function avg = process_cast_comp_fcs(header_dir, unit_number, data_filename)
% function process_cast_comp_fcs(header_dir, unit_number, data_filename)
%   Process a single FCS cast using the compressed data file
%
%   Inputs
%   ------
%   header_dir: string pointing to directory (with trailing /) containing header file
%   unit_number: for FCS19, this is either '4002' or '4003'
%   data_filename: absolute path to compressed data file
%
%   Output structs
%   --------------
%   avg: averaged and derived quantities
%
%   Ken Hughes, April 2023

    head = load_and_modify_header_fcs(...
        header_dir, unit_number, data_filename);
    [Nseg, Nfft, Noverlap, fs] = deal(...
        head.Nseg, head.Nfft, head.Noverlap, head.primary_sample_rate);
    [f, fbounds] = define_freq_fit_ranges_fcs(fs, Nfft);

    comp = comp_load_solo2(data_filename);
    [Vavg, Vpsi] = rename_comp_structs_fcs(comp);
    Vavg = calc_profiling_speed_comp_fcs(Vavg, head);

    avg = calibrate_averaged_voltages_fcs(Vavg, head);
    avg = derive_epsilon_and_chi_reduced(Vpsi, Vavg, avg, head, fbounds);

    % Added by necessity due to failure of shear probes in
    % Arcterx 2023 field program
    avg = epsilon_from_thermistors_fcs(Vpsi, Vavg, avg, head, fbounds);

    avg.time = comp.time;
end
