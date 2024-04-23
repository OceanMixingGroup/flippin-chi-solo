function head = load_and_modify_header_fcs(...
    header_dir, unit_number, data_filename)
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
    % Unfortunate convention that
    % 4002 goes with FCS001
    % 4003 goes with FCS002
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


if contains(data_filename, '201905')
    head = fcs19_header(head, unit_number, isUP, profile_time);
else
    head = fcs_2023_header(head, unit_number, data_filename, ...
                           isUP, profile_time);
end

end
