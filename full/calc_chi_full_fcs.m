function [avg, phi] = calc_chi_full_fcs(phi, avg)
% function calc_chi_full_fcs(phi)
%   Calculate thermal variance dissipation rate in the same way it is done for Chameleon
%
%   Input
%   -----
%   phi: output of calc_spectra_fcs
%        i.e., a struct containing Nz rows of spectra for S1, S2, T1P, T2P
%        and Nz rows of associated wavenumbers
%   avg: output of average_over_blocks_fcs
%        i.e., a struct containing column vectors of length Nz of segment-averaged
%        parameters including nu
%
%   Output
%   ------
%   avg: same as input with the following Nz-element vectors added
%        chi1, chi2: thermal variance dissipation rate derived from spectra
%        chi: mean value of chi1 and chi2, or lower if differing by factor of 10 or more
%   phi: same as input with following Nz-element vectors added
%        kend1_TP, k_end2_TP: upper limit of integral over TP spectra
%
%   References
%   ----------
%   Appendix A of Moum et al. (1995) J. Atmos. Oceanic Tech.
%   doi: 10.1175/1520-0426(1995)012<0346:COTKED>2.0.CO;2
%
%   mixingsoftware/marlcham/calc_chi.m
%
%   Ken Hughes, July 2021

    k_start = 2;  % calc_chi.m suggests 1--3 Hz, so let's go with 2
    Nz = size(phi.k, 1);

    [avg.chi1, avg.chi2, avg.chi, phi.k_end1_TP, phi.k_end2_TP] = deal(nan(Nz, 1));

    for zi = 1:Nz
        [k, epsilon, Wspd, nu, DT] = deal(...
            phi.k(zi, :), avg.epsilon(zi), avg.Wspd(zi), avg.nu(zi), avg.DT(zi));

        [avg.chi1(zi), phi.k_end1_TP(zi)] = chi_from_spec(...
            phi.T1P(zi, :), k, epsilon, Wspd, nu, DT);
        [avg.chi2(zi), phi.k_end2_TP(zi)] = chi_from_spec(...
            phi.T2P(zi, :), k, epsilon, Wspd, nu, DT);
        avg.chi(zi) = combine_turbulence_values_fcs(avg.chi1(zi), avg.chi2(zi));
    end


function [chi, k_end] = chi_from_spec(phi_TP, k, epsilon, Wspd, nu, DT)
    phi_TP(isnan(phi_TP)) = 0; % integrate.m can't handle NaNs
    k_end = get_integration_endpoint(epsilon, Wspd, nu, DT, phi_TP, k);

    chi_obs_part = 6*DT*integrate(k_start, k_end, k, phi_TP);

    % Use fact that Kraichnan spectrum is linear in chi to adjust chi_meas_part
    % In other words, since we know what integration limits we are using, we know
    % from integrating the Kraichnan spectrum what fraction we are picking up
    tmp_chi = 1e-7; % Arbitrary value
    k_Kr = logspace(-2, 4, 500);
    q = 5.26;
    phi_Kr = kraichnan_fcs(k_Kr, epsilon, tmp_chi, 'nu', nu, 'DT', DT, 'q', q);
    chi_Kr_part = 6*DT*integrate(k_start, k_end, k_Kr, phi_Kr);
    fraction_included = chi_Kr_part/tmp_chi;

    chi = chi_obs_part/fraction_included;
end

function k_end = get_integration_endpoint(epsilon, Wspd, nu, DT, phi_in, k)
    kb = batchelor_wavenumber_cpm(epsilon, nu, DT);
    % 15Hz is cutoff copied from Chameleon code. See calc_chi
    k_15Hz = 15/Wspd;

    k_end = min(kb, k_15Hz);

    % Reduce k_end if phi_in doesn't reach that far
    [~, k_max_idx] = find(phi_in == 0, 1, 'first');
    if k_end > k(k_max_idx) & k_max_idx > 1
        k_end = k(k_max_idx - 1);
    end
end

function kb = batchelor_wavenumber_cpm(epsilon, nu, DT)
    kb = (epsilon/(nu*DT^2))^(1/4)/(2*pi);
end


end
