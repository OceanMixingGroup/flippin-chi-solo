function spec = nasmyth_fcs(k, epsilon, varargin)
% function spec = nasmyth_fcs(k, epsilon)
%   Dimensional Nasmyth spectrum in units of s^-2/cpm
%
%   Inputs
%   ------
%   k: vector of wavenumbers in cpm (cycles per meter)
%   epsilon: Turbulent dissipation rate in W/kg (aka m^2/s^3)
%
%   Optional name-value pairs
%   -------------------------
%   'nu': defaults to 1.0E-6
%
%   Output
%   ------
%   spec: value of Nasmyth spectrum in s^-2/cpm at given k
%
%   References
%   ----------
%   RSI Technical Note 028 by Rolf Lueck
%   Bluteau et al. (2016) JTECH doi: 10.1175/JTECH-D-15-0218.1
%
%   Ken Hughes, July 2021

    p = inputParser;
    addParameter(p, 'nu', 1.0e-6);
    parse(p, varargin{:});
    r = p.Results;
    nu = r.nu;

    eta = (nu^3/epsilon).^(1/4);
    numer = 8.05*(k*eta).^(1/3);
    denom = 1 + (20.6*k*eta).^3.715;
    spec = eta*(epsilon/nu).*numer./denom;
end
