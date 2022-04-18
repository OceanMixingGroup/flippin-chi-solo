function [avg, blk] = remove_nonprofiling_data_fcs(avg, blk, head, calibrated_or_voltages)
% function [avg, blk] = remove_nonprofiling_data_fcs(avg, blk, calibrated_or_voltages)
%
%   Inputs
%   ------
%   avg: output of mean_of_T_P_voltages or average_over_blocks_fcs
%   blk: output of reshape_to_Nseg_blocks
%   head: output of load_and_modify_header
%   calibrated_or_voltages: either 'calibrated' or 'voltages'
%       (Need to know whether avg.Wspd_min is in m/s or V/s)

    assert(ismember(calibrated_or_voltages, {'calibrated', 'voltages'}), ...
        'Last input to remove_nonprofiling_data must be ''calibrated'' or ''voltages''')

    Wspd_min = avg.Wspd_min;

    avg = remove_nonprofiling_data_from_struct(avg, Wspd_min);
    blk = remove_nonprofiling_data_from_struct(blk, Wspd_min);

function s = remove_nonprofiling_data_from_struct(s, Wspd_min)
    Ndata = numel(s.T1);

    % Get fields that have same the same number of elements as T1 (a somewhat arbitrary choice)
    flds = fields(s);
    flds = flds(structfun(@numel, s) == Ndata);

    is_profiling = get_profiling_inds(Wspd_min);

    % Truncate resulting arrays
    for ii = 1:length(flds)
        fld_name = flds{ii};
        s.(fld_name) = s.(fld_name)(is_profiling, :);
    end
end

function profiling_inds = get_profiling_inds(Wspd_min)
    % Input is N-element vector of min(W)
    %
    % To find where profiling begins, look for first three consecutive Wspd > 0.05
    % To find where profiling ceases, look for first three consecutive Wspd < 0.05
    % (after profiling has begun, obviously)
    if strcmp(calibrated_or_voltages, 'voltages')
        psi_to_dbar = 1/1.45;
        Wspd_min = Wspd_min*head.c2P*psi_to_dbar;
    end

    Wspd_min_threshold = 0.05;
    above_thresh = Wspd_min > Wspd_min_threshold;

    three_consecutive_above = above_thresh(1:end-2) & above_thresh(2:end-1) & above_thresh(3:end);
    start_idx = find(three_consecutive_above, 1, 'first');

    below_thresh = ~above_thresh;
    below_thresh(1:start_idx) = false;
    three_consecutive_below = below_thresh(1:end-2) & below_thresh(2:end-1) & below_thresh(3:end);
    end_idx = find(three_consecutive_below, 1, 'first') - 1;

    if isempty(end_idx)
        % Account for possibility that file is stopped before three consecutive Wspd < 0.05
        end_idx = length(Wspd_min);
    end

    profiling_inds = start_idx:end_idx;
end

end
