function [f, fbounds] = define_freq_fit_ranges_fcs(fs, Nfft)
% function [f, fbounds] =  define_freq_fit_ranges_fcs(fs, Nfft)
%   Define the low and high limits over which to do the two fits for each shear and TP spectra
%   The high bound for the first range is the same as the low bound for the second range
%
%   Input
%   -----
%   fs: sampling frequency
%   Nfft: number of points that will be used in FFT
%
%   Outputs
%   -------
%   f: 1 x Nf vector of frequencies associated with a spectra using Nfft
%   fbounds: four-element vector with the two low and two high frequency bounds
%            [f_low_1, f_high_1, f_low_2, f_high_2]
%
%   Ken Hughes, July 2021

    Nf = Nfft/2 + 1;

    % The frequency vector associated with Nfft
    f = linspace(0, fs/2, Nf);

    % fbounds should be approximately [1, 3, 3, 5] in Hz;
    % but should also have values that are half-integer mutliples of diff(fs)
    approx_bounds = [1, 3, 3, 5];
    for ii = 1:4
        idx = find(f < approx_bounds(ii), 1, 'last');
        fbounds(ii) = mean(f(idx:idx+1));
    end
end
