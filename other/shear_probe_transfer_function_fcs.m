function H2k = shear_probe_transfer_function_fcs(k)
% function H2k = shear_probe_transfer_function_fcs(k)
%   Transfer function describing shear variance lost at small scales
%
%   Inputs
%   ------
%   k: wavenumber in cpm
%
%   Output
%   ------
%   H2k: value of transfer function at input k (NaN if H2k < 0.05 or k > 170)
%
%   Reference
%   ---------
%   Equation A5 of Moum et al. (1995) J. Atmos. Oceanic Tech.
%   doi: 10.1175/1520-0426(1995)012<0346:COTKED>2.0.CO;2
%
%   Ken Hughes, July 2021

    k0 = 170;
    an = [1.0, -0.164, -4.537, 5.503, -1.804];
    % Start with name used by Moum et al.
    T = zeros(size(k));
    for n = 0:4
        T = T + an(n+1)*(k/k0).^n;
    end
    % Don't trust more than factor of 20 correction (somewhat arbitrary)
    % And note that T is defined for k > k0, but it's nonsensical
    T(T < 0.05 | k > k0) = NaN;

    % Rename output
    H2k = T;

end
