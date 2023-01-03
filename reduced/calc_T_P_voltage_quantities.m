function Vavg = calc_T_P_voltage_quantities(Vblk, head)
% function calc_T_P_voltage_quantities(Vblk)
%   Calculate voltage quantities that are required to reproduce T, P, and Wspd
%
%   Input
%   -----
%   Vblk: output of reshape_to_Nseg_blocks_fcs(<raw data>)
%   head: output of load_and_modify_header
%
%   Output
%   -----
%   Vavg: struct with the following quantities for each segment
%       means of T1 and T2 voltages for T1, T2
%       the final pressure voltage (P_end)
%       the minimum profiling speed in voltage units
%
%   Ken Hughes, Dec 2022

    avg_dim = 2;

    Vavg.T1 = mean(Vblk.T1, avg_dim);
    Vavg.T2 = mean(Vblk.T2, avg_dim);

    Vavg.P_end = Vblk.P(:, end);

    % In the paper, the calculation below uses absolute values
    % Here, however, we want to avoid an edge case that arises in practice
    % of an up profile starting with a period of downward movement, or vice versa,
    % Hence, we're being more explicit
    ti = 1:50:head.Nseg;
    Delta_VP_ti = diff(Vblk.P(:, ti), [], avg_dim);
    Delta_VP = [diff(Vavg.P_end(1:2)); diff(Vavg.P_end)];

    if head.isUP
        Delta_VP_ti = -Delta_VP_ti;
        Delta_VP = -Delta_VP;
    end

    dt = 1/head.primary_sample_rate;
    Vavg.Wspd_min = min(Delta_VP_ti/(50*dt), [], avg_dim);
    Vavg.Wspd = Delta_VP/(head.Nseg*dt);
end
