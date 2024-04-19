function f_Az = define_comp_surf_freq_vector()
    % Onboard processing reports the first 64 coefficients. There are 129 from 0 to 1 Hz.
    Nf = 64;
    f_Az = linspace(0, 0.5, Nf+1)';  %
    f_Az = f_Az(1:end-1);
end
