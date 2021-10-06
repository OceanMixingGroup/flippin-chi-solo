function cal = deglitch_shear_fcs(cal, head)
% function cal = deglitch_shear_fcs(cal)
%   Remove spikes from shear probe signals
%
%   Input
%   -----
%   cal: Output of calibrate_voltages_fcs
%   head: output of load_and_modify_header
%
%   Output
%   ------
%   cal: Same as input with the shear signals overwritten with despiked signal
%
%   Notes
%   -----
%
%   Ken Hughes, July 2021

    cal.S1 = despike_rockland(cal.S1);
    cal.S2 = despike_rockland(cal.S2);

function shear_voltage = despike_rockland(shear_voltage)
    % Despike shear signal following the approach used by Rockland Scientific
    % See Sec. 11.3 of Lueck et al. (2018) Technical Note 039: A guide to data processing
    %
    % Step 1) Calculate the absolute value of the high-passed (0.5Hz) signal
    % Step 2) Get local pseudo std. dev. by low-passing output of step 1
    % Step 3) Spikes are defined where output of step 1 is 8 times larger than that of step 2
    % Step 4) Replace spikes (and surrounding 5 points) with mean of nearest 50 point
    % Step 5) Take the despiked signal and repeat two more times

    fs = head.primary_sample_rate;
    threshold = 8; % Multiples of smoothed, rectified signal that is considered a spike
    f_smooth = 0.5; % Frequency for smoothing rectified signal
    N = 4; % Number of points after the spike that are adjusted

    for ii = 1:3
        shear_voltage = single_despike(shear_voltage);
    end

    % Ensure no NaNs left
    shear_voltage(isnan(shear_voltage)) = nanmean(shear_voltage);


    function shear_voltage = single_despike(shear_voltage)
        filt_ord = 1;
        [bl, al] = butter(filt_ord, f_smooth/(fs/2), 'low');
        [bh, ah] = butter(filt_ord, f_smooth/(fs/2), 'high');

        rectified_highpassed_voltage = abs(filtfilt(bh, ah, shear_voltage));
        local_pseudo_std = filtfilt(bl, al, rectified_highpassed_voltage);

        spikes = find(rectified_highpassed_voltage > threshold*local_pseudo_std);

        shear_voltage(spikes) = NaN;

        % Half-length of region to use to find replacement values
        % Somewhat arbitrary choice
        Nreplace_with = round(fs/4);

        for spike = spikes
            replace_idx = max(spike - round(0.5*N), 1):min(spike + N, length(shear_voltage));
            replace_with_idx = max(spike - Nreplace_with, 1):min(spike + Nreplace_with, length(shear_voltage));
            shear_voltage(replace_idx) = nanmean(shear_voltage(replace_with_idx));
        end
    end

end

end
