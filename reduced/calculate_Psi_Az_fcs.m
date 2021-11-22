function [Vpsi_Az, f_Az] = calculate_Psi_Az_fcs(data, fs, head)
% function [Vpsi_Az, f_Az] = calculate_Psi_Az_fcs(data)
%   If there exists a 256-s period at which FCS is at the surface and facing downward,
%   then calculate the spectrum of AZ voltage corrected for pitch and roll
%
%   Input
%   -----
%   data: output of raw_load_solo (must include both surface data and profiling data)
%   fs: sampling frequency
%   head: output of load_and_modify_header
%
%   Output
%   ------
%   Vpsi_Az: Spectrum of V_Az^wave for f < 0.5
%   f_Az: Associated frequency vector
%
%   Ken Hughes, Nov 2019

    f_max_out = 0.5; % Return only spectra below this frequency
    f_subsample = 2; % Hz
    N_seconds = 512/f_subsample;  % 256-s
    c2Ap = head.c2Ap;

    P_approx = approximate_pressure();
    [c1Axp, c1Ayp, c1Azp] = calibrate_C1A_coefs();
    idx_start = find_when_surfaced_and_pointing_down();
    if isempty(idx_start)
        % Surface record too short, so return dummy vectors of 128 elements
        [Vpsi_Az, f_Az] = deal(nan(head.Nfft/2*f_max_out, 1));
    else
        V_Az_wave = calc_V_Az_wave();
        [Vpsi_Az, f_Az] = calc_V_Az_spectra();
    end

function P_approx = approximate_pressure()
    % If the record starts with FCS pointing upward, then P_approx is a good
    % approximation of the true pressure
    psi_to_dbar = 1/1.45;
    P_approx = (data.P - min(data.P))*head.c2P*psi_to_dbar;
end

function [c1Axp, c1Ayp, c1Azp] = calibrate_C1A_coefs()
    % Derive c1Ax' and c1Ay' based on average V_AX and V_AY over deep part of profile
    % There are many possible ways to do this. Here use any values that are within
    % 60 to 90% of the maximum pressure
    normalized_pressure = P_approx/max(P_approx);
    near_bottom = normalized_pressure > 0.6 & normalized_pressure < 0.9;
    c1Axp = -c2Ap*mean(data.AX(near_bottom))
    c1Ayp = -c2Ap*mean(data.AY(near_bottom))

    % c1Azp in not described in the paper, but it follows the same logic as
    % c1Axp and c1Ayp, except that the mean is +g, not zero.
    c1Azp = 1 - c2Ap*mean(data.AY(near_bottom));
end

function idx_start = find_when_surfaced_and_pointing_down()
    g = 9.81;
    AZ_approx = g*(c1Azp + c2Ap*data.AZ);

    % Find where acceleration nearing full (7 m/s^2), then add 20 seconds.
    % For FCS19 at least, the DN profiles contain a short initial segment with
    % FCS pointing upward.
    idx_start = find(AZ_approx > 7, 1, 'first') + 20*fs;

    % Ensure that 256 seconds later (plus a 15s buffer), the pressure hasn't changed
    % by more than 3dbar (i.e., the dive has yet to begin).
    if P_approx(idx_start + (N_seconds+15)*fs) > P_approx(idx_start) + 3;
        idx_start = [];
    end
end

function V_Az_wave = calc_V_Az_wave()
    idx = idx_start:fs/f_subsample:idx_start+N_seconds*fs-1;
    root_arg = 1 - (c1Axp + c2Ap*data.AX(idx)).^2 - (c1Ayp + c2Ap*data.AY(idx)).^2;
    V_Az_wave = data.AZ(idx) - (1/c2Ap)*sqrt(root_arg);
end

function [Psi_Az, f_Az] = calc_V_Az_spectra()
    [Psi_Az, f_Az] = pwelch(detrend(V_Az_wave), head.Nfft, 0, head.Nfft, f_subsample);
    Psi_Az = Psi_Az(f_Az < f_max_out);
    f_Az = f_Az(f_Az < f_max_out);
end

end
