function cal = calibrate_voltages_fcs(raw_data_struct, head)
% function calibrate_voltages_fcs(raw_data_struct, head)
%   Calibrate raw voltage signals with coefficients from head
%
%   Inputs
%   ------
%   raw_data_struct: output of raw_load_solo
%   head: output from load_and_modify_header
%
%   Output
%   ------
%   cal: struct with physical quanties
%        T1, T2 (deg C), P (dbar), Wspd (m/s), T1P, T2P (deg C/m), S1, S2 (/s)
%        AX, AY, AZ (m/s^2)
%
%   Ken Hughes, July 2021

    c = head.coef;
    d = raw_data_struct;
    fs = head.primary_sample_rate;

    cal = struct;
    cal.time = d.time;  % Calibration not needed
    cal.T1 = calibrate_temperature(c.T1, d.T1);
    cal.T2 = calibrate_temperature(c.T2, d.T2);
    cal.P = calibrate_pressure(c.P, d.P);
    cal.Wspd = calculate_Wspd(cal.P);
    cal.T1P = calibrate_Tprime(c.T1P, c.T1, d.T1P, d.T1, cal.Wspd);
    cal.T2P = calibrate_Tprime(c.T2P, c.T2, d.T2P, d.T2, cal.Wspd);
    cal.S1 = calibrate_shear(c.S1, d.S1, cal.Wspd);
    cal.S2 = calibrate_shear(c.S2, d.S2, cal.Wspd);
    cal.AX = calibrate_acceleration(c.AX, d.AX);
    cal.AY = calibrate_acceleration(c.AY, d.AY);
    cal.AZ = calibrate_acceleration(c.AZ, d.AZ);


function T = calibrate_temperature(cT, VT)
    T = cT(1) + cT(2)*VT + cT(3)*VT.^2;
end

function P = calibrate_pressure(cP, VP)
    psi_to_dbar = 1/1.45;
    p_atm = 10.1325;
    P = (cP(1) + cP(2)*VP)*psi_to_dbar - p_atm;
    P = filter_2Hz(P, 'lowpass');
end

function TP = calibrate_Tprime(cTP, cT, VTP, VT, Wspd)
    VTP = filter_point3Hz(VTP, 'highpass');
    TP = (cT(2) + 2*cT(3)*VT).*VTP./(cTP(1)*Wspd);
end

function shear = calibrate_shear(cS, Vs, Wspd)
    % Shear voltage usually has ~2V DC component
    Vs = filter_point3Hz(Vs, 'highpass');
    alpha_coef = get_alpha_coef(cS);
    shear = alpha_coef*Vs./Wspd.^2;
end

function A = calibrate_acceleration(cA, VA)
    g = 9.81;
    A = g*(cA(1) + cA(2)*VA);
end

function Vfilt = filter_2Hz(V, low_or_high)
    fc = 2;
    [b, a] = butter(4, fc/(fs/2), low_or_high(1:end-4));
    Vfilt = filtfilt(b, a, V);
end

function Vfilt = filter_point3Hz(V, low_or_high)
    fc = 0.3;
    [b, a] = butter(4, fc/(fs/2), low_or_high(1:end-4));
    Vfilt = filtfilt(b, a, V);
end

function Wspd = calculate_Wspd(P)
    Wspd = gradient(P)*head.primary_sample_rate;
    if head.isUP
        Wspd = -Wspd;
    end
end

end
