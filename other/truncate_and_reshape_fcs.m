function struct_out = truncate_and_reshape_fcs(struct_in, Nseg, head, calibrated_or_voltages)
% function struct_out = truncate_and_reshape_fcs(struct_in, head)
%
%   1. Remove non-profiling data
%   2. Reshape to N x Nseg arrays (removing deepest elements to get multiple of Nseg)
%
%   Inputs
%   ------
%   struct_in: output of raw_load_solo or calibrate_voltages_fcs
%   Nseg: Number of points that will be used later for power spectra
%   head: output of load_and_modify_header
%   calibrated_or_voltages: either 'calibrated' or 'voltages' if struct_in is the output
%       of calibrated_voltages_fcs or raw_load_solo, respectively
%
%   Ken Hughes, July 2021

    assert(ismember(calibrated_or_voltages, {'calibrated', 'voltages'}), ...
        'Last input to truncate_and_reshape_fcs must be ''calibrated'' or ''voltages''')

    s = struct_in;
    Ndata = length(s.time);

    % Get fields that have same the same number of elements as 'time'
    flds = fields(s);
    flds = flds(structfun(@length, s) == Ndata);

    % Reshape everything first
    for ii = 1:length(flds)
        fld_name = flds{ii};
        arr = reshape_to_Nseg(s.(fld_name), head.isUP);
        struct_out.(fld_name) = arr;
    end

    is_profiling = get_profiling_inds(struct_out.P);

    % Truncate resulting arrays
    for ii = 1:length(flds)
        fld_name = flds{ii};
        struct_out.(fld_name) = struct_out.(fld_name)(is_profiling, :);
    end

function Xout = reshape_to_Nseg(X, isUP)
    assert(size(X, 2) == Ndata, 'X to reshape is wrong shape')
    Nz = floor(Ndata/Nseg);
    if isUP
        idx = Ndata-Nseg*Nz+1:Ndata;
    else
        idx = 1:Nseg*Nz;
    end
    Xout = reshape(X(idx), Nseg, Nz)';
end

function profiling_inds = get_profiling_inds(pressure_array)
    % Input is N x Nseg array of pressure values
    % From this, an N-element vector of vertical velocities (Wspd) is derived
    %
    % To find where profiling begins, look for first three consecutive Wspd > Wmin
    % To find where profiling ceases, look for final three consecutive Wspd > Wmin

    % Based on flippin_chi_solo/full/calculate_profiling_speed_full_fcs.m
    Wspd = mean(diff(pressure_array, [], 2), 2)*head.primary_sample_rate;
    if head.isUP
        Wspd = -Wspd;
    end

    % This is the one spot in the "on-board" processing where we need to hard-code
    % a calibration coefficient
    if strcmp(calibrated_or_voltages, 'voltages')
        psi_to_dbar = 1/1.45;
        Wspd = Wspd*head.coef.P(2)*psi_to_dbar;
    end

    Wspd_min = 0.05;
    above_thresh = Wspd > Wspd_min;

    three_consecutive = above_thresh(1:end-2) & above_thresh(2:end-1) & above_thresh(3:end);

    start_idx = find(three_consecutive, 1, 'first');
    end_idx = find(three_consecutive, 1, 'last') + 2;

    profiling_inds = start_idx:end_idx;
end


end
