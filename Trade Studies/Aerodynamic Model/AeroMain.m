% DragPolar_Main.m
clc; clear; close all;

% =========================================================================
% 1. ENVIRONMENT & ATMOSPHERIC PARAMETERS
% =========================================================================
params = struct(); 
alt = 1700; % Boulder altitude [m]
[~, ~, ~, rho] = atmoscoesa(alt); 
params.rho = rho;

% =========================================================================
% 2. LOAD EXCEL DESIGN INPUTS
% =========================================================================
configFilePath = "/Users/adbo5750exc/Library/Mobile Documents/com~apple~CloudDocs/ASEN 4018/Trade Studies/Design Input File UAS.xlsx";
designInput = readtable(configFilePath);
count = height(designInput);

% Generate geometry structure array
[ACGeoStruct] = AircraftGeometry(designInput, count);

% =========================================================================
% 3. SWEEP CONFIGURATION SETUP
% =========================================================================
% Sweep 1: Forward & Vertical Velocity (0 to 5 m/s)
v_sweep = linspace(0, 5, 50); 
drag_results_x = zeros(count, length(v_sweep));
drag_results_z = zeros(count, length(v_sweep));

% Sweep 2: Angle of Attack (0 to 90 degrees) at a constant 5 m/s test speed
alpha_sweep_deg = linspace(-25, 25, 100);
V_test = 5.0; 
CL_results = zeros(count, length(alpha_sweep_deg));
CD_results = zeros(count, length(alpha_sweep_deg));

trade_names = strings(count, 1);

% =========================================================================
% 4. EXECUTE AERODYNAMIC SWEEPS ACROSS ALL TRADES
% =========================================================================
for i = 1:count
    ACGeo = ACGeoStruct{i};
    
    % --- DESCRIPTIVE LEGEND EXTRACTION ---
        t_name = string(ACGeo.name{1,1});

    if iscell(ACGeo.chassisPoly)
        t_shape = string(ACGeo.chassisPoly{1,1});
    else
        t_shape = string(ACGeo.chassisPoly);
    end
    
    switch upper(strtrim(t_shape))
        case 'S'
            shape_full = 'Cube';
        case 'O'
            shape_full = 'Octagon';
        case 'A'
            shape_full = 'Airfoil';
        case 'M'
            shape_full = 'Monocoque';
        otherwise
            shape_full = t_shape;
    end
    
    if iscell(ACGeo.matCage)
        t_mat = string(ACGeo.matCage{1,1});
    else
        t_mat = string(ACGeo.matCage);
    end
    
    trade_names(i) = sprintf('%s [%s | %s]', t_name, shape_full, t_mat);
    
    % --- SWEEP 1: VELOCITY SWEEP (X-DRAG AND Z-DRAG) ---
    for j = 1:length(v_sweep)
        % Forward Translation (X-axis)
        v_forward = [v_sweep(j); 0; 0];
        [F_fwd, ~, ~] = MultidirectionalDragModel(v_forward, params, ACGeo);
        drag_results_x(i, j) = abs(F_fwd(1));
        
        % Vertical Climb/Descent (Z-axis)
        v_vert = [0; 0; v_sweep(j)];
        [F_vert, ~, ~] = MultidirectionalDragModel(v_vert, params, ACGeo);
        drag_results_z(i, j) = abs(F_vert(3));
    end
    
    % --- SWEEP 2: ANGLE OF ATTACK POLAR SWEEP (0 to 90 deg) ---
    for j = 1:length(alpha_sweep_deg)
        alpha_rad = deg2rad(alpha_sweep_deg(j));
        
        % Decompose velocity in the pitch plane (X-Z)
        u_test = V_test * cos(alpha_rad);
        w_test = V_test * sin(alpha_rad);
        v_test_vec = [u_test; 0; w_test];
        
        [~, ~, Aero] = MultidirectionalDragModel(v_test_vec, params, ACGeo);
        
        % Strictly store by trade index i and angle index j
        CL_results(i, j) = Aero.C_L;
        CD_results(i, j) = Aero.C_D_eff;
    end
end

% =========================================================================
% 5. PLOTTING
% =========================================================================
legend_opts = {'Location', 'best', 'Interpreter', 'none', 'FontSize', 9};

% FIGURE 1: Multidirectional Forces vs Velocity
figure('Name', 'Multidirectional Forces', 'Position', [100, 500, 950, 400], 'Color', 'w');

subplot(1, 2, 1);
hold on; grid on;
for i = 1:count
    plot(v_sweep, drag_results_x(i, :), 'LineWidth', 2);
end
title('Forward Flight Drag (X-Axis)', 'FontSize', 11, 'FontWeight', 'bold');
xlabel('Velocity (m/s)', 'FontSize', 10);
ylabel('Parasite Drag Force (N)', 'FontSize', 10);
legend(trade_names, legend_opts{:});
set(gca, 'FontSize', 9, 'LineWidth', 1.1);

subplot(1, 2, 2);
hold on; grid on;
for i = 1:count
    plot(v_sweep, drag_results_z(i, :), 'LineWidth', 2);
end
title('Vertical Cross-Flow Drag (Z-Axis)', 'FontSize', 11, 'FontWeight', 'bold');
xlabel('Vertical Velocity (m/s)', 'FontSize', 10);
ylabel('Vertical Drag Force (N)', 'FontSize', 10);
legend(trade_names, legend_opts{:});
set(gca, 'FontSize', 9, 'LineWidth', 1.1);

% FIGURE 2: Aerodynamic Polars vs Angle of Attack
figure('Name', 'Aerodynamic Polars', 'Position', [100, 50, 950, 400], 'Color', 'w');

subplot(1, 2, 1);
hold on; grid on;
for i = 1:count
    plot(alpha_sweep_deg, CL_results(i, :), 'LineWidth', 2);
