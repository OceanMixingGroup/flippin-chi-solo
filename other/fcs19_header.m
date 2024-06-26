function head = fcs19_header(head, unit_number, isUP, profile_time)

% Modifications for 4002 and 4003 for FCS19 were developed
% by Aurelie Moulin
switch unit_number
    case '4002'
        % Shear coefficients were wrongly assigned in the original header file
        % Sensitivity values in /ganges/data/fcs19/pre_cruise/fcs/calibrations/shear/...
        %    ShearCal_18-03_2019-05-07_cal1_final.png
        %    ShearCal_18-04_2019-05-07_cal1_final.png
        head.coef.S1(1) = 0.2258;
        head.coef.S2(1) = 0.2755;
        % Gain was not assigned in the original header file
        % Gain values in /ganges/data/fcs19/pre_cruise/fcs/calibrations/differentiator_shear_TP/...
        %    FCS001/FCS3_S1_1.png
        %    FCS001/FCS3_S1_2.png
        head.coef.S1(4) = 1.21;
        head.coef.S2(4) = 1.19;

        % p_offset is small, empirical correction after subtracting atmospheric pressure of 14.5 psi
        p_offset = -0.9*isUP + -0.0*~isUP;
        head.coef.P(1) = head.coef.P(1) + p_offset;

        % Aurelie's coefficients based on fit to SBE on SOLO
        head.coef.T1 = [-6.9914 9.4796 0.34797 0 0];
        head.coef.T2 = [-8.2162 9.2627 0.38410 0 0];
    case '4003'
        % See 4002 for details on where calibrations are recorded

        % Sensor assignments given in /ganges/data/fcs19/pre_cruise/fcs/fcs_sensor_assisgnment.xlsx
        % S1 was changed in May 15
        [S1_id, S2_id] = deal(9, 12);
        if profile_time > datenum(2019, 5, 15, 18, 04, 0)
            head.sensor_id{S1_id} = '19-02';
            head.coef.S1(1) = 0.2763;
        else
            head.sensor_id{S1_id} = '12-04';
            head.coef.S1(1) = 0.2781;
        end
        % It appears, however, that S1 is bad throughout the whole experiment
        % Setting sensitivity to Inf so that S1 and epsilon1 will equal 0
        % Leaving earlier calibration for reference
        head.coef.S1(1) = Inf;

        head.sensor_id{S2_id} = '12-09';
        head.coef.S2(1) = 0.3434;

        head.coef.S1(4) = 1.12;
        head.coef.S2(4) = 1.12;

        p_offset = -0.5*isUP + 0.1*~isUP;
        head.coef.P(1) = head.coef.P(1) + p_offset;

        % Aurelie's coefficients based on fit to SBE on SOLO
        head.coef.T1 = [-9.46889 11.4976 -0.0796463 0 0];
        head.coef.T2 = [-8.40900 11.1693 -0.0847826 0 0];
end

end
