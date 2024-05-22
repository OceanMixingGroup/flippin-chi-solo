function fcs = arcterx23_create_mat_summary()
    % Start with the cell array of profiles created by
    % /home/hugke729/osu/data/arcterx/scripts/convert_comp_to_mat.m
    % Then process them into 2D arrays

    % base_dir = '/home/hugke729/osu/data/arcterx/'
    base_dir = '/home/hugke729/tmp_fcs/'
    unit = '4002';
    useSD = false;  % If true, then use values calculated from raw files
    z = 3:150;
    [avg, Nfiles] = load_processed_profiles(unit, useSD);
    fcs = grid_all_quantities(z);
    fcs.z = z;
    fcs = manually_remove_bad_vals(fcs, unit);
    fcs = recombine_estimates(fcs);
    fcs = add_readme(fcs);
    % save_summary(fcs);


function [avg, Nfiles] = load_processed_profiles(unit, useSD)
    data_dir = [base_dir unit '/'];
    chi_fname = [data_dir unit '_chi.mat'];
    if useSD
        chi_fname = replace(chi_fname, 'arcterx/' , 'arcterx/SD_card/');
    end
    load(chi_fname, 'avg')  % avg is a cell array
    Nfiles = length(avg);
end

function [out, isUP] = interp_single_quantity(profile_n, quantity, z)
    prof = avg{profile_n};
    P = prof.P;
    isUP = nanmean(diff(P)) < 0;
    idx = P > 3.4;
    idx = idx & abs(prof.Wspd) > 0.05 & abs(prof.Wspd) < 0.5;

    % Remove low-scoring fits from interpolation
    % Note that I'm removing bad data then interpolating
    % as opposed to adding NaNs to the profiles to be interpolating
    if strcmp(quantity, 'eps1')
        idx = idx & prof.eps1_score > 1/3;
    elseif strcmp(quantity, 'eps2')
        idx = idx & prof.eps2_score > 1/3;
    end

    if sum(idx) < 10
        out = nan(size(z));
        return
    end

    out = interp1(P(idx), prof.(quantity)(idx), z);
end

function [Q, isUP] = grid_single_quantity(z, quantity)
    isUP = false(1, Nfiles);
    if ismember(quantity, {'lon', 'lat', 'time'})
        Q = nan(1, Nfiles);
        for profile_n = 1:Nfiles
            Q(profile_n) = avg{profile_n}.(quantity)(1);
        end
    else
        Q = nan(length(z), Nfiles);
        for profile_n = 1:Nfiles
            [Q(:, profile_n), isUP(profile_n)] = interp_single_quantity(profile_n, quantity, z);
        end
    end
end

function fcs = grid_all_quantities(z)
    [~, tidx] = sort(grid_single_quantity(z, 'time'));

    flds = {...
        'time', 'lat', 'lon', ...
        'T', 'T1', 'T2', 'Wspd', ...
        'epsilon', 'eps1', 'eps2', 'eps1_score', 'eps2_score', ...
        'chi', 'chi1', 'chi2', 'eps1_chi', 'eps2_chi', ...
        'N2', 'dTdz'};
        % 'nu', 'DT',

    fcs = struct;
    for fld = flds
        fld = fld{:};
        [tmp, isUP] = grid_single_quantity(z, fld);
        fcs.(fld) = tmp(:, tidx);
        fcs.isUP = isUP(tidx);  % Get's rewritten several times, but that's fine
    end

    fcs.unix_time = 86400*(fcs.time - datenum(1970, 1, 1));
end

function fcs = recombine_estimates(fcs)
    % Recombine
    % eps1 and eps2 values were already combined in processing, but I'm re-doing it manually here
    both_eps = cat(3, fcs.eps1, fcs.eps2);
    fcs.epsilon = nanmean(both_eps, 3);
    use_smaller = (fcs.eps1 < 10*fcs.eps2) | (fcs.eps2 < 10*fcs.eps1);
    smaller_val = nanmin(both_eps, 3);
    fcs.epsilon(use_smaller) = smaller_val(use_smaller);

    % Assuming there's no wild large differences like there are for shear probe values
    fcs.epsilon_chi = nanmean(cat(3, fcs.eps1_chi, fcs.eps2_chi), 3);
end

function fcs = manually_remove_bad_vals(fcs, unit)
    if strcmp(unit, '4002')
        fcs = manually_remove_bad_vals_4002(fcs);
    elseif strcmp(unit, '4003')
        fcs = manually_remove_bad_vals_4003(fcs);
    end
