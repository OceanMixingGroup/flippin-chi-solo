function SSH = convert_wave_acceleration_to_SSH_spectrum(Vpsi_Az, f_Az, head);
% function avg = convert_wave_acceleration_to_SSH_spectrum(Vpsi_Az, f_Az);
%   Convert Psi_Az(f) to Phi_eta(f)
%
%   Inputs
%   ------
%   Vpsi_Az, f_Az: output of calculate_Psi_AZ_fcs
%
%   Output
%   ------
%   SSH: struct with
%           1. Phi_eta: SSH spectrum (m^2/Hs)
%           2. f: Associated frequency vector (Hz)
%           3. Hs: Significant wave height (m)
%
%   Ken Hughes, November 2019

    fc = 1/23;
    H2_eta = (1 - 1./(1 + (f_Az/fc).^4)).^6;
    Phi_eta = (9.81*head.coef.AZ(2))^2*H2_eta.*Vpsi_Az./(2*pi*f_Az).^4;
    Phi_eta(1) = 0;
    % Apply standard definition of significant wave height
    Hs = 4*sqrt(trapz(f_Az, Phi_eta));

    SSH.Phi_eta = Phi_eta;
    SSH.f = f_Az;
    SSH.Hs = Hs;

end

