function [cal, blk, avg, phi] = add_readmes_full_fcs(cal, blk, avg, phi, head)
% function add_readmes_full_fcs(cal, blk, avg, phi)
%   Record what's in each struct created by process_cast_full_fcs

% To do: ensure readmes are correct
t_str       = 'time:                 Matlab time\n';
T_str       = 'T1, T2:               Temperature from two thermistors (degC)\n';
Ta_str      = 'T:                    Mean of T1, T2 (degC)\n';
TP_str      = 'T1P, T2P:             Microstructure temperature gradient from two thermistors (degC/m)\n';
s_str       = 'S1, S2:               Microstructure shear from two shear probes (/s)\n';
P_str       = 'P:                    Pressure (dbar)\n';
W_str       = 'Wspd:                 Profiling speed derived from pressure (m/s)\n';
Wmin_str    = 'Wspd_min:             Minimum Wspd within block (m/s)\n';
A_str       = 'AX, AY, AZ:           Accelerations (m/s^2)\n';
nu_str      = 'nu:                   Molecular viscosity (m^2/s)\n';
DT_str      = 'DT:                   Molecular thermal diffusivity (m^2/s)\n';
eps_str     = 'eps1, eps2:           Turbulent dissipation rate from each shear probe (W/kg)\n';
epsa_str    = 'epsilon:              Combined value (see Notes) from eps1, eps2 (W/kg)\n';
chi_str     = 'chi1, chi2:           Thermal variance dissipation rate from each thermistor (K^2/s)\n';
chia_str    = 'chi:                  Combined value (see Notes) from chi1, chi2 (K^2/s)\n';
kend_s_str  = 'k_end1_s, k_end2_s:   Upper limit of integral over shear spectrum (cpm)\n';
kend_TP_str = 'k_end1_TP, k_end2_TP: Upper limit of integral over Tz spectrum (cpm)\n';
phi_s_str   = 'S1, S2:               Corrected shear spectra from two shear probes (s^-2/cpm)\n';
phi_TP_str  = 'T1P, T2P:             Corrected Tz spectra from two thermistors ((K/m)^2/cpm)\n';
phi_k_str   = 'k:                    Wavenumber (cpm)\n';
phi_f_str   = 'f:                    Frequency (Hz)\n';

cal.readme = sprintf([...
    'Calibrated data for file \n' head.data_filename '\n\n' ...
    'Each quantity is a 1 x N vector where N is the total number of profiling data.\n\n' ...
    t_str ...
    T_str ...
    TP_str ...
    s_str ...
    P_str ...
    W_str ...
    A_str ...
    '\nCreated by the script flippin_chi_solo/full/process_cast_full_fcs.m'
    ]);

blk.readme = sprintf([...
    'Calibrated data (reshaped into segments of length ' num2str(head.Nfft) ') ' ...
    'for file \n' head.data_filename '\n\n' ...
    'Each quantity is a Nx x ' num2str(head.Nfft) ' array.\n\n' ...
    t_str ...
    T_str ...
    TP_str ...
    s_str ...
    P_str ...
    W_str ...
    A_str ...
    '\nCreated by the script flippin_chi_solo/full/process_cast_full_fcs.m'
    ]);

avg.readme = sprintf([...
    'Quantities either averaged or derived from ' num2str(head.Nfft) '-element segments for file \n' ...
    head.data_filename '\n\n' ...
    'Each quantity is a Nz x 1 vector where Nz is the number of segments.\n\n' ...
    t_str ...
    T_str ...
    Ta_str ...
    P_str ...
    W_str ...
    Wmin_str ...
    nu_str ...
    DT_str ...
    eps_str ...
    epsa_str ...
    chi_str ...
    chia_str ...
    '\n' ...
    'Notes:\n' ...
    'eps1 and eps2 are combined to give single estimate of epsilon by either taking the mean\n' ...
    'of the two or the smaller of the two if they differ by more than factor of 10.\n' ...
    'And similarly for chi.\n' ...
    '\n' ...
    '\nCreated by the script flippin_chi_solo/full/process_cast_full_fcs.m'
    ]);

phi.readme = sprintf([...
    'Spectra derived from ' num2str(head.Nfft) '-element segments for file \n' ...
    head.data_filename '\n\n' ...
    'Spectra arrays and k are Nz x Nf where Nz is the number of segments and Nf = ' ...
    num2str(head.Nfft) '/2 + 1:\n' ...
    phi_s_str ...
    phi_TP_str ...
    phi_k_str ...
    '\n' ...
    'Upper limits of integration are Nz-element vectors:\n' ...
    kend_s_str ...
    kend_TP_str ...
    '\n' ...
    'Also included is the vector\n' ...
    phi_f_str ...
    '\n' ...
    'Notes:\n' ...
    'Shear spectra are corrected for the spatial averaging of the shear probe,\n'...
    'the antialiasing filter, and the digital filter.\n' ...
    'Tz spectra are corrected for the thermal response of the thermistor, \n'...
    'the antialiasing filter, and the digital filter.\n' ...
    '\n' ...
    '\nCreated by the script flippin_chi_solo/full/process_cast_full_fcs.m'
    ]);


end
