function H2k = complete_thermistor_transfer_function_fcs(f, W)
% function H2 = complete_thermistor_transfer_function_fcs(f, W)
%   Calculate H^2(k) that describes
%   1. variance lost at high frequencies by thermal response of thermistor
%   2. variance lost at high frequencies by the analog two-pole Butterworth filter
%   3. variance lost at high frequencies by the digital filtering of raw voltages
%
%   Inputs
%   ------
%   f: frequency vector (Hz)
%   W: profiling speed (single value)
%
%   Output
%   ------
%   H2k: the complete transfer function, which will have values between 0 and 1
%
%   Notes
%   ------
%   Some transfer function are defined in terms of k. Others in terms of f.
%   Because outputs are dimensionless, we can multiply H2(f) and H2(k) as we please
%
%   Ken Hughes, July 2021
    assert(length(W) == 1, 'W is not a single value')
    k = f/W;

    H2k_FT = thermal_response_transfer_function_fcs(f);
    fc_butter = 50;
    H2f_AA = analog_butterworth_transfer_function_fcs(f, fc_butter);
    H2f_D = digital_filter_transfer_function_fcs(f);

    H2k = H2k_FT.*H2f_AA.*H2f_D;
end
