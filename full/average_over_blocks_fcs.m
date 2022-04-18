function avg = average_over_blocks_fcs(blk)
% function avg = average_over_blocks_fcs(blk)
%   Average each Nseg-length segment and derive viscosity and diffusivity
%
%   Input
%   -----
%   blk: output of truncate_and_reshape_fcs
%
%   Output
%   ------
%   avg: struct with Nz x 1 averages of time, T1, T2, T (mean 1 + 2), P, Wspd, Wspd_min, nu, and DT

    avg_dim = 2;
    avg.time = mean(blk.time, avg_dim);
    avg.T1 = mean(blk.T1, avg_dim);
    avg.T2 = mean(blk.T2, avg_dim);
    avg.T = 0.5*avg.T1 + 0.5*avg.T2;
    avg.P = mean(blk.P, avg_dim);
    avg.Wspd = mean(blk.Wspd, avg_dim);
    avg.Wspd_min = min(blk.Wspd, [], avg_dim);

    % Salinity has minimal effect on nu and DT and isn't measured. Approximate as 35
    S = 35*ones(size(avg.P));
    avg.nu = sw_visc(S, avg.T, avg.P);
    avg.DT = sw_tdif(S, avg.T, avg.P);

end
