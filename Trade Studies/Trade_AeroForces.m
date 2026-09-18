%{
Trade Study: Aerodynamic Forces & Moments
Critical Component of Study: Rotor Arms
%}
%% Initialization & Parameters
clc; clear; close all;

% Rod Parameters
rod_length = 0.15; % m
rod_diameter = 0.005; % m
hollow_ratio = 0.9;
T = 166.8 / 4; % N, thrust per arm

% Anonymous Functions for Geometry & Physics
A_solid = @(d) pi .* (d ./ 2).^2;
I_solid = @(d) (pi .* d.^4) ./ 64;
I_hollow = @(d_inner, d_outer) (pi/64) .* (d_outer.^4 - d_inner.^4);
V_solid = @(d, L) pi .* ((d ./ 2).^2) .* L;
V_hollow = @(d_inner, d_outer, L) pi .* ((d_outer ./ 2).^2 - (d_inner ./ 2).^2) .* L;
delta = @(F, L, E, I_val) (F .* L.^3) ./ (3 .* E .* I_val);

%% Material Properties Setup
% Materials: 1:CF, 2:FG, 3:Al-6061, 4:Ti-6Al-4V, 5:PA-CF
mat_names = {'Carbon Fibre', 'Fiberglass', 'Aluminum 6061', 'Ti-6Al-4V', 'PA-CF'};
mat_rho = [1800, 2000, 2700, 4512, 1170]; % kg/m^3
mat_E = [227e9, 20e9, 70e9, 119e9, 8e9]; % Pa (Converted GPa to Pa upfront)
mat_colors = {'r', 'g', 'b', 'm', 'c'}; % Plot line colors

num_mats = length(mat_names);

%% Independent Variable Arrays
L_lib = linspace(0.05, 0.20, 500);
D_lib = linspace(0.001, 0.015, 500);
[X_L, Y_D] = meshgrid(L_lib, D_lib);

%% Trade Study - Visualization Global Setup
levels = linspace(0, 0.05, 80);
limit = 0.0025;

%% 1 & 2. 2D Contour Maps (Solid and Hollow)
for i = 1:num_mats
    % Calculate Meshgrids for the current material
    delta_solid_MG = delta(T, X_L, mat_E(i), I_solid(Y_D));
    delta_hollow_MG = delta(T, X_L, mat_E(i), I_hollow(hollow_ratio*Y_D, Y_D));
    
    % Solid Contour Plot
    figure(100 + i);
    contourf(X_L, Y_D, delta_solid_MG, levels, 'LineStyle','none');
    colorbar; clim([0, 0.05]); colormap turbo; hold on;
    contour(X_L, Y_D, delta_solid_MG, [limit, limit], 'r--', 'LineWidth', 2);
    xlabel('Rod Length (m)', 'FontWeight', 'bold');
    ylabel('Rod Diameter (m)', 'FontWeight', 'bold');
    zlabel('Deflection (m)', 'FontWeight', 'bold');
    title(sprintf('%s Beam Deflection (SOLID)', mat_names{i}), 'FontSize', 12);
    grid on; hold off;
    
    % Hollow Contour Plot
    figure(200 + i);
    contourf(X_L, Y_D, delta_hollow_MG, levels, 'LineStyle','none');
    colorbar; clim([0, 0.05]); colormap turbo; hold on;
    contour(X_L, Y_D, delta_hollow_MG, [limit, limit], 'r--', 'LineWidth', 2);
    xlabel('Rod Length (m)', 'FontWeight', 'bold');
    ylabel('Rod Diameter (m)', 'FontWeight', 'bold');
    zlabel('Deflection (m)', 'FontWeight', 'bold');
    title(sprintf('%s Beam Deflection (HOLLOW)', mat_names{i}), 'FontSize', 12);
    grid on; hold off;
end

%% 3. Nominal Length: Mass vs. Deflection (Fig 300)
L_nom = 0.15;
figure(300); hold on;

