function blk = despike_shear_blocks_fcs(blk)
% function blk = despike_shear_blocks_fcs(blk)
%
% Within each block, remove data points that are more than 3 standard deviations
%
%   Input
%   -----
%   blk: struct with fields that have shapes Nz x Nseg
%        i.e., output of reshape_to_Nseg_blocks_fcs and remove_nonprofiling_data_fcs
%
%   Output
%   ------
%   blk: same as input with S1 and S2 modified such that spikes are set to the
%        mean over the 'Nseg'-length element
%
%   Ken Hughes, August 2021

    Nz = size(blk.time, 1);
    for zi = 1:Nz
        blk.S1(zi, :) = despike_segment(blk.S1(zi, :));
        blk.S2(zi, :) = despike_segment(blk.S2(zi, :));
    end

function X = despike_segment(X)
    X_mean = mean(X);
    spikes = abs(X - X_mean) > 3*std(X);
    X(spikes) = mean(X(~spikes));
end

end
