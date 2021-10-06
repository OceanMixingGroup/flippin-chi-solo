function Vpsi = fit_spectra_to_power_laws_fcs(blk, f, fidx, fs, Nfft)
% function Vpsi = fit_spectra_to_power_laws_fcs(blk, fidx, fs, Nfft)
%   For each 512-element spectra, calculate fit of
%       1. shear voltage spectra to f^1/3
%       2. TP voltage spectra to f^1
%
%   Inputs
%   ------
%   blk: reshaped array of voltages (output of truncate_and_reshape_fcs)
%   f: frequency vector output by define_freq_fit_range_fcs
%   fidx: logical vector = 1 if fl < f < fh output by define_freq_fit_range_fcs
%   fs: sampling frequency
%   Nfft: number of points used in FFT
%
%   Output
%   ------
%   Vpsi: struct containing Nz power-law fit of voltage spectra for S1, S1, T1P, and T2P
%
%   Ken Hughes, July 2021

    Nz = size(blk.S1, 1);

    [Vpsi.psi_S1_fit, Vpsi.psi_S2_fit] = deal(nan(Nz, 1));
    [Vpsi.psi_T1P_fit, Vpsi.psi_T2P_fit] = deal(nan(Nz, 1));

    for zi = 1:Nz
        psi_S1 = voltage_psd(blk.S1(zi, :));
        psi_S2 = voltage_psd(blk.S2(zi, :));
        psi_T1P = voltage_psd(blk.T1P(zi, :));
        psi_T2P = voltage_psd(blk.T2P(zi, :));

        Vpsi.psi_S1_fit(zi) = sum(psi_S1(fidx).*f(fidx).^(1/3))/sum(f(fidx).^(2/3));
        Vpsi.psi_S2_fit(zi) = sum(psi_S2(fidx).*f(fidx).^(1/3))/sum(f(fidx).^(2/3));

        Vpsi.psi_T1P_fit(zi) = sum(psi_T1P(fidx).*f(fidx))/sum(f(fidx).^2);
        Vpsi.psi_T2P_fit(zi) = sum(psi_T2P(fidx).*f(fidx))/sum(f(fidx).^2);
    end

function Psi = voltage_psd(V)
    V = detrend(V);
    Psi = pwelch(V, Nfft, 0, Nfft, fs);
    % pwelch outputs row vector, but we want column vector
    Psi = Psi';
end

end
