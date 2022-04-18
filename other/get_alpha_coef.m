function alpha_coef = get_alpha_coef(cS)
% function alpha_coef = get_alpha_coef(cS)
%   Combined engineering calibrations that relates shear voltage to shear
%   u_z = (alpha/W^2) V_s
%
%   Input
%   -----
%   cS: 4- or 5-element shear calibration (i.e., head.coef.S1 or head.coef.S2)
%
%   Ken Hughes, July 2021
    Gs = 1.0;
    Ts = cS(1); % Unit is seconds
    Ss = cS(4);  % Unit is V s^2/m^2. Value in header includes density
    alpha_inv = 2*sqrt(2)*Gs*Ts*Ss;
    alpha_coef = 1/alpha_inv;
end
