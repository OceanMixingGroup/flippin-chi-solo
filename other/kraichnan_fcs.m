function spec = kraichnan_fcs(k, epsilon, chi, varargin)
% function spec = kraichnan_fcs(k, epsilon, chi, varargin)
%   Dimensional Kraichnan spectrum in units of (K/m)^2/cpm
%
%   Inputs
%   ------
%   k: vector of wavenumbers in cpm (cycles per meter)
%   epsilon: Turbulent dissipation rate in W/kg (aka m^2/s^3)
%   chi: Temperature variance dissipation rate in K^2/m
%
%   Optional name-value pairs
%   -------------------------
%   'nu': viscosity in m^2/s. Defaults to 1E-6
%   'DT': thermal diffusivity in m^2/s. Defaults to 1.4E-7
%   'q': Kraichnan constant. Defaults to 5.26
%
%   Output
%   ------
%   spec: value of Kraichnan spectrum in (K/m)^2/cpm at given k
%
%   Notes
%   -----
%   Peterson and Fer (2014) give spectrum with k in rad/m. This is converted to
%   cpm as krad = 2pi k
%
%   Reference
%   ---------
%   Peterson and Fer (2014) Methods Oceanogr. doi:10.1016/j.mio.2014.05.002
%
%   Ken Hughes, July 2021

    p = inputParser;
    addParameter(p, 'nu', 1E-6);
    addParameter(p, 'DT', 1.4E-7);
    addParameter(p, 'q', 5.26);
    parse(p, varargin{:});
    r = p.Results;
    nu = r.nu;
    DT = r.DT;
    q = r.q;

    kb = (epsilon/(nu*DT^2))^(1/4);

    krad = k*2*pi;

    nd_spec = (krad*kb*q).*exp(-(6*q).^0.5.*krad/kb);
    spec = 2*pi*nd_spec.*chi*sqrt(nu/epsilon)/kb;
end
