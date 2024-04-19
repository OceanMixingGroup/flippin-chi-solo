function [Vavg, Vpsi] = rename_comp_structs_fcs(comp)
    % Make the structs output by comp_load_solo2 match the existing FCS code
    %
    % Input
    % -----
    % comp: struct with names such as psiS1Fit1, T1Mean, and WspdMin
    %
    % Output
    % ------
    % Vavg: equivalent to Vavg in the reduced Matlab processing
    % Vpsi: equivalent to Vpsi in the reduced Matlab processing

    Vavg.T1 = comp.T1Mean;
    Vavg.T2 = comp.T2Mean;
    Vavg.Wspd_min = comp.WspdMin;
    Vavg.P_end = comp.pEnd;

    Vpsi.psi_S1_fit = [comp.psiS1Fit1, comp.psiS1Fit2];
    Vpsi.psi_S2_fit = [comp.psiS2Fit1, comp.psiS2Fit2];
    Vpsi.psi_T1P_fit = [comp.psiT1pFit1, comp.psiT1pFit2];
    Vpsi.psi_T2P_fit = [comp.psiT2pFit1, comp.psiT2pFit2];

    % Deal with missing values in shear data
    % This affects tests done at Scripps in early 2023
    Vpsi.psi_S1_fit(Vpsi.psi_S1_fit == 1e-16) = NaN;
    Vpsi.psi_S2_fit(Vpsi.psi_S2_fit == 1e-16) = NaN;
end
