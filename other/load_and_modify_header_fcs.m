function head = load_and_modify_header_fcs(header_dir, unit_number, data_filename)
% function head = load_and_modify_header_fcs(header_dir, unit_number, data_filename)
%   Load the header file and make corrections and experiment-specific modifications
%
%   Inputs
%   ------
%   header_dir: string pointing to directory (with trailing /) containing header file
%   unit_number: for FCS19, this is either '4002' or '4003'
%   data_filename: absolute path to raw data file. See notes
%
%   Output
%   ------
%   head: struct containing multiple header details
%
%   Output
%   ------
%   data_filename is required since the header changes
%     1. depending on profile direction, which is included in the filename
%     2. if sensors are changed, which can be manually noted
%
%   Ken Hughes, July 2021

switch unit_number
    % FCS19 had unfortunate convention that 4002 goes with FCS001 and 4003 goes with FCS002
    case '4002'
        pod = 'FCS001';
    case '4003'
        pod = 'FCS002';
end

% Load original header
load([header_dir 'header_' pod '.mat'], 'head');

[profile_time, isUP] = parse_filename_fcs(data_filename);
head.isUP = isUP;
head.data_filename = data_filename;

% Power spectra options
head.Nseg = 512;
head.Nfft = 256;
head.Noverlap = 128;

% Modifications for 4002 and 4003 for FCS19 were developed by Aurelie Moulin
if profile_time > datenum(2019, 5, 12) & profile_time < datenum(2019, 5, 18)
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

else
    % Temporary place holder for Feb 2023 tests off of San Diego
    % Shear calibations from ganges_work/Sensor Inventory/Sensor Inventory.xlsx
    % Looking at "sensitivity/capacitance Feb 2023" in shear tab

    % Temperature calibrations from
    % ganges/data/fcs19/pre_cruise/fcs/calibrations/temperature/FCS00[1,2]/*cals.png

    switch unit_number
        case '4002'
            head.coef.S1(1) = 0.2715;  % 19-04
            head.coef.S2(1) = 0.2800;  % 19-05
            head.coef.T1 = [1.9899, 0.8178, 2.4073, 0, 0];  % 12-02
            head.coef.T2 = [2.3186, 1.0811, 2.2812, 0, 0];  % 12-06
        case '4003'
            head.coef.S1(1) = 0.3876;  % 19-03
            head.coef.S2(1) = 0.3459;  % 19-06
            head.coef.T1 = [-0.6441, 3.1493, 1.8824, 0, 0];   % 12-03
            head.coef.T2 = [-0.2792, 1.9824, 2.086, 0, 0];   % 12-04
        end

    % Placeholder for differentiator gain
    head.coef.S1(4) = 1.21;
    head.coef.S2(4) = 1.21;
end

% For first Feb 2023 test off Scripps, S2 was bad
[~, name, ext] = fileparts(data_filename);
feb2023_test1_files = {'DN_RAW_20190101000002.4002', 'UP_RAW_20230201193553.4002'};
if any(contains(feb2023_test1_files, [name ext]))
    head.coef.S2(1) = Inf;
end

end
