function H2f = thermal_response_transfer_function_fcs(f)
% function H2f = thermal_response_transfer_function_fcs(f)
%   Transfer function describing Tprime variance lost at high frequencies by
%   diffusion of heat through the thermistor bead's coating
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
%   Nash et al. (1999) J. Atmos. Oceanic Tech.
%   doi:10.1175/1520-0426(1999)016<1474:ATPFHS>2.0.CO;2
%
%   Ken Hughes, Dec 2022

%   Figure A2 of Nash et al. shows measured transfer functions for profiling speed of 0.3 m/s
%   For a double-pole filter response, two different thermistors have optimal
%   cut-off frequencies of fc = 25.1 and 36.7 Hz
%   Use approximate mean of these two values
%   The use of one significant (30, not 30.9) recognizes the uncertainty in fc

    fc = 30;
    H2f = 1./((1 + (f/fc).^2)).^2;

end
