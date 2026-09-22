function [T_dot, ThermalStruct] = ThermalModel(t, T_nodes, ACGeo, params, v_b, MatProps)
    % THERMALMODEL: Computes transient heat build-up and distribution
    %
    % Inputs:
    %   t          - Current time (s)
    %   T_nodes    - 3x1 vector of current nodal temperatures (Kelvin)
    %                [T_avi; T_batt; T_cage]
    %   ACGeo      - Aircraft geometry structure from AircraftGeometry.m
    %   params     - Atmospheric parameters struct (needs params.T for ambient)
    %   v_b        - Body velocity vector (m/s) for forced convection
    %   MatProps   - Struct containing user-defined material thermal properties
    %
    % Outputs:
    %   T_dot         - 3x1 vector of temperature rates of change (K/s)
    %   ThermalStruct - Detailed heat flux output for plotting

    % --- 1. UNPACK STATES & ENVIRONMENT ---
    T_avi  = T_nodes(1);
    T_batt = T_nodes(2);
    T_cage = T_nodes(3);
    
    T_inf = params.T; % Ambient air temperature (K)[cite: 8]
    magV = norm(v_b); % Airspeed for forced convection cooling
    
    % --- 2. EXTRACT GEOMETRY & MASS ---
    % Using parameters established in AircraftGeometry.m
    L = ACGeo.sideLength;
    H = ACGeo.heightCage;
    t_cage = ACGeo.thickCage;
    
    m_avi  = ACGeo.massAvi;
    m_batt = ACGeo.massBatt * 4; % 4 batteries
    m_cage = ACGeo.massCage;
    
    % Surface Area for convection to ambient air (Outer walls + Top/Bottom)
    if strcmp(ACGeo.chassisPoly, 'S') || (iscell(ACGeo.chassisPoly) && strcmp(ACGeo.chassisPoly{1,1}, 'S'))
        A_conv = (4 * L * H) + (2 * L^2);
    elseif strcmp(ACGeo.chassisPoly, 'O') || (iscell(ACGeo.chassisPoly) && strcmp(ACGeo.chassisPoly{1,1}, 'O'))
        % Octagonal prism exposed surface area
        A_conv = (4 * L * H) + (4 * 2*(sqrt(2)-1)*L^2);
    else
        % Approximation for Monocoque Egg
        A_conv = (L * (H/3)) * 4 + (2 * pi * (L/2)^2); 
    end
    
    % --- 3. MATERIAL PROPERTIES (User Inputs via MatProps) ---
    % Specific Heat Capacities (J / kg*K)
    cp_avi  = MatProps.cp_avi;
    cp_batt = MatProps.cp_batt;
    cp_cage = MatProps.cp_cage;
    
    % Contact areas for internal conduction (m^2) (Estimates)
    A_contact_avi = 0.05 * 0.05;  % Footprint of avionics board on cage
    A_contact_batt = 0.08 * 0.04 * 4; % Footprint of 4 batteries on cage
    
    % Thermal Conductivities (W / m*K)
    k_cage = MatProps.k_cage; 
    
    % --- 4. THERMAL RESISTANCES ---
    % Conduction resistance: R = L / (k * A)
    % Assuming heat travels half the thickness of the cage plates
    R_cond_avi  = (t_cage / 2) / (k_cage * A_contact_avi);
    R_cond_batt = (t_cage / 2) / (k_cage * A_contact_batt);
    
    % Convection resistance: R = 1 / (h * A)
    % Estimate convective heat transfer coefficient 'h' (W / m^2*K)
    % Uses a simplified mixed convection model based on velocity
    if magV < 0.1
        h_conv = 10; % Natural convection (hover/still air)
    else
        h_conv = 10 + 4 * sqrt(magV); % Forced convection (forward flight)
    end
    R_conv_cage = 1 / (h_conv * A_conv);
    
    % --- 5. HEAT GENERATION (Watts) ---
    % Placeholder for internal active heat generation 
    Q_gen_avi  = MatProps.power_avi;  % e.g., 15W for companion computer
    Q_gen_batt = MatProps.power_batt; % e.g., I^2*R losses from motors drawing current
    
    % --- 6. HEAT TRANSFER EQUATIONS (Nodal Network) ---
    % Fourier's Law of Heat Conduction & Newton's Law of Cooling
    
    % Heat flow OUT of Avionics INTO Cage
    Q_avi_to_cage = (T_avi - T_cage) / R_cond_avi;
    
    % Heat flow OUT of Batteries INTO Cage
    Q_batt_to_cage = (T_batt - T_cage) / R_cond_batt;
    
    % Heat flow OUT of Cage INTO Environment (Air)
    Q_cage_to_air = (T_cage - T_inf) / R_conv_cage;
    
    % --- 7. TEMPERATURE DERIVATIVES (dT/dt) ---
    % Equation: m * cp * dT/dt = Q_in - Q_out + Q_gen
    
    dT_avi  = (Q_gen_avi - Q_avi_to_cage) / (m_avi * cp_avi);
    dT_batt = (Q_gen_batt - Q_batt_to_cage) / (m_batt * cp_batt);
    
    % The cage acts as the primary heat sink, absorbing from internal components
    dT_cage = (Q_avi_to_cage + Q_batt_to_cage - Q_cage_to_air) / (m_cage * cp_cage);
    
    T_dot = [dT_avi; dT_batt; dT_cage];
    
    % --- 8. PACKAGE OUTPUTS ---
    ThermalStruct.Q_avi_to_cage = Q_avi_to_cage;
    ThermalStruct.Q_batt_to_cage = Q_batt_to_cage;
    ThermalStruct.Q_cage_to_air = Q_cage_to_air;
    ThermalStruct.h_conv = h_conv;
    ThermalStruct.R_cond_avi = R_cond_avi;
    ThermalStruct.R_cond_batt = R_cond_batt;
end