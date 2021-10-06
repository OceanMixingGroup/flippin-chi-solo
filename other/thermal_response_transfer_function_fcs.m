function H2f = thermal_response_transfer_function_fcs(f)
% function H2f = thermal_response_transfer_function_fcs(f)
%   Transfer function describing Tprime variance lost at high frequencies to
%
%   Inputs
%   ------
%   f: frequency in Hz
%
%   Output
%   ------
%   H2f: value of transfer function at input f (NaN if H2f < 0.05)
%
%   References
%   ----------
%   Sommer et al. (2013) J. Atmos. Oceanic Tech.
%   doi: 10.1175/JTECH-D-12-00272.1
%
%   Eqs 2, 3 of Lien et al. (2016) Methods Oceanogr.
%   doi: 10.1016/j.mio.2016.09.003
%   Ken Hughes, July 2021


    % Below is the more general form. Since s = 0, it simplifies to tau = 0.01
    % assert(length(W) == 1, 'W is not a single value')
    % [s, tau0, U0] = deal(0, 0.01, 1); % Sommer et al. choice quoted in Lien et al.
    % tau = tau0*(W/U0).^s;

    tau = 0.01;

    H2f = 1./((1 + (2*pi*f*tau).^2).^2);
    % Don't trust more than factor of 20 correction (somewhat arbitrary)
    H2f(H2f < 1/20) = NaN;
end
