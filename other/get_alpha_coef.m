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
    rho = 1024; % Unit is kg/m^3
    Gs = 1.0;
    Ts = cS(1); % Unit is seconds
    Ss = cS(4)/1e3;  % **
    alpha_inv = 2*sqrt(2)*rho*Gs*Ts*Ss;
    alpha_coef = 1/alpha_inv;

    % ** Header files for OSU shear calibration coefficients use
    % centimeter-gram-second (cgs) units, so the shear calibration coefficient
    % is in V/(dyne/cm^2). However, it is recorded in the header file as ~0.25
    % rather than 0.25x10^-4. The 10^-4 factor is in the Chameleon processing code.
    %
    % Here we are using meter-kilogram-second (mks) units, so we divide the
    % header value by 10^-3 to get a coefficient in V m^2/N.
end
