function avg = derive_epsilon_and_chi_reduced(Vpsi, Vavg, avg, head, fl, fh);
% function avg = derive_epsilon_and_chi_reduced(Vpsi, Vavg, head);
%   Invert power-law fits of spectra to find eps and chi
%
%   Inputs
%   ------
%   Vpsi: power-law fits of voltage spectra calculated on-board
%         or output of fit_spectra_to_power_laws_fcs if simulating on-board processing with Matlab
%   Vavg: voltage means calculated on-board
%         or output of mean_of_T_P_voltages if simulating on-board processing with Matlab
%   avg: struct of calibrated data where each quantity is Nz x 1
%   head: output of load_and_modify_header
%   fl, fh: low and high ends of frequency fitting range
%
%   Output
%   ------
%   avg: same as input with additional fields
%        epsilon, eps1, eps2, eps_init1, eps_init2, F_Na1, F_Na2
%        chi, chi1, chi2, chi_init1, chi_init2, F_Kr1, F_Kr2


    avg.eps_init1 = calc_eps_init(Vpsi.psi_S1_fit, avg.Wspd, head.coef.S1);
    avg.eps_init2 = calc_eps_init(Vpsi.psi_S2_fit, avg.Wspd, head.coef.S2);
    avg.F_Na1 = calc_F_Na(avg.eps_init1, avg.Wspd, avg.nu, fl, fh);
    avg.F_Na2 = calc_F_Na(avg.eps_init2, avg.Wspd, avg.nu, fl, fh);
    avg.eps1 = correct_eps_init(avg.eps_init1, avg.F_Na1);
    avg.eps2 = correct_eps_init(avg.eps_init2, avg.F_Na2);
    avg.epsilon = combine_turbulence_values_fcs(avg.eps1, avg.eps2);

    avg.chi_init1 = calc_chi_init(Vpsi.psi_T1P_fit, Vavg.T1, avg.epsilon, ...
                                  avg.nu, head.coef.T1, head.coef.T1P);
    avg.chi_init2 = calc_chi_init(Vpsi.psi_T2P_fit, Vavg.T2, avg.epsilon, ...
                                  avg.nu, head.coef.T2, head.coef.T2P);
    avg.F_Kr1 = calc_F_Kr(avg.chi_init1, avg.epsilon, avg.Wspd, avg.nu, avg.DT, fl, fh);
    avg.F_Kr2 = calc_F_Kr(avg.chi_init2, avg.epsilon, avg.Wspd, avg.nu, avg.DT, fl, fh);
    avg.chi1 = correct_chi_init(avg.chi_init1, avg.F_Kr1);
    avg.chi2 = correct_chi_init(avg.chi_init2, avg.F_Kr2);
    avg.chi = combine_turbulence_values_fcs(avg.chi1, avg.chi2);


function eps_init = calc_eps_init(psi_s_fit, Wspd, cS)
    alpha_coef = get_alpha_coef(cS);
    eps_two_thirds = alpha_coef^2./(8.05*Wspd.^(8/3)).*psi_s_fit;
    eps_init = eps_two_thirds.^(3/2);
end

function epsilon = correct_eps_init(eps_init, F_Na)
    epsilon = eps_init./F_Na.^(3/2);
end

function chi_init = calc_chi_init(psi_TP_fit, VT_avg, epsilon, nu, cT, cTP)
    q = 5.26;
    prefactor = 1./(4*pi^2*q.*sqrt(nu./epsilon));
    bracket_arg = (cT(2) + 2*cT(3)*VT_avg)/cTP(1);
    chi_init = prefactor.*bracket_arg.^2.*psi_TP_fit;
end

function chi = correct_chi_init(chi_init, F_Kr)
    chi = chi_init./F_Kr;
end


end
