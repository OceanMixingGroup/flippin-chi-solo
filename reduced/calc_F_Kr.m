function F_Kr = calc_F_Kr(chi_init, epsilon, Wspd, nu, DT, fl, fh)
% function F_Kr = calc_F_Kr(eps_init, Wspd, nu, fl, fh)
%   Calculate the "Kraichnan correction factor"
%
%   Inputs
%   ------
%   chi_init: initial underestimate of chi (W/kg) from f^1 fit
%   epsilon: corrected value of epsilon (i.e., eps_init/F_Na^(3/2))
%   Wspd: profiling speed (m/s) derived from dP/dt
%   nu: viscosity (m^2/s)
%   DT: thermal diffusivity (m^2/s)
%   fl, fh: low and high frequencies for k^1/3 fit
%
%   Notes
%   -----
%   chi_init, epsilon, Wspd, nu, and DT must all be the same size
%
%   Output
%   ------
%   F_Kr: Nasmyth correction factor (value between 0 and 1)
%
%   Ken Hughes, July 2021

    correct_size = isequal(size(chi_init), size(epsilon), size(Wspd), size(nu), size(DT));
    assert(correct_size, 'first five inputs to calc_F_Kr must be same size')

    N = numel(chi_init);
    F_Kr = nan(size(chi_init));
    for ii = 1:N
        F_Kr(ii) = calc_F_Kr_single(...
            chi_init(ii), epsilon(ii), Wspd(ii), nu(ii), DT(ii), fl, fh);
    end


function F_Kr_i = calc_F_Kr_single(chi_init, epsilon, Wspd, nu, DT, fl, fh)
    [kl, kh] = deal(fl/Wspd, fh/Wspd);
    k = linspace(kl, kh);  % Must be linspace in order for mean to be equivalent to integral
    f = Wspd*k;

    if isfinite(chi_init)
        F_Kr_i = fzero(@F_Kr_implicit_eqn, [1e-20, 1]);
    else
        F_Kr_i = NaN;
    end

    function out = F_Kr_implicit_eqn(F_Kr)
        q = 5.26;
        H2 = complete_thermistor_transfer_function_fcs(f, Wspd);
        H2(isnan(H2)) = min(H2);
        numer = H2.*kraichnan_fcs(k, epsilon, chi_init/F_Kr, 'nu', nu, 'DT', DT, 'q', q);
        denom = (4*pi^2*k*(chi_init/F_Kr)*sqrt(nu/epsilon)*q);
        out = mean(numer./denom) - F_Kr;
    end
end

end
