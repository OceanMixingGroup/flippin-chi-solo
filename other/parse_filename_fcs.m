function [mtime, isUP] = parse_filename_fcs(data_filename)
% function mtime = parse_filename_fcs(data_filename)
%   Convert the time string in the filename of a raw FCS file to Matlab time
%
%   Input
%   -----
%   data_filename: relative or absolute path of raw data file
%
%   Output
%   ------
%   mtime: Matlab datenum value to the nearest second

%   Example filename is .../fcs/4003/raw/DN_RAW_20190514072003.002
    [~, fname, ~] = fileparts(data_filename);

    [yy, MM, dd, hh, mm, ss] = deal(...
        str2num(fname(8:11)), ...
        str2num(fname(12:13)), ...
        str2num(fname(14:15)), ...
        str2num(fname(16:17)),  ...
        str2num(fname(18:19)), ...
        str2num(fname(19:20)));

    mtime = datenum(yy, MM, dd, hh, mm, ss);

    if contains(data_filename, 'UP_')
        isUP = true;
    elseif contains(data_filename, 'DN_')
        isUP = false;
    end
end
