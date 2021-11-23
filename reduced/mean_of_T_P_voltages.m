function Vavg = mean_of_T_P_voltages(Vblk, head)
% function mean_of_T_P_voltages(Vblk)
%   Calculate means of voltage channels that are required to reproduce T, P, and Wspd
%
%   Input
%   -----
%   Vblk: output of reshape_to_Nfft_blocks_fcs(<raw data>)
%   head: output of load_and_modify_header
%
%   Output
%   -----
%   Vavg: struct with means of voltages for T1, T1sq, T2, T2sq, P, Wspd, and Wspd_min
%
%   Ken Hughes, July 2021

    avg_dim = 2;

    Vavg.T1sq = mean(Vblk.T1.^2, avg_dim);
    Vavg.T1 = mean(Vblk.T1, avg_dim);
    Vavg.T2sq = mean(Vblk.T2.^2, avg_dim);
    Vavg.T2 = mean(Vblk.T2, avg_dim);

    Vavg.P = mean(Vblk.P, avg_dim);
    
    ti = 1:50:head.Nfft;
    Delta_VP = Vblk.P(:, end) - Vblk.P(:, 1);
    Delta_VP_ti = diff(Vblk.P(:, ti), [], avg_dim);

    if head.isUP
        Delta_VP = -Delta_VP;
        Delta_VP_ti = -Delta_VP_ti;
    end

    dt = 1/head.primary_sample_rate;
    Vavg.Wspd = Delta_VP/((head.Nfft - 1)*dt);
    Vavg.Wspd_min = min(Delta_VP_ti/(50*dt), [], avg_dim);
end
