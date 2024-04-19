function avg = epsilon_from_thermistors_fcs(...
    Vpsi, Vavg, avg, head, fbounds)
% function avg = epsilon_from_thermistors_fcs(...
%     Vpsi, Vavg, avg, head, fbounds)
%   Calculate dissipation using the chipod method (thermistors only)
%
% Inputs
% ------
% See ../reduced/derive_epsilon_and_chi_reduced.m
%
% Outputs
% -------
% avg: same as input with additional fields
%      eps1_chi, eps2_chi
%
% Notes
% -----
% Assumes stratification is only temperature dependent
%
% References
% ----------
% Moum and Nash (2009) JTech, doi:10.1175/2008JTECHO617.1
%
% Ken Hughes, June 2023

% "Constants"
Gamma = 0.2;
g = 9.81;
dTdz_min = 0.004;
num_iterations = 7;  % 5 iterations should be overkill

% Stratification
dTdz = -gradient(avg.T)./gradient(avg.P);
S0 = 34.7;
N2 = g*sw_alpha(avg.T, S0*ones(size(avg.P)), avg.P).*dTdz;
N2(dTdz < dTdz_min) = NaN;

% Iterate to get epsilon from chi following
% Sections 2a and 2b of Moum and Nash (2009)
[eps1_chi, eps2_chi] = deal(1e-8*ones(size(avg.P)));  % First guesses
avg_dim = 2;
for dummy = 1:num_iterations
    eps1_chi_prev = eps1_chi;
    eps2_chi_prev = eps2_chi;

    for ii = 1:2
        fl = fbounds(2*ii-1);
        fh = fbounds(2*ii);

        chi_init1(:, ii) = calc_chi_init(...
            Vpsi.psi_T1P_fit(:, ii), Vavg.T1, eps1_chi, avg.nu, head.coef.T1, head.coef.T1P);
        chi_init2(:, ii) = calc_chi_init(...
            Vpsi.psi_T2P_fit(:, ii), Vavg.T2, eps1_chi, avg.nu, head.coef.T2, head.coef.T2P);
        F_Kr1(:, ii) = calc_F_Kr(...
            avg.chi_init1(:, ii), eps1_chi, avg.Wspd, avg.nu, avg.DT, fl, fh);
        F_Kr2(:, ii) = calc_F_Kr(...
            avg.chi_init2(:, ii), eps1_chi, avg.Wspd, avg.nu, avg.DT, fl, fh);
        chi1(:, ii) = correct_chi_init(chi_init1(:, ii), F_Kr1(:, ii));
        chi2(:, ii) = correct_chi_init(chi_init2(:, ii), F_Kr2(:, ii));

    end
    chi1 = nanmean(chi1, avg_dim);
    chi2 = nanmean(chi2, avg_dim);

    % Update epsilon per equation 6 of Moum and Nash
    eps1_chi = N2.*chi1./(2*Gamma*dTdz.^2);
    eps2_chi = N2.*chi2./(2*Gamma*dTdz.^2);

    % calc_F_Kr will throw error if epsilon gets unphysically small
    eps_min = 1e-16;
    eps1_chi(eps1_chi < eps_min) = NaN;
    eps2_chi(eps2_chi < eps_min) = NaN;
end

% Everything should converge when using appropriate inputs,
% but just in case...
no_converge1 = ~between(eps1_chi./eps1_chi_prev, [0.99, 1.01]);
no_converge2 = ~between(eps2_chi./eps2_chi_prev, [0.99, 1.01]);
eps1_chi(no_converge1) = NaN;
eps2_chi(no_converge2) = NaN;
chi1(no_converge1) = NaN;
chi2(no_converge2) = NaN;

% Finally, save output back to avg
avg.eps1_chi = eps1_chi;
avg.eps2_chi = eps2_chi;
avg.dTdz = dTdz;
avg.N2 = N2;


function idx = between(x, bounds);
    idx = x >= bounds(1) & x <= bounds(2);
end

% Functions below are copies from
% ../reduced/derive_epsilon_and_chi_reduced.m

function chi_init = calc_chi_init(...
    psi_TP_fit, VT_avg, epsilon, nu, cT, cTP)
    q = 5.26;
    prefactor = 1./(4*pi^2*q.*sqrt(nu./epsilon));
    bracket_arg = (cT(2) + 2*cT(3)*VT_avg)/cTP(1);
    chi_init = prefactor.*bracket_arg.^2.*psi_TP_fit;
end

function chi = correct_chi_init(chi_init, F_Kr)
    chi = chi_init./F_Kr;
end

end
