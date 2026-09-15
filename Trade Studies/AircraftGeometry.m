function [ACGeo] = AircraftGeometry(designInput, count)
%AIRCRAFTGEOMETRY returns aircraft geometry structure
%   will need to breakdown geometry into struts, fans/rotors,
%   fuselage/housing. need to breakdown material distribution to get weight
%   and cg model. need to determine inertia matrix. 

ACGeo = cell(count, 1); % parent cell that will contain sub structures 

%% CG

i = 1;

while i <= count
    % all units should be converted into SI [kg, m, m/s, etc.]
    GeometryStruct = struct();
    GeometryStruct.name = designInput(i, 1); % design name
    GeometryStruct.numRotors = table2array(designInput(i, 3)); % number of rotors
    GeometryStruct.chassisPoly = designInput(i, 4).Square_Oct; % polygon used for chassis, ver 1.0 fix at square or octagon
    GeometryStruct.sideLength = table2array(designInput(i, 5)) / 100; % polygon side length
    GeometryStruct.thickCage = table2array(designInput(i, 6)) / 100; % thickness of cage
    GeometryStruct.heightCage = table2array(designInput(i, 7)) / 100; % height of cage
    GeometryStruct.matCage = designInput(i, 8).Mat_cage; % cage material
    GeometryStruct.lengthArm = table2array(designInput(i, 9)) / 100; % length of arm (assume full length of arm is outside of cage and props)
    GeometryStruct.thickArm = table2array(designInput(i, 10)) / 100; % thickness of arm
    GeometryStruct.diaArm = table2array(designInput(i, 11)) / 100; % max diameter of arm
    GeometryStruct.matArm = designInput(i, 12).Mat_strut; % material of arm
    GeometryStruct.diaProp = table2array(designInput(i, 13)) / 100; % fan diameter
    GeometryStruct.heightProp = table2array(designInput(i, 14)) / 100; % height of fan assembly
    GeometryStruct.massFan = table2array(designInput(i, 15)); % mass of each fan
    GeometryStruct.massAvi = table2array(designInput(i, 16)); % mass of avionics
    GeometryStruct.x_cgAvi = table2array(designInput(i, 17)) / 100; % x_cg of avionics relative to geometric center of bottom plate
    GeometryStruct.y_cgAvi = table2array(designInput(i, 18)) / 100; % y_cg of avionics relative to geometric center of bottom plate
    GeometryStruct.z_cgAvi = table2array(designInput(i, 19)) / 100; % z_cg of avionics relative to geometric center of bottom plate
    GeometryStruct.massBatt = table2array(designInput(i, 20)); % mass of each battery pack
    GeometryStruct.x_cgBatt = table2array(designInput(i, 21)) / 100; % +/- x_cg of battery relative to geometric center of bottom plate
    GeometryStruct.y_cgBatt = table2array(designInput(i, 22)) / 100; % +/- y_cg of battery relative to geometric center of bottom plate
    GeometryStruct.z_cgBatt = table2array(designInput(i, 23)) / 100; % +/- z_cg of battery relative to geometric center of bottom plate
    

    % by symmetry, x and y_cg necessarily has to be at the origin. expand
    % later models when no longer symmetric
    if (strcmp(GeometryStruct.chassisPoly,'S'))
        densityCage = 1270; % for PETG
        densityArm = 1750; % for low mod carbon fiber
        massCage = densityCage * (GeometryStruct.sideLength^3 - (GeometryStruct.sideLength - 2 * GeometryStruct.thickCage)^3);
        massArm = densityArm * (pi * (GeometryStruct.diaArm^2 - (GeometryStruct.diaArm - 2 * GeometryStruct.thickArm)^2) / 4);
        massAvi = GeometryStruct.massAvi;
        massBatt = GeometryStruct.massBatt;
        massProp = GeometryStruct.massFan;
        massTot = massCage + 4 * massArm + massAvi + 4 * massBatt + 4 * massProp;
        z_cg_Cage = GeometryStruct.heightCage/2;
        z_cg_Batt = GeometryStruct.z_cgBatt;
        z_cg_Avi = GeometryStruct.z_cgBatt;
        z_cg_Prop = GeometryStruct.heightCage/2; % may need to add parameter to excel file
        z_cg_tot = (massCage * z_cg_Cage + (4 * massArm * z_cg_Prop) + (4 * massProp * z_cg_Prop) + (4 * massBatt * z_cg_Batt) + massAvi * z_cg_Avi)/massTot;


        r_cage = (s_out * sqrt(2)) / 2;
        % Motor center radial distance from vehicle center
        r_motor = r_cage + GeometryStruct.lengthArm; 
        x_m = r_motor * cosd(45);
        y_m = r_motor * sind(45);
        
        % Delta Z relative to total CG
        dz_cage = z_cg_Cage - z_cg_tot;
        dz_arm  = z_cg_Arm  - z_cg_tot;
        dz_prop = z_cg_Prop - z_cg_tot;
        dz_batt = z_cg_Batt - z_cg_tot;
        dz_avi  = z_cg_Avi  - z_cg_tot;
        
        % --- Inertia: 1. Cage ---
        I_cage_local = (1/6) * densityCage * (s_out^5 - s_in^5);
        Ixx_cage = I_cage_local + massCage * dz_cage^2;
        Iyy_cage = I_cage_local + massCage * dz_cage^2;
        Izz_cage = I_cage_local;
        
        % Integral of r^2 dm along the arm:
        Izz_arms = 4 * massArm * ((1/3)*GeometryStruct.lengthArm^2 + ...
                   r_cage^2 + GeometryStruct.lengthArm*r_cage);
        Ixx_arms = 0.5 * Izz_arms + 4 * massArm * dz_arm^2;
        Iyy_arms = 0.5 * Izz_arms + 4 * massArm * dz_arm^2;
        
        Ixx_props = 4 * massProp * (y_m^2 + dz_prop^2);
        Iyy_props = 4 * massProp * (x_m^2 + dz_prop^2);
        Izz_props = 4 * massProp * (x_m^2 + y_m^2);
        
        xb = GeometryStruct.x_cgBatt;
        yb = GeometryStruct.y_cgBatt;
        Ixx_batt = 4 * massBatt * (yb^2 + dz_batt^2);
        Iyy_batt = 4 * massBatt * (xb^2 + dz_batt^2);
        Izz_batt = 4 * massBatt * (xb^2 + yb^2);
        
        Ixx_avi = massAvi * dz_avi^2;
        Iyy_avi = massAvi * dz_avi^2;
        Izz_avi = 0;
        
        % Moment of Inertia Tensor 
        Ixx_tot = Ixx_cage + Ixx_arms + Ixx_props + Ixx_batt + Ixx_avi;
        Iyy_tot = Iyy_cage + Iyy_arms + Iyy_props + Iyy_batt + Iyy_avi;
        Izz_tot = Izz_cage + Izz_arms + Izz_props + Izz_batt + Izz_avi;
        
        I_matrix = [Ixx_tot,   0,       0;
                      0,    Iyy_tot,    0;
                      0,       0,    Izz_tot];
        
        GeometryStruct.massCage = massCage;
        GeometryStruct.massArm  = massArm;
        GeometryStruct.massAvi  = massAvi;
        GeometryStruct.massBatt = massBatt;
        GeometryStruct.massProp = massProp;
        GeometryStruct.massTot  = massTot;
        GeometryStruct.z_cgCage = z_cg_Cage;
        GeometryStruct.z_cgArm = z_cg_Prop;
        GeometryStruct.z_cgProp = z_cg_Prop;
        GeometryStruct.z_cgTot = z_cg_tot;
        GeometryStruct.z_cgTot  = z_cg_tot;
        
        GeometryStruct.Ixx = Ixx_tot;
        GeometryStruct.Iyy = Iyy_tot;
        GeometryStruct.Izz = Izz_tot;
        GeometryStruct.I_matrix = I_matrix;

        % --- Stevens & Lewis Inertia Coefficients ---
        Ixx = Ixx_tot;
        Iyy = Iyy_tot;
        Izz = Izz_tot;
        Ixz = 0; % Symmetrical airframe assumption

        
    end
    

    Gamma = Ixx * Izz - Ixz^2;

    Gamma1 = (Ixz * (Ixx - Iyy + Izz)) / Gamma;
    Gamma2 = (Izz * (Izz - Iyy) + Ixz^2) / Gamma;
    Gamma3 = Izz / Gamma;
    Gamma4 = Ixz / Gamma;
    Gamma5 = (Izz - Ixx) / Iyy;
    Gamma6 = Ixz / Iyy;
    Gamma7 = ((Ixx - Iyy) * Ixx + Ixz^2) / Gamma;
    Gamma8 = Ixx / Gamma;

    GeometryStruct.Gamma  = Gamma;
    GeometryStruct.Gamma1 = Gamma1;
    GeometryStruct.Gamma2 = Gamma2;
    GeometryStruct.Gamma3 = Gamma3;
    GeometryStruct.Gamma4 = Gamma4;
    GeometryStruct.Gamma5 = Gamma5;
    GeometryStruct.Gamma6 = Gamma6;
    GeometryStruct.Gamma7 = Gamma7;
    GeometryStruct.Gamma8 = Gamma8;
    
    ACGeo{i} = GeometryStruct;
    i = i + 1;
   
end

end