function parse_fcs_sat_file()

sat_filename = '/home/hugke729/Downloads/4002.sat';
unit = sat_filename(end-7:end-4);  % '4002' or '4003'
binary_out_directory = ['/home/hugke729/tmp_fcs/' unit '/'];  % Where to save outputs

% Manually specify which dives to ignore
if strcmp(unit, '4002')
    ignore_dives = 1:138;
elseif strcmp(unit, '4003')
    ignore_dives = [1:60, 258:372, 1785];
end

% ---------------------------------------------------------

[dive_data, dive_nums, lon, lat, t_lonlat] = read_sat_file(sat_filename);
for ii = 1:length(dive_nums)
    convert_dive_to_binary_file(dive_data{ii});
end
save([binary_out_directory 'location_' unit '.mat'], 'lon', 'lat', 't_lonlat');

function [dive_data, dive_nums, lon, lat, t_lonlat] = read_sat_file(sat_filename)
    % Take a sat file and parse it line-by-line.
    % Look for either
    % A packet's metadata line, which starts with HX00
    % A packet's data line, which comes in blocks and starts with +
    % A GPS data line, which starts with G

    % Assume that no dives are more than 4 packets of 1920 bytes.
    % Assume some arbitrarily large number of dives for now
    Nmax_dives = 10000;
    pkts = cell(4, Nmax_dives);
    [lon, lat, t_lonlat] = deal(nan(1, Nmax_dives));

    fid = fopen(sat_filename);
    % Loop through file line by line
    text_line = fgetl(fid);
    while ischar(text_line)
        text_line = fgetl(fid);

        if text_line == -1, continue, end % End of file reached

        if strcmp(text_line(1:4), 'HX00')
            % Example:
            % HX00  140 3840   64    2
            % where dive_num=140 is the dive number and pkt_num=2 is the packet number
            dive_num = str2num(text_line(5:9));
            pkt_num = str2num(text_line(end-1));
            pkt = '';

            % The lines after the HX00 line are the turbulence data
            % Keep adding together lines starting with '+'
            % until we reach a line that doesn't
            next_line = fgetl(fid);
            while strcmp(next_line(1), '+')
                pkt = [pkt next_line(2:end)];
                next_line = fgetl(fid);
            end
            % We will join the pkts later
            % For now, just save it in the appropriate row and column of the pkts array
            pkts{pkt_num, dive_num} = pkt;
        end

        if strcmp(text_line(1:2), 'G ')
            % Example:
            % G  140 1 31 May 2023 09:30 +19 30.10 +141 34.73   20 13 33 39 48  0.7 ...
            % ... 0    19.50159   141.57889
            % where dive_num=140 and the last two numbers are latitude and longitude
            dive_num = str2num(text_line(3:6));
            if dive_num == 0
                continue
            end
            lat(dive_num) = str2num(text_line(75:83));
            lon(dive_num) = str2num(text_line(87:95));
            t_lonlat(dive_num) = datenum(text_line(10:26), 'dd mmm yyyy HH:MM');
        end
    end

    % Join 1, 2, 3, or 4 pkts into a single dive
    dive_data = cell(1, Nmax_dives);
    for dive_num = setdiff(1:Nmax_dives, ignore_dives)
        dive_data{dive_num} = strcat(pkts{:, dive_num});
        dive_data{dive_num} = manually_remove_bad_bits(dive_data, dive_num, unit);
    end

    % Keep only arrays with profiles
    dive_nums = find(~cellfun(@isempty, dive_data));
    dive_data = dive_data(dive_nums);
    lon = lon(dive_nums);
    lat = lat(dive_nums);
    t_lonlat = t_lonlat(dive_nums);

    fclose(fid);
end

function t = read_tstr(eight_char_tstr)
    % After ffffffff or ffff0000ffff0000, the next 8 characters are a time stamp in hex
    % For example, e2539264 would become 1687311330 seconds after 1/1/1970,
    % which is 01:35:30 on 21 Jun 2023
    t = eight_char_tstr;
    % Change endianness and convert to posixtime (number of seconds since 00:00:00 1/1/1970)
    t = int32(hex2dec([t(7:8) t(5:6) t(3:4) t(1:2)]));
    % Subtracting 1 second makes most filenames match SD card filenames
    t = t - 1;
