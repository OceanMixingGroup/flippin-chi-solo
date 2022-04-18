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
    avg.P = calibrate_pressure(c.P, Vavg.P);
    avg.Wspd = calibrate_Wspd(c.P, Vavg.Wspd);
    avg.Wspd_min = calibrate_Wspd(c.P, Vavg.Wspd_min);

    % Salinity has minimal effect on nu and DT and isn't measured. Approximate as 35
    S = 35*ones(size(avg.P));
    avg.nu = sw_visc(S, avg.T, avg.P);
    avg.DT = sw_tdif(S, avg.T, avg.P);

function T = calibrate_temperature(cT, VT)
    T = cT(1) + cT(2)*VT + cT(3)*VT.^2;
end

function P = calibrate_pressure(cP, VP)
    psi_to_dbar = 1/1.45;
    p_atm = 10.1325;
    P = (cP(1) + cP(2)*VP)*psi_to_dbar - p_atm;
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
