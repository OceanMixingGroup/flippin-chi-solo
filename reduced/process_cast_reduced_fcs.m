function [avg, Vblk] = process_cast_reduced_fcs(header_dir, unit_number, data_filename)
% function process_cast_reduced_fcs(header_dir, unit_number, data_filename)
%   Process a single FCS cast with the data reduction method
%
%   Inputs
%   ------
%   header_dir: string pointing to directory (with trailing /) containing header file
%   unit_number: for FCS19, this is either '4002' or '4003'
%   data_filename: absolute path to raw data file. See notes
%
%   Output structs
%   --------------
%   avg: averaged and derived quantities
%   Vblk: raw data reshaped into blocks
%
%   Ken Hughes, July 2021

    head = load_and_modify_header_fcs(header_dir, unit_number, data_filename);
    [Nfft, fs] = deal(head.Nfft, head.primary_sample_rate);
    % ----------------------------------------------------------
    % Equivalent of on-board processing
    [head.c2P, head.c2Ap] = hard_code_approx_coefs_fcs();
    [~, isUP] = parse_filename_fcs(data_filename);
    [f, fidx, fl, fh] = define_freq_fit_range_fcs(fs, Nfft);
    data = raw_load_solo(data_filename);
    Vblk = reshape_to_Nfft_blocks_fcs(data, Nfft, head, 'voltages');
    Vavg = mean_of_T_P_voltages(Vblk, head);
    [Vavg, Vblk] = remove_nonprofiling_data_fcs(Vavg, Vblk, head, 'voltages');
    Vblk = despike_shear_blocks_fcs(Vblk);
    Vpsi = fit_spectra_to_power_laws_fcs(Vblk, f, fidx, fs, Nfft);
    if ~isUP
        [Vpsi_Az, f_Az] = calculate_Psi_Az_fcs(data, fs, head);
    end

    % ----------------------------------------------------------
    % Off-board processing
    avg = calibrate_averaged_voltages_fcs(Vavg, head);
    avg = derive_epsilon_and_chi_reduced(Vpsi, Vavg, avg, head, fl, fh);
    avg.time = mean(Vblk.time, 2);

    if ~isUP & all(isfinite(Vpsi_Az))
        avg.SSH = convert_wave_acceleration_to_SSH_spectrum(Vpsi_Az, f_Az, head);
    end

    avg = add_readmes_reduced_fcs(avg, Vblk, head);

end
