clear; 
close all;

% --- 1. ENVIRONMENT & PARAMETERS ---
params = struct(); 
alt = 1700; % Boulder altitude [m]
[T_atm, a, P, rho] = atmoscoesa(alt); % Standard atmosphere call
params.alt = alt; 
params.T = T_atm; 
params.a = a; 
params.P = P; 
params.rho = rho;

MatProps = struct();
MatProps.k_cage = 0.22;     % ASA Thermal Conductivity (W/m*K)
MatProps.cp_cage = 1500;   % ASA Specific Heat (J/kg*K)
MatProps.cp_avi = 900;     % Avionics Specific Heat (Generic PCB)
MatProps.cp_batt = 1000;   % Battery Specific Heat (LiPo)
dissFC = 4; % dissipation of flight controller W
dissComp = 5; % dissipation of onboard computing
dissRTK = 6; % dissipation of GPS-RTK
dissRadio = 1; % dissipation of radio system
dissWifi = 4; % dissipation of wifi chip
MatProps.power_avi = dissFC + dissComp + dissRTK + dissRadio + dissWifi;   % Avionics heat dissipation (W)
MatProps.power_batt = 30;  % Battery internal resistance heating (W)

configFilePath = "/Users/adbo5750exc/Library/Mobile Documents/com~apple~CloudDocs/ASEN 4018/Trade Studies/Design Input File UAS.xlsx";
designInput = readtable(configFilePath);
count = height(designInput);
[ACGeoStruct] = AircraftGeometry(designInput, count);

% Select which configuration to animate
trade_idx = 5; 
ACGeo = ACGeoStruct{trade_idx};

tspan = [0 900]; % 15 minutes of operation
T_initial = [params.T; params.T; params.T]; % Start at ambient temp (Kelvin)
v_b = [0; 0; 0]; % Assume hover (no forward airspeed cooling)

% uses lumped capacitance
[t_out, T_out] = ode45(@(t, T_nodes) ThermalModel(t, T_nodes, ACGeo, params, v_b, MatProps), tspan, T_initial);

% Convert outputs Celsius 
T_out_C = T_out - 273.15;
T_max = max(T_out_C, [], 'all');
T_min = min(T_out_C, [], 'all');
T_max_nodes = max(T_out_C); 
fprintf('\nMaximum Temperatures for %s:\n', string(ACGeo.name{1,1}));
fprintf('  Avionics: %5.1f °C\n', T_max_nodes(1));
fprintf('  Battery:  %5.1f °C\n', T_max_nodes(2));
fprintf('  Cage:     %5.1f °C\n\n', T_max_nodes(3));

fig = figure('Name', 'Transient Thermal Profile', 'Position', [100, 100, 700, 600], 'Renderer', 'painters');
colormap('hot'); % Heatmap color scale
caxis([T_min, T_max]);
cb = colorbar;
cb.Label.String = 'Temperature (°C)';
cb.Label.FontSize = 12;

hold on; axis equal;
xlim([-ACGeo.sideLength, ACGeo.sideLength]);
ylim([-0.05, ACGeo.heightCage + 0.05]);
title(sprintf('Internal Thermal Distribution: %s', string(ACGeo.name{1,1})), 'FontSize', 14);
xlabel('Lateral Y Position (m)'); ylabel('Vertical Z Position (m)');
grid on;

if iscell(ACGeo.chassisPoly)
    shapeFlag = ACGeo.chassisPoly{1,1};
else
    shapeFlag = ACGeo.chassisPoly;
end

if istable(ACGeo.name)
    tradeName = string(ACGeo.name{1,1});
else
    tradeName = string(ACGeo.name);
end

title(sprintf('Internal Thermal Distribution: %s', tradeName), 'FontSize', 14);

L = ACGeo.sideLength;
H = ACGeo.heightCage;

if strcmp(shapeFlag, 'S') || strcmp(shapeFlag, 'O')
    cage_x = [-L/2, L/2, L/2, -L/2];
    cage_y = [0, 0, H, H];
    
elseif strcmp(shapeFlag, 'M')
    % Monocoque: Rectangular base (lower 1/3) + Semi-ellipsoid dome (upper 2/3)
    H_base = H / 3;
    H_dome = H - H_base;  
    theta = linspace(pi, 0, 40);
    dome_x = (L/2) * cos(theta);
    dome_y = H_base + H_dome * sin(theta);
    cage_x = [-L/2, dome_x, L/2];
    cage_y = [0, dome_y, 0];
end

% Battery Stack 
batt_x = [-0.04, 0.04, 0.04, -0.04];
batt_y = [ACGeo.z_cgBatt - 0.015, ACGeo.z_cgBatt - 0.015, ACGeo.z_cgBatt + 0.015, ACGeo.z_cgBatt + 0.015];

% Avionics Board 
avi_x = [-0.03, 0.03, 0.03, -0.03];
avi_y = [ACGeo.z_cgAvi - 0.01, ACGeo.z_cgAvi - 0.01, ACGeo.z_cgAvi + 0.01, ACGeo.z_cgAvi + 0.01];

p_cage = patch(cage_x, cage_y, 'k', 'FaceColor', 'flat', 'CData', T_out_C(1,3), 'LineWidth', 2);
p_batt = patch(batt_x, batt_y, 'k', 'FaceColor', 'flat', 'CData', T_out_C(1,2), 'LineWidth', 1);
p_avi  = patch(avi_x, avi_y, 'k', 'FaceColor', 'flat', 'CData', T_out_C(1,1), 'LineWidth', 1);

% Add internal fold lines for the octagon (purely visual)
if strcmp(shapeFlag, 'O')
    s_half = (L / (1 + sqrt(2))) / 2; 
    plot([-s_half, -s_half], [0, H], 'k-', 'LineWidth', 0.5, 'Color', [0.3 0.3 0.3]);
    plot([s_half, s_half], [0, H], 'k-', 'LineWidth', 0.5, 'Color', [0.3 0.3 0.3]);
end

% Add real-time telemetry text to the plot
telemetry_text = text(-ACGeo.sideLength*0.9, ACGeo.heightCage*0.85, '', ...
    'FontSize', 11, 'FontWeight', 'bold', 'BackgroundColor', 'w', 'EdgeColor', 'k');

animate_steps = round(linspace(1, length(t_out), 500)); 

for i = 1:length(animate_steps)
    idx = animate_steps(i);
    
    % Update colors based on the current temperature of each node
    p_cage.CData = T_out_C(idx, 3);
    p_batt.CData = T_out_C(idx, 2);
    p_avi.CData  = T_out_C(idx, 1);
    
    % Update the telemetry text box
    telemetry_text.String = sprintf(' Time: %4.0f s\n Cage: %5.1f °C\n Batt: %5.1f °C\n Avi:  %5.1f °C ', ...
                                    t_out(idx), T_out_C(idx,3), T_out_C(idx,2), T_out_C(idx,1));
    
    drawnow limitrate; 
    pause(0.05);

end