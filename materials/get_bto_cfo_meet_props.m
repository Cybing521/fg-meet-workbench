function [bto, cfo] = get_bto_cfo_meet_props()
%GET_BTO_CFO_MEET_PROPS  MEET input-row properties for BaTiO3 and CoFe2O4 phases.
%
% Fields match Thermal_CFFFplate input (27 columns). Values are calibrated so
%   mix(Vf0=0.6, U-type) ~= Qian Shenyun uniform 0.6Vf reference row.
% Base data: Kondaiah et al. (2012); Kim (2011); Zhang et al. (2026) Table 1.

    % --- CoFe2O4 (ferromagnetic, Vf -> 0) ---
    cfo.E1 = 2.10e11;
    cfo.E2 = 2.10e11;
    cfo.v12 = 0.31;
    cfo.v23 = 0.0;
    cfo.G12 = 4.53e10;
    cfo.G13 = 4.53e10;
    cfo.G23 = 4.53e10;
    cfo.d31 = 0.0;
    cfo.d32 = 0.0;
    cfo.angle = 0.0;
    cfo.hE = 6.0e-4;
    cfo.q31 = 5.80e2;
    cfo.q32 = 5.80e2;
    cfo.g33 = 9.3e-11;
    cfo.k33 = 0.0;
    cfo.r33 = 1.57e-3;
    cfo.A1 = 1.8e6;
    cfo.A2 = 1.8e6;
    cfo.PyroE = 0.0;
    cfo.PyroM = 0.0;
    cfo.Cv = 165.0;
    cfo.HC = 1.0;
    cfo.Density = 5300.0;

    % --- BaTiO3 (ferroelectric, Vf -> 1) ---
    bto.E1 = 1.50e11;
    bto.E2 = 1.50e11;
    bto.v12 = 0.36;
    bto.v23 = 0.0;
    bto.G12 = 4.30e10;
    bto.G13 = 4.30e10;
    bto.G23 = 4.30e10;
    bto.d31 = -9.0e-11;
    bto.d32 = -9.0e-11;
    bto.angle = 0.0;
    bto.hE = 6.0e-4;
    bto.q31 = 0.0;
    bto.q32 = 0.0;
    bto.g33 = 1.26e-8;
    bto.k33 = 0.0;
    bto.r33 = 1.0e-5;
    bto.A1 = 2.5e6;
    bto.A2 = 2.5e6;
    bto.PyroE = 0.0;
    bto.PyroM = 0.0;
    bto.Cv = 422.0;
    bto.HC = 1.0;
    bto.Density = 5800.0;

    % Anchor: match Qian 0.6Vf uniform homogenized row (Thermal_CFFFplate)
    ref = struct( ...
        'E1', 1.206e11, 'E2', 1.206e11, 'v12', 3.398e-01, 'v23', 0.0, ...
        'G12', 4.500e10, 'G13', 4.500e10, 'G23', 4.500e10, ...
        'd31', -5.404e-11, 'd32', -5.404e-11, ...
        'q31', 4.947e1, 'q32', 4.947e1, ...
        'g33', 9.203e-09, 'k33', 1.755e-08, 'r33', 7.536e-05, ...
        'A1', 2.356e+06, 'A2', 2.356e+06, ...
        'PyroE', 2.492e-04, 'PyroM', 5.900e-03, ...
        'Cv', 425.2232, 'Density', 5600.0);

    vfRef = 0.6;
    bto = calibrate_phase(bto, cfo, ref, vfRef);
end

function phase = calibrate_phase(bto, cfo, ref, vfRef)
    names = fieldnames(ref);
    for k = 1:numel(names)
        f = names{k};
        if isfield(bto, f)
            bto.(f) = (ref.(f) - (1 - vfRef) * cfo.(f)) / vfRef;
        end
    end
    phase = bto;
end
