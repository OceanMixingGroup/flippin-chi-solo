function H2f = analog_butterworth_transfer_function_fcs(f, varargin)
% function H2f = analog_butterworth_correction_fcs(f, fc)
%   Transfer function for 2-pole analog Butterworth filter with default cutoff fc = 40Hz
%
%   Inputs
%   ------
%   f: frequencies in Hz
%   fc: cutoff frequency. Defaults to 40Hz
%
%   Output
%   ------
%   H2f: value of transfer function at input f
%
%   Ken Hughes, July 2021

    if nargin < 2
        fc = 40;
    else
        fc = varargin{1};
    end
    npoles = 2;
    H2f = 1./(1 + (f/fc).^(2*npoles));

end
