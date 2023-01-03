function F_Na = calc_F_Na(eps_init, Wspd, nu, fl, fh)
% function F_Na = calc_F_Na(eps_init, Wspd, nu, fl, fh)
%   Calculate the "Nasmyth correction factor"
%
%   Inputs
%   ------
%   eps_init: initial underestimate of epsilon (W/kg) from f^1/3 fit
%   Wspd: profiling speed (m/s) derived from dP/dt
%   nu: viscosity (m^2/s)
%   fl, fh: low and high frequencies for f^1/3 fit
%
%   Notes
%   -----
%   eps_init, Wspd, and nu must all be the same size
%
%   Output
%   ------
%   F_Na: Nasmyth correction factor (value between 0 and 1)
%
%   Ken Hughes, July 2021

    correct_size = isequal(size(eps_init), size(Wspd), size(nu));
    assert(correct_size, 'first three inputs to calc_F_Na must be same size')

    N = numel(eps_init);
    F_Na = nan(size(eps_init));
    for ii = 1:N
        F_Na(ii) = calc_F_Na_single(eps_init(ii), Wspd(ii), nu(ii), fl, fh);
    end


function F_Na_i = calc_F_Na_single(eps_init, Wspd, nu, fl, fh)

    if Wspd < 0.02
        % Sometimes negative or low Wspd values slip through other processing and throw errors here
        F_Na_i = NaN;
        return
    end

    [kl, kh] = deal(fl/Wspd, fh/Wspd);
    k = linspace(kl, kh); % Must be linspace in order for mean to be equivalent to integral
    f = Wspd*k;

    if isfinite(eps_init) & eps_init > 0
        F_Na_i = fzero(@F_Na_implicit_eqn, [1e-5, 1]);
    else
        F_Na_i = NaN;
    end

    function out = F_Na_implicit_eqn(F_Na)
        H2 = complete_shear_transfer_function_fcs(f, Wspd);
        H2(isnan(H2)) = min(H2);
        numer = H2.*nasmyth_kgh(k, eps_init/F_Na^(3/2), 'nu', nu);
        denom = (8.05*k.^(1/3)*eps_init^(2/3)/F_Na);
        out = mean(numer./denom) - F_Na;
    end
end

end

