function props = porosity_correction(props, e0, porosity_mode, z, h)
%POROSITY_CORRECTION  Apply porosity correction to MEET material properties.
%
%   props = porosity_correction(props, e0, porosity_mode, z, h)
%
%   Inputs:
%     props         - struct with material fields (from mix_meet_props)
%     e0            - porosity parameter (0 < e0 < 1), 0 means no porosity
%     porosity_mode - 1: Even (uniform), 2: Uneven (center-rich), 3: Log-uneven
%     z             - thickness coordinate of layer midplane [-h/2, h/2]
%     h             - total plate thickness
%
%   Output:
%     props - corrected struct with all material fields scaled by porosity factor
%
%   Reference: Wattanasakulpong & Ungbhakorn (2014); Zhao et al. (2024)
%              建模思路_版本二_含孔隙FG-MEE板.docx

    if nargin < 2 || isempty(e0) || e0 == 0
        return;  % no correction needed
    end

    if nargin < 3 || isempty(porosity_mode)
        porosity_mode = 1;
    end

    % Compute correction factor based on porosity distribution mode
    abs_z_norm = abs(z) / (h / 2);  % normalized: 0 at center, 1 at surfaces

    switch porosity_mode
        case 1  % Mode I: Even (uniform porosity)
            factor = 1 - e0;

        case 2  % Mode II: Uneven (center-rich, surfaces dense)
            factor = 1 - e0 * (1 - 2 * abs(z) / h);

        case 3  % Mode III: Logarithmic-uneven
            % Avoid log(0) at surfaces: clamp argument
            arg = 1 - 2 * abs(z) / h;
            arg = max(arg, 1e-10);
            factor = 1 - (e0 / 2) * log(1 ./ arg);
            % Ensure factor stays positive and physical
            factor = max(factor, 0.01);

        otherwise
            error('porosity_correction:UnknownMode', ...
                'Unknown porosity mode: %d. Use 1 (Even), 2 (Uneven), or 3 (Log-uneven).', ...
                porosity_mode);
    end

    % Apply correction to all material property fields
    fields_to_correct = {'E1','E2','v12','G12','G13','G23', ...
                         'd31','d32','q31','q32', ...
                         'g33','k33','r33', ...
                         'A1','A2','PyroE','PyroM', ...
                         'Cv','Density'};

    for i = 1:numel(fields_to_correct)
        f = fields_to_correct{i};
        if isfield(props, f)
            props.(f) = props.(f) * factor;
        end
    end
end
