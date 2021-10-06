function [avg, phi] = calc_epsilon_full_fcs(phi, avg)
% function calc_epsilon_full_fcs(phi)
%   Calculate turbulence dissipation rate in the same way it is done for Chameleon
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
%        eps1, eps2: dissipation rate derived from spectra
%        epsilon: mean value of eps1 and eps2, or lower if differing by factor of 10 or more
%   phi: same as input with the following Nz-element vectors added
%        k_end1_s, k_end2_s: upper integration limit of wavenumber spectra
%
%   Reference
%   ---------
%   Appendix A of Moum et al. (1995) J. Atmos. Oceanic Tech.
%   doi: 10.1175/1520-0426(1995)012<0346:COTKED>2.0.CO;2
%
%   Ken Hughes, July 2021

    [k_start, k_stop_min, k_stop_max] = deal(2, 10, 45);

    Nz = size(phi.k, 1);
    [avg.eps1, avg.eps2, avg.epsilon, phi.k_end1_s, phi.k_end2_s] = deal(nan(Nz, 1));

    for zi = 1:Nz
        [nu, Wspd] = deal(avg.nu(zi), avg.Wspd(zi));
        [avg.eps1(zi), phi.k_end1_s(zi)] = iterate_to_eps(phi.S1(zi, :), phi.k(zi, :), nu, Wspd);
        [avg.eps2(zi), phi.k_end2_s(zi)] = iterate_to_eps(phi.S2(zi, :), phi.k(zi, :), nu, Wspd);
        avg.epsilon(zi) = combine_turbulence_values_fcs(avg.eps1(zi), avg.eps2(zi));
    end


function [epsilon, k_end] = iterate_to_eps(phi_s, k, nu, Wspd)
    % Iterate toward solution in which observed and Nasymth integrals match over
    % k_start to k_stop

    % First deal with case where spectra are NaNs because pump was running
    if all(isnan(phi_s))
        [epsilon, k_end] = deal(NaN);
        return
    end

    % Now deal with all meaningful cases
    phi_s(isnan(phi_s)) = 0; % integrate.m can't handle NaNs

    % First guess of epsilon uses k = 2-10 cpm
    eps_init = 7.5*nu*integrate(k_start, k_stop_min, k, phi_s);
    ks_init = kolmogorov_wavenumber_cpm(eps_init, nu);
    k_end = get_next_integration_endpoint(ks_init, phi_s, k, Wspd);

    % Dummy values to start off iteration
    eps_obs_part = eps_init;
    eps_nas_part = 0.5*eps_init;
    epsilon = eps_init;

    niter = 0;
    while abs(eps_obs_part/eps_nas_part - 1) > 0.01 & niter < 20
        eps_obs_part = 7.5*nu*integrate(k_start, k_end, k, phi_s);
        phi_Na = nasmyth_fcs(k, epsilon, 'nu', nu);
        eps_nas_part = 7.5*nu*integrate(k_start, k_end, k, phi_Na);

        % Adjust epsilon for next iteration
        ks = kolmogorov_wavenumber_cpm(epsilon, nu);
        k_end = get_next_integration_endpoint(ks, phi_s, k, Wspd);
        epsilon = epsilon*(eps_obs_part/eps_nas_part);

        niter = niter + 1;
    end

    if niter == 20
        epsilon = NaN;
    end
end

function ks = kolmogorov_wavenumber_cpm(epsilon, nu)
    ks = (epsilon/nu^3)^(1/4)/(2*pi);
end


function k_end = get_next_integration_endpoint(ks, phi_in, k, Wspd)
% See page 358 of Moum et al. (1995)
% But veto this choice if phi(k_end) is 0 (i.e., meaningless because shear probe
% correction factor is too large)
    if 0.5*ks >= k_stop_max
        k_end = k_stop_max;
    elseif 0.5*ks < k_stop_min
        k_end = k_stop_min;
    else
        k_end = 0.5*ks;
    end

    % Ensure we aren't integrating into possible shear spike at 16 Hz
    k_end = min(k_end, 15/Wspd);

    % Reduce k_end if phi_in doesn't reach that far
    [~, k_max_idx] = find(phi_in == 0, 1, 'first');
    if k_end > k(k_max_idx) & k_max_idx > 1
        k_end = k(k_max_idx - 1);
    end
end

end
