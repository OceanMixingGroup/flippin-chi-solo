unit = '4003'
% Where outputs from parse_fcs_sat_file.m went
binary_out_directory = ['/home/hugke729/tmp_fcs/' unit '/'];
% Where header_FCS001.mat and header_FCS002.mat are
header_dir = '/home/hugke729/osu/data/fcs/header/';

% Find every profile
files = [dir([binary_out_directory 'UP_COMP_*' unit]);
         dir([binary_out_directory 'DN_COMP_*' unit])];
Nfiles = size(files);

% Load locations
loc_file = [binary_out_directory 'location_' unit '.mat'];
locs = load(loc_file, 'lon', 'lat', 't_lonlat');

avg = cell(Nfiles);

% parfor from the Parallel processing toolbox can speed this up a lot
% but regular for also works
parfor ii = 1:length(files)
% for ii = 1:length(files)

    fname = [files(ii).folder '/' files(ii).name];
    t = datenum(fname(end-18:end-5), 'yyyymmddHHMMSS');

    if files(ii).bytes < 100 | files(ii).bytes > 10000
        % File is too small or too big, so it's probably a bad file
        continue
    elseif strcmp(unit, '4003') & (t > datenum(2023, 6, 23) & t < datenum(2023, 7, 5))
        % No thermistors or shear probes were functioning
        continue
    end

    % The main processing part
    % github.com/OceanMixingGroup/flippin-chi-solo/tree/main/comp
    disp(['Processing ' fname '  File number: ' num2str(ii)])
    avg{ii} = process_cast_comp_fcs(header_dir, unit, fname);

    avg{ii}.lat = interp1(locs.t_lonlat, locs.lat, t);
    avg{ii}.lon = interp1(locs.t_lonlat, locs.lon, t);
end

missing = cellfun(@isempty, avg);
avg = {avg{~missing}};

% Save individual profiles as dives
readme = 'Created with /home/hugke729/osu/data/arcterx/scripts/convert_comp_to_mat.m'
save([binary_out_directory unit '_chi.mat'], 'avg', 'readme')

