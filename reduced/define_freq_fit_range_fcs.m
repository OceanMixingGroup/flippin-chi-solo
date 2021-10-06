function [f, fidx, fl, fh] = define_freq_fit_range_fcs(fs, Nfft)
% function define_freq_fit_range_fcs()
%   Define the low and high limits over which to do fits to shear and TP spectra
%
%   Input
%   -----
%   fs: sampling frequency
%   Nfft: number of points that will be used in FFT
%
%   Outputs
%   -------
%   f: 1 x Nf vector of frequencies associated with a spectra using Nfft
%   fidx: 1 x Nf boolean vector that is 1 for fl < f < fh and 0 elsewhere
%   and where Nf = Nfft/1 + 1 (i.e., 257 if Nfft = 512)
%   fl, fh: specified low (l) and high (h) limits to frequency
%
%   Ken Hughes, July 2021

    [fl, fh] = deal(1, 4);

    Nf = Nfft/2 + 1;

    % The frequency vector associated with Nfft
    f = linspace(0, fs/2, Nf);

    fidx = f >= fl & f <= fh;
end