end

function idx = between(x, bounds);
    idx = x >= bounds(1) & x <= bounds(2);
end

function out = is_near(t, t0)
    % true if t is within 4 minutes of t0
    out =abs(t - t0) < 4*60/86400;
end

function fcs = manually_remove_bad_vals_4002(fcs)
    arcterx23end = datenum(2023, 8, 1);
    % eps1
    t = fcs.time;
    bad_ti = (...
        is_near(t, datenum(2023, 6, 1, 8, 55, 0)) | ...
        is_near(t, datenum(2023, 6, 1, 9, 27, 0)) | ...
        is_near(t, datenum(2023, 6, 1, 19, 31, 0)) | ...
        is_near(t, datenum(2023, 6, 2, 9, 4, 0)) | ...
        is_near(t, datenum(2023, 6, 2, 9, 37, 0)) | ...
        is_near(t, datenum(2023, 6, 2, 19, 12, 0)) | ...
        is_near(t, datenum(2023, 6, 2, 19, 43, 0)) | ...
        is_near(t, datenum(2023, 6, 3, 9, 10, 0)) | ...
        is_near(t, datenum(2023, 6, 3, 11, 45, 0)) | ...
        is_near(t, datenum(2023, 6, 3, 19, 37, 0)) | ...
        is_near(t, datenum(2023, 6, 3, 22, 49, 0)) | ...
        between(t, datenum(2023, 6, 3, [20, 23], 0, 0)) | ...
        between(t, [datenum(2023, 6, 4, 15, 20, 0), arcterx23end]) | ...
        (between(t, [datenum(2023, 6, 2, 5, 40, 0), arcterx23end]) & fcs.isUP));
    fcs.eps1(:, bad_ti) = NaN;

    % eps2
    bad_ti = (...
        is_near(t, datenum(2023, 6, 1, 8, 55, 0)) | ...
        is_near(t, datenum(2023, 6, 1, 9, 28, 0)) | ...
        is_near(t, datenum(2023, 6, 1, 19, 38, 0)) | ...
        (between(t, datenum(2023, 6, 2, [5, 22], [28, 42], 0)) & fcs.isUP) | ...
        (between(t, datenum(2023, 6, 3, [11, 22], [41, 48], 0)) & fcs.isUP) | ...
        (between(t, [datenum(2023, 6, 4, 14, 47, 0), arcterx23end]) & fcs.isUP) | ...
        is_near(t, datenum(2023, 6, 4, 19, 28, 0)) | ...
        is_near(t, datenum(2023, 6, 5, 8, 49, 0)) | ...
        is_near(t, datenum(2023, 6, 5, 9, 24, 0)) | ...
        is_near(t, datenum(2023, 6, 6, 8, 26, 0)) | ...
        is_near(t, datenum(2023, 6, 6, 9, 31, 0)) | ...
        between(t, [datenum(2023, 6, 6, 13, 44, 0), arcterx23end]));

    fcs.eps2(:, bad_ti) = NaN;
end

function fcs = manually_remove_bad_vals_4003(fcs)
    arcterx23end = datenum(2023, 8, 1);
    % eps1
    t = fcs.time;
    bad_ti = (...
        (prctile(log10(fcs.eps1), 10, 1) > - 9.4 & t < datenum(2023, 6, 2, 6, 10, 0)) | ...
        between(t, datenum(2023, 6, [2, 6], [7, 11], [20, 45], 0)) | ...
        between(t, [datenum(2023, 6, 7, 19, 35, 0), arcterx23end]) | ...
        is_near(t, datenum(2023, 6, 7, 9, 20, 0)));
    fcs.eps1(:, bad_ti) = NaN;

    % eps2
    bad_ti = (...
        is_near(t, datenum(2023, 6, 7, 9, 22, 0)) | ...
        between(t, datenum(2023, 6, [7, 8], [19, 9], [35, 22], 0)) | ...
        between(t, datenum(2023, 6, [8, 9], [18, 9], [56, 45], 0)) | ...
        between(t, [datenum(2023, 6, 9, 18, 25, 0), arcterx23end]));
    fcs.eps2(:, bad_ti) = NaN;

    % eps1_chi
    bad_ti = between(t, [datenum(2023, 6, 21, 3, 0, 0), arcterx23end]);
    fcs.eps1_chi(:, bad_ti) = NaN;
end

