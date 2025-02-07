function correct_Jan_1_2019_dates_within_sat_file(sat_filename)
    % Sometimes during the Arcterx 2025 IOP2 cruise, casts were
    % recorded with date strings of ~00:06:20 on Jan 1, 2019 give
    % or take ten seconds.
    %
    % This function directly fixes (overwrites a small amount of)
    % the data within the sat file, so it should be run before the
    % rest of the sat file processing
    %
    % The issue is likely related to the chi clock not getting synced
    % quickly enough after a power cycle.
    %
    % As of writing, the issue only affects unit 4007

    % Method:
    % 1. Search line by line for the affected casts, which look like
    % '+ffffffff????2a5c.......' where ????2a5c is the datestring, part
    % of which is fixed by the date, and part is variable with the
    % slight time variability
    % 2. Find the next line in the file of the form
    % '!dive  102        999 06FEB2025 00:43:50'
    % 3. Use that time (dive end) minus ~40 minutes, to get approx
    % start time
    % 4. Convert newly calculated start time back to a ????2a5c datestring

    all_lines = readlines(sat_filename);
    line_no = 1;
    for line_no = 1:length(all_lines)
        curr_line = char(all_lines(line_no));
        if length(curr_line) < 17
            continue
        end
        if strcmp(curr_line([1:9, 14:17]), '+ffffffff2a5c')
            % !dive ... line should be 60 lines later, but just search
            % over next 100 to be sure
            % new_t = curr_line(10:17);  % Set existing value initially
            for tmp_line_no = line_no:line_no + 100
                tmp_line = char(all_lines(tmp_line_no));
                if strcmp(tmp_line(1:5), '!dive')
                    new_t = tmp_line(23:40);
                    new_t = datevec(new_t, 'ddmmmyyyy HH:MM:SS');
                    % Make conversion to ????2a5c form
                    new_t = posixtime(datetime(new_t)) - 40*60;
                    new_t = lower(dec2hex(new_t));
                    new_t = [new_t(7:8) new_t(5:6) new_t(3:4) new_t(1:2)]
                    break
                end
            end
            % Make replacement for earlier line
            curr_line(1:17) = ['+ffffffff' new_t];
            all_lines(line_no) = string(curr_line);
        end
    end
    % Overwrite sat_filename with now-corrected time strings
    writelines(all_lines, sat_filename)
end
