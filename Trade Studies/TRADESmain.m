clc;
clear;
close all;

%% fixed parameters

params = struct();
alt = 1700; % boulder altitude [m]
g = 9.81; % acceleration due to gravity [m/s^2]
[T, a, P, rho] = atmoscoesa(alt); % standard atmosphere call [K, m/s, Pa, kg/m^3]

v_init = 0;
x0 =  [0; 0; -alt; ... % inertial position m
       0; 0; 0; ...  % euler angles rad
       v_init; 0; 0; ...    % body frame velocity m/s
       0; 0; 0];  % angular rates rad/s

noRotors = 4; % number of rotors. for now fix at even numbered rotors for i-k and j-k symmetry in the inertia matrix

configFilePath = "/Users/adbo5750exc/Library/Mobile Documents/com~apple~CloudDocs/ASEN 4018/Trade Studies/Design Input File UAS.xlsx";

designInput = readtable(configFilePath);
count = height(designInput);


[ACGeoStruct] = AircraftGeometry(designInput, count);

% ODE call and drag model function called within dynamics_ode function

% main trades to test with this model:
% 3d print vs aluminum
% cube vs octagonal prism for chassis
% cg above, equal, or below geometric center
% different sizes for chassis
% carbon fiber vs fiberglass vs acrylic
% length of struts/diagonal