end

function filename = t_to_filename(t, prefix)
    % The filenames are written on the SD card as, say,
    % XX_COMP_yyyymmddHHMMSS.unit where XX is UP, DN, or SURF
    % This function will recreate that filename based on the timestamp from read_tstr
    t = datetime(t, 'ConvertFrom', 'posixtime');
    fmt = repmat('%02i', 1, 6);
    t_str = sprintf(fmt, t.Year, t.Month, t.Day, t.Hour, t.Minute, t.Second);
    filename = [binary_out_directory prefix t_str '.' unit];
end

function hex2binfile(fname_out, hex_str)
    hex_str = reshape(hex_str, 4, [])';
    endianness = 'b';
    fid = fopen(fname_out, 'w');
    fwrite(fid, hex2dec(hex_str), 'uint16', endianness);
    fclose(fid);
end

function rounded = round_index(idx)
    % From the output of strfind(pkt_string, 'ffffffff')
    % Find the index of the last character before ffffffff
    % But also ensure output is a multiple of 8
    % This is harder than it sounds
    % For example, the output index for all of the cases below should be 8
    % 12345678ffffffff12345678
    % 1234567fffffffff12345678
    % 123456ffffffffff12345678
    % 12345fffffffffff12345678
    % 12345678fffffffff2345678
    % 12345678ffffffffff345678
    % 12345678fffffffffff45678
    % 1234567ffffffffff2345678
    % 123456ffffffffffff345678
    % 12345ffffffffffffff45678
    if any(diff(idx) == 1)
        nsplit = find(diff(idx) > 1);
        if isempty(nsplit)
            idx = mean(idx);
        elseif length(nsplit) == 1
            idx = [mean(idx(1:nsplit)), mean(idx(nsplit+1:end))];
        else
            disp('Did not expect to reach this point')
        end
    end
    rounded = 8*round(idx/8);
end

function convert_dive_to_binary_file(dive_pkt)
    % The full dive packet will have one of three formats
    % 1. SURF, DN, UP
    % ffff0000ffff0000 ... ffffffff ... ffffffff ...
    % 2. DN, UP
    % ffffffff ... ffffffff ...
    % 3. UP
    % ffffffff ...

    f8 = 'ffffffff';
    surf_key = 'ffff0000ffff0000';
    len_surf = 280;

    if strcmp(dive_pkt(1:16), surf_key)
        % Full file with SURF, DN, UP

        t_surf = read_tstr(dive_pkt(17:24));
        t_surf = t_surf - 260;  % Match SD card filename
        fname_surf = t_to_filename(t_surf, 'SURF_COMP_');
        hex2binfile(fname_surf, dive_pkt(1:len_surf));

        % Surface data has been written, so get rid of it
        dive_pkt = dive_pkt(len_surf+1:end);

        % Find where the DN data ends by finding the second ffffffff
        % And then write that to a DN bin file
        dn_end_idx = round_index(strfind(dive_pkt(9:end), f8)) + 8;
        t_dn = read_tstr(dive_pkt(9:16));
        fname_dn = t_to_filename(t_dn, 'DN_COMP_');
        hex2binfile(fname_dn, dive_pkt(1:dn_end_idx));

        % Down data has been written, so get rid of it
        dive_pkt = dive_pkt(dn_end_idx+1:end);

        % Everything else is UP
        t_up = read_tstr(dive_pkt(9:16));
        fname_up = t_to_filename(t_up, 'UP_COMP_');
        hex2binfile(fname_up, dive_pkt);

    elseif strcmp(dive_pkt(1:8), f8)
        % Either DN then UP, or just UP

        % If it's DN then UP, then will be able to find another ffffffff
        % after the first one
        dn_end_idx = round_index(strfind(dive_pkt(9:end), f8)) + 8;

        if ~isempty(dn_end_idx)
            % DN then UP profile
            t_dn = read_tstr(dive_pkt(9:16));
            fname_dn = t_to_filename(t_dn, 'DN_COMP_');
            hex2binfile(fname_dn, dive_pkt(1:dn_end_idx));

            % Down data has been written, so get rid of it
            dive_pkt = dive_pkt(dn_end_idx+1:end);
        end

        % Everything else is UP
        t_up = read_tstr(dive_pkt(9:16));
        fname_up = t_to_filename(t_up, 'UP_COMP_');
        hex2binfile(fname_up, dive_pkt);

    else
        disp(['Should not reach this point. Dive ' num2str(dive_num)])

    end

    if exist(replace(fname_up, 'UP', 'DN'))
        % Not sure how this happens, but it can occur for last dive
        disp(['Attempting to remove duplicate(?) file for dive ' num2str(dive_num)])
        rm_fname = replace(fname_up, 'UP', 'DN');
        try
            system(['rm ' rm_fname]);
        end
    end

