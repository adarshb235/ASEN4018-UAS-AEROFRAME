%{
Trade Study: Aerodynamic Forces & Moments
Critical Component of Study: Rotor Arms
%}
%% Trade Study - Simulation

clc;
clear;
close all;


% Define Rod Parameters
rod_length = 0.15; % m
rod_diameter = 0.005; % m
A = @(rod_diameter) pi .* (rod_diameter ./ 2).^2; % circular cross section
I = @(d) (pi .* d.^4) ./ 64;  % circular cross section
V = @(rod_diameter, rod_length) pi .* ((rod_diameter ./ 2).^2) .* rod_length; % cylindrical shape

% Material Densities
% Carbon Fibre (CF)
CF_rho = 1800; % kg/m^3
% Fiber Glass (FG)
FG_rho = 2000; % kg/m^3
% Aluminium (Al)
Al_rho = 2700; % kg/m^3

% Material Young's Moduli
% Carbon Fibre (CF)
CF_E = 227; % GPa
% Fiber Glass (FG)
FG_E = 20; % GPa
% Aluminium (Al)
Al_E = 70; % GPa

% Volume Calculations
CF_volume = V(rod_diameter, rod_length);
FG_volume = V(rod_diameter, rod_length);
Al_volume = V(rod_diameter, rod_length);

% 2nd Moment of Area (I)
CF_I = I(rod_diameter);
FG_I = I(rod_diameter);
Al_I = I(rod_diameter);

% Mass Calculations
CF_mass = CF_rho * CF_volume;
FG_mass = FG_rho * FG_volume;
Al_mass = Al_rho * Al_volume;

% Deflection Calculations 
% (Load at free end, supported beam)
delta = @(F, L, E, I_val) (F .* L.^3) ./ (3 .* E .* I_val);
T = 166.8/4; % N, 166.8 N of thrust on the high end
deflection_CF = delta(T, rod_length, CF_E*1e9, CF_I); % Carbon Fibre Deflection
deflection_FG = delta(T, rod_length, FG_E*1e9, FG_I); % Fiberglass Deflection
deflection_Al = delta(T, rod_length, Al_E*1e9, Al_I); % Aluminium Deflection

% Varying Variables

% Vary Rod Length
L_lib = linspace(0.05, 0.20, 500);

deflection_CF_len = arrayfun(@(d) delta(T, rod_length, CF_E*1e9, I(d)), L_lib);
deflection_FG_len = arrayfun(@(d) delta(T, rod_length, FG_E*1e9, I(d)), L_lib);
deflection_Al_len = arrayfun(@(d) delta(T, rod_length, Al_E*1e9, I(d)), L_lib);

% Vary Rod Diameter
D_lib = linspace(0.001, 0.010, 500);

deflection_CF_diam = arrayfun(@(d) delta(T, rod_length, CF_E*1e9, I(d)), D_lib);
deflection_FG_diam = arrayfun(@(d) delta(T, rod_length, FG_E*1e9, I(d)), D_lib);
deflection_Al_diam = arrayfun(@(d) delta(T, rod_length, Al_E*1e9, I(d)), D_lib);

% Meshgrid of Deflections for Length & Diameter Variations
[X, Y] = meshgrid(L_lib, D_lib);

delta_CF_MG = delta(T, X, CF_E*1e9, I(Y));
delta_FG_MG = delta(T, X, FG_E*1e9, I(Y));
delta_Al_MG = delta(T, X, Al_E*1e9, I(Y));
%% Trade Study - Visualization
figure();

% Carbon Fibre
subplot(1,3,1);

s_CG = surf(X, Y, delta_CF_MG);

shading interp;

xlabel('Rod Length (m)', 'FontWeight', 'bold');
ylabel('Rod Diameter (m)', 'FontWeight', 'bold');
zlabel('Deflection (m)', 'FontWeight', 'bold');
title('Carbon Fibre Beam Deflection', 'FontSize', 12);

zlim([0, 0.05]);
clim([0, 0.05]);

grid on;

% Fiberglass
subplot(1,3,2);

s_FG = surf(X, Y, delta_FG_MG);

shading interp;

xlabel('Rod Length (m)', 'FontWeight', 'bold');
ylabel('Rod Diameter (m)', 'FontWeight', 'bold');
zlabel('Deflection (m)', 'FontWeight', 'bold');
title('Fiberglass Beam Deflection', 'FontSize', 12);

zlim([0, 0.05]);
clim([0, 0.05]);

grid on;

% Aluminium
subplot(1,3,3);

s_Al = surf(X, Y, delta_Al_MG);

shading interp;

xlabel('Rod Length (m)', 'FontWeight', 'bold');
ylabel('Rod Diameter (m)', 'FontWeight', 'bold');
zlabel('Deflection (m)', 'FontWeight', 'bold');
title('Aluminium Beam Deflection', 'FontSize', 12);

zlim([0, 0.05]);
clim([0, 0.05]);

grid on;