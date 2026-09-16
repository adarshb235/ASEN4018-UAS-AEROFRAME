clc;
clear;
close all;

%% fixed parameters

params = struct();
alt = 1700; % boulder altitude [m]
g = 9.81; % acceleration due to gravity [m/s^2]
[T, a, P, rho] = atmoscoesa(alt); % standard atmosphere call [K, m/s, Pa, kg/m^3]

params.alt = alt;
params.T = T;
params.a = a;
params.P = P;
params.rho = rho;

v_init = 0;
x0 =  [0; 0; -alt; ... % inertial position m
       0; 0; 0; ...  % euler angles rad
       v_init; 0; 0; ...    % body frame velocity m/s
       0; 0; 0];  % angular rates rad/s

noRotors = 4; % number of rotors. for now fix at even numbered rotors for i-k and j-k symmetry in the inertia matrix

configFilePath = "/Users/adbo5750exc/Library/Mobile Documents/com~apple~CloudDocs/ASEN 4018/Trade Studies/Design Input File UAS.xlsx";

designInput = readtable(configFilePath);
count = height(designInput);

control_inputs = zeros(6, 1);

i = 1;


tspan = [0 50]; % 15 min of operation, but the simulation takes way too long so doing 50 s for now
[ACGeoStruct] = AircraftGeometry(designInput, count);

while i <= 1
    fprintf('Running simulation %d of %d: %s\n', i, count, string(ACGeoStruct{i}.name{1,1}));
    
    [t_out, x_out] = ode45(@(t, x) DynamicsODE(t, x, ACGeoStruct{i}, params, control_inputs), tspan, x0);
    
    t_results{i} = t_out;
    x_results{i} = x_out;
    
    i = i + 1;
end

% --- EXTRACT DATA ---
% Change 'trade_idx' to plot a different design from your Excel sheet
trade_idx = 1; 
t_plot = t_results{trade_idx};
x_plot = x_results{trade_idx};

% Unpack the 12-state vector arrays for readability
pos   = x_plot(:, 1:3);   % [X, Y, Z] Inertial Position (m)
euler = x_plot(:, 4:6);   % [Roll, Pitch, Yaw] Euler Angles (rad)
vel   = x_plot(:, 7:9);   % [u, v, w] Body Frame Velocity (m/s)
rates = x_plot(:, 10:12); % [p, q, r] Body Angular Rates (rad/s)

%% FIGURE 1: 6-DOF Dynamics (4 Subplots)
figure('Name', 'UAS 6-DOF Dynamics', 'NumberTitle', 'off', 'Position', [100, 100, 900, 700]);

% Subplot 1: Inertial Position
% Note: Z is inverted to show positive altitude above ground
subplot(2, 2, 1);
plot(t_plot, pos(:, 1), 'r', 'LineWidth', 1.5); hold on;
plot(t_plot, pos(:, 2), 'g', 'LineWidth', 1.5);
plot(t_plot, -pos(:, 3), 'b', 'LineWidth', 1.5); 
title('Inertial Position');
xlabel('Time (s)');
ylabel('Position (m)');
legend('X (North)', 'Y (East)', 'Altitude (-Z)', 'Location', 'best');
grid on;

% Subplot 2: Euler Angles
subplot(2, 2, 2);
plot(t_plot, rad2deg(euler(:, 1)), 'r', 'LineWidth', 1.5); hold on;
plot(t_plot, rad2deg(euler(:, 2)), 'g', 'LineWidth', 1.5);
plot(t_plot, rad2deg(euler(:, 3)), 'b', 'LineWidth', 1.5);
title('Euler Angles');
xlabel('Time (s)');
ylabel('Angle (deg)');
legend('Roll', 'Pitch', 'Yaw', 'Location', 'best');
grid on;

% Subplot 3: Body Frame Velocities
subplot(2, 2, 3);
plot(t_plot, vel(:, 1), 'r', 'LineWidth', 1.5); hold on;
plot(t_plot, vel(:, 2), 'g', 'LineWidth', 1.5);
plot(t_plot, vel(:, 3), 'b', 'LineWidth', 1.5);
title('Body Frame Velocities');
xlabel('Time (s)');
ylabel('Velocity (m/s)');
legend('u (Forward)', 'v (Right)', 'w (Down)', 'Location', 'best');
grid on;

% Subplot 4: Body Angular Rates
subplot(2, 2, 4);
plot(t_plot, rad2deg(rates(:, 1)), 'r', 'LineWidth', 1.5); hold on;
plot(t_plot, rad2deg(rates(:, 2)), 'g', 'LineWidth', 1.5);
plot(t_plot, rad2deg(rates(:, 3)), 'b', 'LineWidth', 1.5);
title('Body Angular Rates');
xlabel('Time (s)');
ylabel('Rate (deg/s)');
legend('p (Roll)', 'q (Pitch)', 'r (Yaw)', 'Location', 'best');
grid on;

%% FIGURE 2: 3D Trajectory Map
figure('Name', 'UAS 3D Trajectory', 'NumberTitle', 'off', 'Position', [1050, 100, 600, 500]);

% Plot the 3D flight path (inverting Z so altitude goes UP)
plot3(pos(:, 1), pos(:, 2), -pos(:, 3), 'k', 'LineWidth', 2); hold on;

% Mark start point (Green) and end point (Red)
plot3(pos(1, 1), pos(1, 2), -pos(1, 3), 'go', 'MarkerSize', 8, 'MarkerFaceColor', 'g');
plot3(pos(end, 1), pos(end, 2), -pos(end, 3), 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');

title('UAS 3D Flight Trajectory');
xlabel('North (m)');
ylabel('East (m)');
zlabel('Altitude (m)');
legend('Flight Path', 'Start', 'End', 'Location', 'best');
grid on;
view(3); % Sets standard 3D isometric view

% ODE call and drag model function called within dynamics_ode function,
% must include "count" valued iteration

% main trades to test with this model:
% 3d print vs aluminum
% cube vs octagonal prism for chassis
% cg above, equal, or below geometric center
% different sizes for chassis
% carbon fiber vs fiberglass vs acrylic
% length of struts/diagonal
 