for i = 1:num_mats
    % Calculate Arrays over D_lib
    mass_solid = (mat_rho(i) .* V_solid(D_lib, L_nom)) .* 1000; % to grams
    mass_hollow = (mat_rho(i) .* V_hollow(hollow_ratio.*D_lib, D_lib, L_nom)) .* 1000;
    
    defl_solid = delta(T, L_nom, mat_E(i), I_solid(D_lib)) .* 1000; % to mm
    defl_hollow = delta(T, L_nom, mat_E(i), I_hollow(hollow_ratio.*D_lib, D_lib)) .* 1000;
    
    plot(mass_solid, defl_solid, '-', 'Color', mat_colors{i}, 'LineWidth', 2, ...
        'DisplayName', sprintf('%s (Solid)', mat_names{i}));
    plot(mass_hollow, defl_hollow, '--', 'Color', mat_colors{i}, 'LineWidth', 2, ...
        'DisplayName', sprintf('%s (Hollow~%.0f%% Dia Ratio)', mat_names{i}, hollow_ratio*100));
end

xlabel('Mass per arm [grams]'); 
ylabel('Deflection [mm]');
title(sprintf('Mass vs. Deflection (Nominal Length = %.0fmm)', L_nom*1000));
xlim([0, 15]); ylim([0, 20]);
legend('Location','best'); grid on; hold off;

%% 4. Nominal Length: Deflection vs. Outer Diameter (Fig 301)
figure(301); hold on;

for i = 1:num_mats
    defl_solid = delta(T, L_nom, mat_E(i), I_solid(D_lib)) .* 1000;
    defl_hollow = delta(T, L_nom, mat_E(i), I_hollow(hollow_ratio.*D_lib, D_lib)) .* 1000;
    
    plot(D_lib .* 1000, defl_solid, '-', 'Color', mat_colors{i}, 'LineWidth', 2, ...
        'DisplayName', sprintf('%s (Solid)', mat_names{i}));
    plot(D_lib .* 1000, defl_hollow, '--', 'Color', mat_colors{i}, 'LineWidth', 2, ...
        'DisplayName', sprintf('%s (Hollow)', mat_names{i}));
end

xlim([0, 15]); ylim([0, 5]);
xlabel('Outer Diameter [mm]'); 
ylabel('Deflection [mm]');
title(sprintf('Deflection vs. Outer Diameter (Nominal L = %.0fmm) (Ratio = %.2f)', L_nom*1000, hollow_ratio));
legend('Location', 'best'); grid on; hold off;

%% 5. Nominal Case - Mass vs. Deflection Bar Chart (Hollow, L=150mm, D=8mm)
nom_d = 0.008;
nom_l = 0.15;

% Preallocate arrays for speed
nom_masses = zeros(1, num_mats);
nom_defls = zeros(1, num_mats);

% Calculate nominals for the bar chart
for i = 1:num_mats
    nom_masses(i) = (mat_rho(i) * V_hollow(hollow_ratio*nom_d, nom_d, nom_l)) * 1000; % grams
    nom_defls(i) = delta(T, nom_l, mat_E(i), I_hollow(hollow_ratio*nom_d, nom_d)) * 1000; % mm
end

figure(400);
x = 1:num_mats; 
bar_width = 0.35;

yyaxis left;
b1 = bar(x - bar_width/2, nom_masses, bar_width);
ylabel('Mass [g]', 'FontWeight', 'bold');
ylim([0, max(nom_masses) * 1.2]);

yyaxis right;
b2 = bar(x + bar_width/2, nom_defls, bar_width);
ylabel('Deflection [mm]', 'FontWeight', 'bold');
ylim([0, max(nom_defls) * 1.2]);

xticks(x);
xticklabels(mat_names);
title(sprintf('Nominal Hollow Beam: Mass and Deflection (D=%.0fmm, L=%.0fmm)', nom_d*1000, nom_l*1000), 'FontWeight', 'bold');
grid on;
legend([b1, b2], {'Mass', 'Deflection'}, 'Location', 'northwest');
