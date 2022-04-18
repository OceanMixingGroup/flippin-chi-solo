function blk = reshape_to_Nseg_blocks_fcs(struct_in, Nseg, head, calibrated_or_voltages)
% function blk = reshape_to_Nseg_blocks_fcs(struct_in, head)
%
%   Reshape vectors to N x Nseg arrays (removing deepest elements to get multiple of Nseg)
%
%   Inputs
%   ------
%   struct_in: output of raw_load_solo or calibrate_voltages_fcs
%   Nseg: Number of points that will be used later for power spectra
%   head: output of load_and_modify_header
%   calibrated_or_voltages: either 'calibrated' or 'voltages' if struct_in is the output
%       of calibrated_voltages_fcs or raw_load_solo, respectively
%
%   Output
%   ------
%   blk: struct with same quantities as struct_in but with vectors reshaped to arrays
%
%   Ken Hughes, July 2021

    assert(ismember(calibrated_or_voltages, {'calibrated', 'voltages'}), ...
        'Last input to reshape_to_Nseg_blocks_fcs must be ''calibrated'' or ''voltages''')

    s = struct_in;
    Ndata = length(s.time);

    % Get fields that have same the same number of elements as 'time'
    flds = fields(s);
    flds = flds(structfun(@length, s) == Ndata);

    for ii = 1:length(flds)
        fld_name = flds{ii};
        arr = reshape_to_Nseg(s.(fld_name), head.isUP);
        blk.(fld_name) = arr;
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

end