end


function pkt = manually_remove_bad_bits(dive_data, dive_num, unit)
    % There's only a few bad bits, so it's simpler to specify and remove these manually

    % For each dive with bad data, the strings below signify
    %    (1) start of the bad data section, which always starts with ffffffff
    %    (2) start of the good data section, which must be at the start of a new line
    % We keep the whole line with the ffffffff
    % And then remove everything until the start of the good bit

    % Looking at the original sat files for Arcterx23 should make it clear
    % what to add here

    if strcmp(unit, '4002')
        bad_lines = {
            151, 'ffffffff94677764461c', '3200c9cfcacd6762';
            158, 'ffffffff7f9c77644e1c', '3601c4b0c4b3675f';
            177, 'ffffffff182c7864441c', '3201b8bcbfb76a64';
            247, 'ffffffffdc3a7a64351c', '3407c1c3ccbe736d';
            260, 'ffffffff659d7a64311c', '3403cac2c3ba6c68';
            274, 'ffffffff75067b64331c', '3602c1c7c0bb6a66';
            279, 'ffffffffe52a7b64311c', '3401c7b5c9c0625b';
            541, 'ffffffff06207e64311c', '3203c4c2c6c1726c';
            584, 'ffffffffa7627f64271c', '3003c2bdc1bf6861'};
    elseif strcmp(unit, '4003')
        bad_lines = {
            159, 'ffffffffe2d579641d1c', '3401d4cea4a36e6f';
            200, 'ffffffffd71c7b64181c', '2e00cec8aea96f71';
            463, 'ffffffffeadc81641b1c', '3007c2bbcad16565';
            543, 'ffffffff1e498464141c', '34038889bfc06a6f';
            571, 'ffffffff2c1b85640c1c', '3003a199b7b07168';
            610, 'ffffffff854286640c1c', '3400b7b1cbc36562';
            631, 'fffffffff4e88664111c', '3603b7b8d8d8615d';
            706, 'fffffffffe3489640f1c', '34018c84bebe7465';
            740, 'ffffffff813c8a640c1c', '30079390e5d46e63';
            764, 'ffffffff21fa8a640a1c', '2e10a0a28a846b6a';
            819, 'ffffffffbbb58c640a1c', '2e05b1b8a99c6e65';
            859, 'ffffffff9cf78d64051c', '3402908c7c756766';
            876, 'ffffffff3c7b8e640a1c', '32059e9e80806764';
            891, 'ffffffffe7f48e64081c', '3601aaa997906e6d';
            925, 'ffffffff6c059064051c', '3200c7bfc4c17d79';
            944, 'ffffffff32a49064051c', '300894978f8d6364';
            946, 'ffffffffb9b39064081c', '3006908e84866968';
            956, 'ffffffffab019164081c', '2e02979097957165';
            981, 'ffffffffe4cd9164fb1b', '3401767a7675706e';
            983, 'ffffffff24de9164001c', '2e0c8b8589816565';
            997, 'ffffffffb34f9264031c', '30018b8a00000000'};
    end

    pkt = dive_data{dive_num};
    if ismember(dive_num, [bad_lines{:, 1}])
        row = find(dive_num == [bad_lines{:, 1}]);
        bad_str_start = strfind(pkt, bad_lines{row, 2});
        good_str_start = strfind(pkt, bad_lines{row, 3});
        % Keep the first line (64 characters), because it has the timestamp
        % Then ignore everything until the good data starts
        pkt = [pkt(bad_str_start:bad_str_start+63) pkt(good_str_start:end)];
    end

end

end
