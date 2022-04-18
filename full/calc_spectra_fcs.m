function phi = calc_spectra_fcs(blk, head)
% function calc_spectra_fcs(blk)
%   Calculate power spectra of shear and Tprime vs wavenumber
%   And correct for sensor responses
%
%   Input
%   -----
%   blk: output of truncate_and_reshape_fcs (blk short for block array)
%
%   Output
%   ------
%   phi: struct containing power spectra for shear and TP and associated k and f
%        spectra are corrected for lost variance at small scales
%
%   Ken Hughes, July 2021

    Nz = size(blk.P, 1);

    % Pre-allocate outputs
    [phi.S1, phi.S2, phi.T1P, phi.T2P, phi.k] = deal(nan(Nz, head.Nfft/2 + 1));
    phi.Wspd = nan(Nz, 1);

    for zi = 1:Nz
        W = mean(blk.Wspd(zi, :));
        phi.Wspd(zi) = W;
        if W < 0.05
            % Below 5 cm/s, f to k conversion becomes problematic.
            % So don't calculate spectra for this block. Skip to next zi instead
            continue
        end

        [phi.S1(zi, :), phi.k(zi, :), phi.f] = calc_wavenumber_spec(blk.S1(zi, :), W, 'S');
        phi.S2(zi, :) = calc_wavenumber_spec(blk.S2(zi, :), W, 'S');
        phi.T1P(zi, :) = calc_wavenumber_spec(blk.T1P(zi, :), W, 'TP');
        phi.T2P(zi, :) = calc_wavenumber_spec(blk.T2P(zi, :), W, 'TP');
    end


function [phi_x, k, f] = calc_wavenumber_spec(x, W, spec_type)
    % For vector x, calculate power spectrum in wavenumber units and correct appropriately
    assert(length(x) == head.Nseg, 'x wrong shape')
    assert(length(W) == 1, 'W must be single value')
    assert(ismember(spec_type, {'S', 'TP'}), 'spec_type is incorrect')

    x = detrend(x);
    [phi_x, f] = pwelch(x, head.Nfft, head.Noverlap, head.Nfft, head.primary_sample_rate);
    % Reshape output from N x 1 to 1 x N
    phi_x = phi_x(:)';
    f = f(:)';

    % Convert to wavenumber space
    k = f/W;
    phi_x = phi_x*W;

    % Correct for lost variance
    switch spec_type
        case 'S'
            H2k = complete_shear_transfer_function_fcs(f, W);
        case 'TP'
            H2k = complete_thermistor_transfer_function_fcs(f, W);
    end
    phi_x = phi_x./H2k;

end

end
