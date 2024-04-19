function avg = process_surface_comp_fcs(header_dir, unit_number, data_filename)
% function process_surface_comp_fcs(header_dir, unit_number, data_filename)
%   Process a single FCS surfacing using the compressed data file

%   Inputs
%   ------
%   header_dir: string pointing to directory (with trailing /)
%               containing header file
%   unit_number: for FCS19, this is either '4002' or '4003'
%   data_filename: absolute path to compressed data file.
%
%   Output structs
%   --------------
%   avg: struct containing substruct SSH
%        (to match output of process_cast_reduced_fcs)
%
%   Ken Hughes, April 2023

    head = load_and_modify_header_fcs(...
        header_dir, unit_number, data_filename);

    f_Az = define_comp_surf_freq_vector();
    [Vpsi_Az, avg.t] = comp_load_surf(data_filename);

    if length(Vpsi_Az) == 63
        % Work-around until I figure out true cause
        Vpsi_Az = [Vpsi_Az; 0];
        disp(['Only 63 points for ' data_filename])
    end

    avg.SSH = convert_wave_acceleration_to_SSH_spectrum(...
        Vpsi_Az, f_Az, head);

end
