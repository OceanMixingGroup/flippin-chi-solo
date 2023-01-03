function avg = calibrate_averaged_voltages_fcs(Vavg, head);
% function avg = calibrate_averaged_voltages_fcs(Vavg, head);
%   Calculate T1, T2, P, and Wspd from their means over 'Nseg'-element voltage segments
%
%   Inputs
%   ------
%   Vavg: voltage means calculated on-board
%         or output of mean_of_T_P_voltages if simulating on-board processing with Matlab
%   head: output of load_and_modify_header
%
%   Output
%   ------
%   avg: struct with calibrated T1, T2, T, P, Wspd, Wspd_min, nu, and DT

    c = head.coef;

    avg.T1 = calibrate_temperature(c.T1, Vavg.T1);
    avg.T2 = calibrate_temperature(c.T2, Vavg.T2);
    avg.T = average_temperatures(avg.T1, avg.T2);
    avg.P = calibrate_pressure(c.P, Vavg.P_end);
    avg.Wspd = calibrate_Wspd(c.P, Vavg.Wspd);
    avg.Wspd_min = calibrate_Wspd(c.P, Vavg.Wspd_min);

    % Salinity has minimal effect on nu and DT and isn't measured. Approximate as 35
    S = 35*ones(size(avg.P));
    avg.nu = sw_visc(S, avg.T, avg.P);
    avg.DT = sw_tdif(S, avg.T, avg.P);

function T = calibrate_temperature(cT, VT)
    T = cT(1) + cT(2)*VT + cT(3)*VT.^2;
end

function P = calibrate_pressure(cP, VP_end)
    psi_to_dbar = 1/1.45;
    p_atm = 10.1325;
    P_end = (cP(1) + cP(2)*VP_end)*psi_to_dbar - p_atm;

    % We recorded pressure at the end of the segment, but we really
    % want it at the mid-point
    P = nan(size(P_end));
    P(2:end) = 0.5*(P_end(1:end-1) + P_end(2:end));
    P(1) = P(2) - diff(P_end(1:2));
end

function T = average_temperatures(T1, T2)
    T = mean([T1, T2], 2);
end

function TP = calibrate_TP(cTP, cT, VTP, VT, W)
    % Not actually used, but can be helpful for troubleshooting
    TP = (cT(2) + 2*cT(3)*VT).*VTP./(cTP(1)*W);
end

function Wspd = calibrate_Wspd(cP, VdPdt)
    psi_to_dbar = 1/1.45;
    Wspd = cP(2)*psi_to_dbar*VdPdt;
    Wspd(Wspd < 0) = NaN;
end


end
