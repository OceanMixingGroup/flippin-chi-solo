function phi = remove_data_when_pump_on_fcs(phi, blk, head);
% function phi = remove_data_when_pump_on_fcs(phi, blk);
%
%   The SOLO pump leaves a tell-tale ~35Hz oscillation in many of the raw signals.
%   Since it ruins the shear signal, the resulting spectra are set to NaN
%
%   Input
%   -----
%   phi: output of calc_spectra_fcs
%   blk: output of truncate_and_reshape_fcs
%   head: output of load_and_modify_header
%
%   Output
%   ------
%   phi: same as input, but with the spectra that are affected by pump set to NaN
%
%   Ken Hughes, July 2021

    % Empirical value from manual tests for how much larger AX spectrum is over the
    % 33-37Hz range
    ratio_max = 15;

    Nz = size(blk.time, 1);
    % Using AZ signal as pump signal shows up particularly well
    AZ = blk.AZ - mean(blk.AZ, 2);

    pump_on = false(1, Nz);
    for zi = 2:Nz-1
        [pxx, f] = pwelch(AZ(zi, :), head.Nfft, 0, head.Nfft, head.primary_sample_rate);
        [pump_idx, no_pump_idx] = get_pump_indices(f);
        ratio = max(pxx(pump_idx))/mean(pxx(no_pump_idx));

        if ratio > ratio_max
            % To be conservative, we'll assume the pump is on for not only current
            % segment but the ones immediately before or after as well.
            pump_on(zi-1:zi+1) = true;
        end
    end

    for fld = {'S1', 'S2', 'T1P', 'T2P'}
        phi.(fld{:})(pump_on, :) = NaN;
    end

function [pump_idx, no_pump_idx] = get_pump_indices(f)
    % Pump frequency lies within these bounds
    pump_f_bounds = [33, 37];
    % Control bounds that are unaffected by pump
    no_pump_f_bounds = [40, 50];

    pump_idx = f > pump_f_bounds(1) & f < pump_f_bounds(2);
    no_pump_idx = f > no_pump_f_bounds(1) & f < no_pump_f_bounds(2);
end

end
