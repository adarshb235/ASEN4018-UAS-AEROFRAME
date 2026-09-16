function [AeroStruct] = AerodynamicsModel(v_b, params, ACGeo)
%AERODYNAMICSMODEL estimate drag and lift coeffs 
%   calculate component effects for our subsonic operating conditions

    AeroStruct = struct();
    u = v_b(1);
    v = v_b(2);
    w = v_b(3);
    magV = norm(v_b);

    if magV < 1e-6
        F_aero = [0; 0; 0];
        AeroStruct.C_L = 0;
        AeroStruct.C_D = 0;
        AeroStruct.alpha_deg = 0;
        AeroStruct.beta_deg = 0;
        AeroStruct.q_press = 0;
    end

    q_press = 0.5 * params.rho * magV^2;
    alpha = atan2(w, u);
    beta = asin(max(min(v / magV, 1), -1));
    
    if (strcmp(ACGeo.chassisPoly{1,1},'S'))
        A_side = ACGeo.sideLength * ACGeo.heightCage;
        A_planform = ACGeo.sideLength^2;
        A_arm = ACGeo.lengthArm * ACGeo.diaArm;
        A_arm_tot = 4 * A_arm * cosd(45); % projecting arms onto the body axis

        S_x = A_side + A_arm_tot;
        S_y = A_side + A_arm_tot;
        S_z = A_planform + 4 * A_arm;

        % for cross flow at low reynolds (like we have), assume the
        % following CD conditions for bluff body

        C_D_0 = 1.05;
        C_D_max = 1.15;
        C_D_A_rotor = 0.005;

        % directional drag calc

        C_D_x = C_D_max * abs(sin(alpha)^3) + C_D_0 * abs(cos(alpha)^3);
        C_D_y = C_D_max * abs(sin(beta)^3) + C_D_0 * abs(cos(beta)^3);
        C_L_eff = C_D_max * (sin(alpha)^2) * cos(alpha); % effective lift

        D = q_press * [S_x; S_y] .* ([C_D_x; C_D_y] + [C_D_A_rotor; C_D_A_rotor]);
        L = q_press * S_z * C_L_eff;

        F_x = -D(1) * sign(u) * cos(alpha) + L * sin(alpha);
        F_y = -D(2) * sign(v) * cos(beta);
        F_z = -D(1) * sign(u) * sin(alpha) - L * cos(alpha);

        dz_cage = ACGeo.z_cgCage - ACGeo.z_cgTot; 
    
        % M = r_AC x F_aero (where r_AC = [0; 0; dz_cage])
        M_x = -dz_cage * F_y;
        M_y = dz_cage * F_x;
        M_z = 0; % Symmetrical bluff body produces negligible yaw moment
        
        F_aero = [F_x; F_y; F_z];
        M_aero = [M_x; M_y; M_z];

        AeroStruct.C_L = C_L_eff;
        AeroStruct.C_D_x = C_D_x;
        AeroStruct.alpha_deg = rad2deg(alpha);
        AeroStruct.beta_deg = rad2deg(beta);
        AeroStruct.q_press = q_press;
        AeroStruct.F_aero = F_aero;
        AeroStruct.M_aero = M_aero;


        

    end
    
end
