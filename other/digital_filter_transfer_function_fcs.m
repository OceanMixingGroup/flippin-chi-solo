function H2f = digital_filter_transfer_function_fcs(f)
% function digital_filter_transfer_function_fcs(f, samplingFrequency)
%   Transfer function for the digital filter that is applied to 400 Hz data
%
%   Inputs
%   ------
%   f: frequencies in Hz
%
%   Output
%   ------
%   H2f: value of transfer function at input f
%
%   Ken Hughes July 2021

    % FCS digitizes data at 400Hz before it is subsampled to 100 Hz
    samplingFrequency = 400;

    % Values quoted from Josh Logan's powerpoint in ganges/work/Josh/Work/
    g_i = (1/(2^16-1))*[...
        0, 52, 221, 393, 427, 174, 0, 0, 0, 0, 0, 1970, 5054, 8202, 10558, 11433, ...
        10558, 8202, 5054, 1970, 0, 0, 0, 0, 0, 174, 427, 393, 221, 52, 0];

    N = 2^10;  % Arbitrary large number
    fft_gi = fft(g_i, N); % zero-padded FFT
    H2f = fft_gi.*conj(fft_gi);
    % Associated frequency vector for the specified N
    f_N = (samplingFrequency/N)*(0:N-1);

    H2f = interp1(f_N, H2f, f);
end