end
title('Lift Coefficient vs Angle of Attack', 'FontSize', 11, 'FontWeight', 'bold');
xlabel('Angle of Attack, \alpha (deg)', 'FontSize', 10);
ylabel('Lift Coefficient (C_L)', 'FontSize', 10);
legend(trade_names, legend_opts{:});
set(gca, 'FontSize', 9, 'LineWidth', 1.1);

subplot(1, 2, 2);
hold on; grid on;
for i = 1:count
    plot(alpha_sweep_deg, CD_results(i, :), 'LineWidth', 2);
end
title('Drag Coefficient vs Angle of Attack', 'FontSize', 11, 'FontWeight', 'bold');
xlabel('Angle of Attack, \alpha (deg)', 'FontSize', 10);
ylabel('Drag Coefficient (C_D)', 'FontSize', 10);
legend(trade_names, legend_opts{:});
set(gca, 'FontSize', 9, 'LineWidth', 1.1);


% =========================================================================
% LOCAL FUNCTION: 6-DOF AERODYNAMIC & POLAR MODEL
% =========================================================================
function [F_aero, M_aero, AeroStruct] = MultidirectionalDragModel(v_b, params, ACGeo)
    AeroStruct = struct();
    
    u = v_b(1);
    v = v_b(2);
    w = v_b(3);
    V_mag = norm(v_b);
    
    if V_mag < 1e-6
        F_aero = [0; 0; 0];
        M_aero = [0; 0; 0];
        AeroStruct.C_Dx = 0; AeroStruct.C_Dy = 0; AeroStruct.C_Dz = 0;
        AeroStruct.C_D_eff = 0; AeroStruct.C_L = 0; AeroStruct.alpha_deg = 0;
        return;
    end
    
    rho = params.rho;
    alpha = atan2(w, u);
    
    L_cage = ACGeo.sideLength; 
    H_cage = ACGeo.heightCage;
    
    if iscell(ACGeo.chassisPoly)
        shapeFlag = ACGeo.chassisPoly{1,1};
    else
        shapeFlag = ACGeo.chassisPoly;
    end
    
    % Shape-specific geometries and baseline coefficients
    switch upper(strtrim(shapeFlag))
        case 'S'
            % --- Square / Rectangular Prism ---
            S_chassis_x = L_cage * H_cage;
            S_chassis_y = L_cage * H_cage;
            S_chassis_z = L_cage^2;
            
            CD_0 = 1.05;   
            CD_max = 1.15; 
            
        case 'O'
            % --- Octagonal Prism ---
            S_chassis_x = L_cage * H_cage;
            S_chassis_y = L_cage * H_cage;
            S_chassis_z = 2 * (sqrt(2) - 1) * L_cage^2; 
            
            CD_0 = 0.95;
            CD_max = 1.05;
            
        case 'A'
            % --- Streamlined Airfoil Top / Rectangular Base ---
            H_top = H_cage / 3;
            H_base = H_cage - H_top;
            
            A_airfoil_half = 0.685 * L_cage * H_top;
            S_chassis_x = (L_cage * H_base) + A_airfoil_half;
            S_chassis_y = L_cage * H_cage;
            S_chassis_z = L_cage^2;
            
            CD_0 = 0.45; 
            CD_max = 1.15; 
            
        case 'M'
            % --- Monocoque Dome Top / Rectangular Base ---
            H_base = H_cage / 3;
            H_top = H_cage - H_base;
            
            S_chassis_x = (L_cage * H_base) + (0.5 * pi * (L_cage/2) * H_top);
            S_chassis_y = S_chassis_x;
            S_chassis_z = pi * (L_cage/2)^2;
            
            CD_0 = 0.60;
            CD_max = 0.90;
            
        otherwise
            error('Unsupported chassis polygon type: %s', shapeFlag);
    end
    
    % Continuous Angle of Attack Polars (Cross-Flow Formulation)
    C_D_eff = CD_max * abs(sin(alpha)^3) + CD_0 * abs(cos(alpha)^3);
    C_L_eff = CD_max * (sin(alpha)^2) * cos(alpha);
    
    % Parasitic Drag Area Buildup (Arms & Rotors)
    A_arm = ACGeo.lengthArm * ACGeo.diaArm;
    A_arms_xy = 4 * (A_arm * cosd(45));
    A_arms_z  = 4 * A_arm;
    CD_arm = 1.10; 
    
    CDA_x = (CD_0 * S_chassis_x) + (CD_arm * A_arms_xy) + (4 * 0.005);
    CDA_y = (CD_0 * S_chassis_y) + (CD_arm * A_arms_xy) + (4 * 0.005);
    CDA_z = (CD_max * S_chassis_z) + (CD_arm * A_arms_z);
    
    % Decoupled Body Forces
    F_x = -0.5 * rho * CDA_x * abs(u) * u;
    F_y = -0.5 * rho * CDA_y * abs(v) * v;
    F_z = -0.5 * rho * CDA_z * abs(w) * w;
    F_aero = [F_x; F_y; F_z];
    
    % Aerodynamic Moments
    if isfield(ACGeo, 'z_cgCage') && isfield(ACGeo, 'z_cgTot')
        dz_cage = ACGeo.z_cgCage - ACGeo.z_cgTot;
    else
        dz_cage = 0; 
    end
    M_aero = [-dz_cage * F_y; dz_cage * F_x; 0];
    
    % Assign Struct Outputs
    AeroStruct.C_D_eff = C_D_eff;
    AeroStruct.C_L = C_L_eff;
    AeroStruct.C_Dx = CD_0;
    AeroStruct.C_Dy = CD_0;
    AeroStruct.C_Dz = CD_max;
    AeroStruct.alpha_deg = rad2deg(alpha);
end