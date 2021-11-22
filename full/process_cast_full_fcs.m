function [avg, cal, blk, phi, head, data] = process_cast_full_fcs(header_dir, unit_number, data_filename)
% function process_cast_full_fcs(header_dir, unit_number, data_filename)
%   Process a single FCS cast with a standard method adapted from Chameleon processing
%
%   Inputs
%   ------
%   header_dir: string pointing to directory (with trailing /) containing header file
%   unit_number: for FCS19, this is either '4002' or '4003' (including quotation marks)
%   data_filename: absolute path to raw data file. See notes
%
%   Output structs
%   --------------
%   avg: averaged and derived quantities
%   cal: calibrated data
%   blk: calibrated data reshaped into evenly sized segments (i.e., blocks)
%   phi: spectra derived from blk
%   head: header after experiment-specific modifications
%   data: raw voltage data
%
%   Ken Hughes, July 2021

    head = load_and_modify_header_fcs(header_dir, unit_number, data_filename);
    data = raw_load_solo(data_filename);
    cal = calibrate_voltages_fcs(data, head);
    cal = deglitch_shear_fcs(cal, head);
    blk = reshape_to_Nfft_blocks_fcs(cal, head.Nfft, head, 'calibrated');
    avg = average_over_blocks_fcs(blk);
    [avg, blk] = remove_nonprofiling_data_fcs(avg, blk, head, 'calibrated');
    phi = calc_spectra_fcs(blk, head);
    phi = remove_data_when_pump_on_fcs(phi, blk, head);
    [avg, phi] = calc_epsilon_full_fcs(phi, avg);
    [avg, phi] = calc_chi_full_fcs(phi, avg);
    [cal, blk, avg, phi] = add_readmes_full_fcs(cal, blk, avg, phi, head);

end
