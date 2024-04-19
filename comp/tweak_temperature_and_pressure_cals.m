function avg = tweak_temperature_and_pressure_cals(avg, data_filename)
% function avg = tweak_temperature_and_pressure_cals(avg)
%    Using CTD data from the SBE on the SOLO, modify
%    temperature and pressure calibrations so they match well
%
%   Input
%   ------
%   avg: struct containing approximately calibrated T1, T2, and P
%   data_filename: absolute path to compressed data file
%
%   Output
%   ------
%   avg: same as input with T1, T2, and P modified
%
%   Notes
%   -----
%   This function is fragile as it depends on the coefficients
%   defined elsewhere (e.g., fcs_2023_header.m)
%   If these are later changed, then the function will not make sense

isArcterxIOP = contains(data_filename, 'arcterx');

if isArcterxIOP
    switch unit_number
        case '4002'
            % body
        case '4003'
            % body
    end
end

end