function fcs = add_readme(fcs)

    z_str          = 'z (Nz, 1):               Depth grid (m)\n';
    tm_str         = 'time (1, Nt):            Matlab time (UTC)\n';
    tu_str         = 'unix_time (1, Nt):       Seconds since Jan 01, 1970 (UTC)\n';
    isUP_str       = 'isUP (1, Nt):            Whether profile is upward\n';
    lat_str        = 'lat (1, Nt):             Latitude (degrees)\n';
    lon_str        = 'lon (1, Nt):             Longitude (degrees)\n';
    T1_str         = 'T1 (Nz, Nt):             Temperature from thermistor 1 (degC)\n';
    T2_str         = 'T2 (Nz, Nt):             Temperature from thermistor 2 (degC)\n';
    T_str          = 'T (Nz, Nt):              Best combination of T1 and T2 (degC)\n';
    Wspd_str       = 'Wspd (Nz, Nt):           Profiling speed (m/s, positive for both directions)\n';
    eps1_str       = 'eps1 (Nz, Nt):           Dissipation rate from shear probe 1 (W/kg)\n';
    eps2_str       = 'eps2 (Nz, Nt):           Dissipation rate from shear probe 2 (W/kg)\n';
    chi1_str       = 'chi1 (Nz, Nt):           T variance dissipation rate from thermistor 1 (K^2/s)\n';
    chi2_str       = 'chi2 (Nz, Nt):           T variance dissipation rate from thermistor 2 (K^2/s)\n';
    epsilon_str    = 'epsilon (Nz, Nt):        Best combination of eps1 and eps2 (W/kg)\n';
    chi_str        = 'chi (Nz, Nt):            Best combination of chi1 and chi2 (W/kg)\n';
    eps1_chi_str   = 'eps1_chi (Nz, Nt):       Dissipation rate from thermistor 1 (W/kg)\n';
    eps2_chi_str   = 'eps2_chi (Nz, Nt):       Dissipation rate from thermistor 2 (W/kg)\n';
    epsilon_chi_str= 'epsilon_chi (Nz, Nt):    Best combination of eps1_chi and eps2_chi (W/kg)\n';
    dTdz_str       = 'dTdz (Nz, Nt):           Temperature gradient (K/m)\n';
    N2_str         = 'N2 (Nz, Nt):             Squared buoyancy frequency from dTdz (s^-2)\n';

    deployment_str = 'Deployed during the May 2023 Arcterx cruise in the West Pacific Ocean.\n\n';
    if floor(min(fcs.time)) == datenum(2024, 5, 21)
        deployment_str = 'May 2024 FCS tests off of San Diego.\n\n'
    end

    fcs.readme = sprintf([...
        'Processed and gridded data for FCS unit ' unit '\n\n' ...
        deployment_str ...
        'Individual reduced profiles were processed following \n' ...
        'Hughes et al. (2023), Ocean Sci., doi: 10.5194/os-19-193-2023\n' ...
        'https://github.com/OceanMixingGroup/flippin-chi-solo\n\n' ...
        'Profiles were then linearly interpolated onto a 1m vertical grid.\n\n' ...
        'Variables:\n\n' ...
        z_str ...
        tm_str ...
        tu_str ...
        isUP_str ...
        lat_str ...
        lon_str ...
        T1_str ...
        T2_str ...
        T_str ...
        Wspd_str ...
        eps1_str ...
        eps2_str ...
        epsilon_str ...
        eps1_chi_str ...
        eps2_chi_str ...
        epsilon_chi_str ...
        dTdz_str ...
        N2_str ...
        '\nCreated by Ken Hughes''s script arcterx23_create_mat_summary.m\n\n' ...
        'Additional notes:\n\n' ...
        'Unit 4002 was deployed once (31 May--6 Jun)\n' ...
        'Unit 4003 was deployed twice (31 May--4 Jun and 6 Jun--21 Jun).\n\n' ...
        'Both units had issues with shear probes degrading a couple days after deployment.\n' ...
        'Hence, the eps1, eps2, and epsilon quantities are short.\n\n' ...
        'Turbulent dissipation is also calculated from the thermistors (assuming Gamma = 0.2).\n' ...
        'These quantities (eps1_chi, eps2_chi, and epsilon_chi) cannot be calculated in the\n' ...
        'absence of stratification. Although the records are longer in time, they sparse near\n' ...
        'the surface.' ...
        ]);
end

function save_summary(fcs)
    dirs = {base_dir 'sum/'};
    for d = dirs
        d = d{:};
        save([d unit '.mat'], 'fcs')
    end
end

end
