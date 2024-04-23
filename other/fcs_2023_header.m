function head = fcs_2023_header(...
    head, unit_number, data_filename, isUP, profile_time)
% Header modifications for both tests in Feb/Mar and Arcterx in May
% Shear calibrations from ganges_work/Sensor Inventory/Sensor Inventory.xlsx
% Looking at "sensitivity/capacitance Feb 2023" in shear tab

% This may need to change
isArcterxIOP = contains(data_filename, 'arcterx');

switch unit_number
    case '4002'
        head.coef.S1(1) = 0.2715;  % 19-04
        head.coef.S2(1) = 0.2800;  % 19-05
        head.coef.T1 = [1.9899, 0.8178, 2.4073, 0, 0];  % 12-02
        head.coef.T2 = [2.3186, 1.0811, 2.2812, 0, 0];  % 12-06

        if isArcterxIOP
            % Offsets calculated June 9, 2023 with
            % /home/hugke729/osu/matlab/arcterx/calibrate_T_and_P_manually.m
            p_offset = -0.2*isUP + 1.2*~isUP;
            head.coef.P(1) = head.coef.P(1) + p_offset;

            head.coef.T1 = [-21.5095, 15.8826, 0, 0, 0]; % 12-02
            head.coef.T2 = [-20.5480, 15.5666, 0, 0, 0]; % 12-06
        end
    case '4003'
        % Feb and Mar tests
        head.coef.S1(1) = 0.3876;  % 19-03
        head.coef.S2(1) = 0.3459;  % 19-06
        head.coef.T1 = [-0.6441, 3.1493, 1.8824, 0, 0];   % 12-03
        head.coef.T2 = [-0.2792, 1.9824, 2.086, 0, 0];   % 12-04

        if isArcterxIOP
            if profile_time < datenum(2023, 6, 5)
                head.coef.T1 = [-20.5347, 15.4361, 0, 0, 0]; % 12-03
                head.coef.T2 = [-41.7717, 19.6349, 0, 0, 0]; % 09-10
                % Probe 19-01 was assigned to S2 (coef = 0.2603)
                % but it didn't work at all
                head.coef.S2(1) = Inf;
                if profile_time > datenum(2023, 6, 4, 13, 0, 0);
                    % T2 voltage goes to zero in middle of downcast
                    % at 13:12
                    head.coef.T2(:) = NaN;
                end
            else
                % Redeployment after swapping S1, S2, and T2
                head.coef.T1 = [-21.0256, 15.5916, 0, 0, 0]; % 12-03
                head.coef.T2 = [-19.4732, 15.4361, 0, 0, 0]; % 19-03
                head.coef.S1(1) = 0.2669;  % 22-09
                head.coef.S2(1) = 0.2559;  % 19-07
                if profile_time > datenum(2023, 6, 14, 7, 12, 0);
                    % T2 voltage drops ~2V for several profiles, then falls
                    % to 0.07 (presumably not salvageable)
                    head.coef.T2(:) = NaN;
                end
            end

            % Offsets calculated June 9, 2023 with
            % /home/hugke729/osu/matlab/arcterx/calibrate_T_and_P_manually.m
            p_offset = -0.55*isUP + 1.0*~isUP;
            head.coef.P(1) = head.coef.P(1) + p_offset;
        end

end

% Placeholder for differentiator gain
head.coef.S1(4) = 1.21;
head.coef.S2(4) = 1.21;

% For first Feb 2023 test off Scripps, S2 was bad
[~, name, ext] = fileparts(data_filename);
feb2023_test1_files = {'DN_RAW_20190101000002.4002', 'UP_RAW_20230201193553.4002'};
if any(contains(feb2023_test1_files, [name ext]))
    head.coef.S2(1) = Inf;
end

if contains(data_filename, 'SIODive17Mar') | isArcterxIOP
    if strcmp(unit_number, '4002')
        head.coef.AX = [1.7132, -1.0612, 0, 0, 0];
        head.coef.AY = [1.7591, -1.1002, 0, 0, 0];
        head.coef.AZ = [1.7868, -1.0885, 0, 0, 0];
    elseif strcmp(unit_number, '4003')
        head.coef.AX = [1.8581, -1.1034, 0, 0, 0];
        head.coef.AY = [1.7959, -1.0997, 0, 0, 0];
        head.coef.AZ = [1.7701, -1.1060, 0, 0, 0];
    end
end

end
