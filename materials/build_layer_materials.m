function layers = build_layer_materials(nLayer, h, vf0, fgMode, varargin)
%BUILD_LAYER_MATERIALS  Layer-wise MEET material rows for FG-MEE plate.
%   layers(k) has fields for layer k (bottom -> top), including zC1, zC2.
%
%   Usage:
%     layers = build_layer_materials(nLayer, h, vf0, fgMode)
%     layers = build_layer_materials(nLayer, h, vf0, fgMode, power_n)
%     layers = build_layer_materials(nLayer, h, vf0, fgMode, power_n, e0, porosity_mode)
%
%   Inputs:
%     nLayer        - number of layers through thickness
%     h             - plate thickness (m)
%     vf0           - nominal BaTiO3 volume fraction
%     fgMode        - FG distribution: 'U','V','X','O','P'
%     power_n       - (optional) power-law exponent, default 2
%     e0            - (optional) porosity parameter, default 0 (no porosity)
%     porosity_mode - (optional) 1=Even, 2=Uneven, 3=Log-uneven, default 1

    % Parse optional arguments
    power_n = 2;
    e0 = 0;
    poro_mode = 1;

    if numel(varargin) >= 1 && ~isempty(varargin{1})
        power_n = varargin{1};
    end
    if numel(varargin) >= 2 && ~isempty(varargin{2})
        e0 = varargin{2};
    end
    if numel(varargin) >= 3 && ~isempty(varargin{3})
        poro_mode = varargin{3};
    end

    [bto, cfo] = get_bto_cfo_meet_props();

    dz = h / nLayer;
    layers = repmat(struct(), nLayer, 1);

    for k = 1:nLayer
        z1 = -h/2 + (k - 1) * dz;
        z2 = -h/2 + k * dz;
        zMid = 0.5 * (z1 + z2);

        vf = fg_volume_fraction(zMid, h, vf0, fgMode, power_n);
        props = mix_meet_props(vf, bto, cfo);

        % Apply porosity correction if e0 > 0
        if e0 > 0
            props = porosity_correction(props, e0, poro_mode, zMid, h);
        end

        layers(k) = props;
        layers(k).zC1 = z1;
        layers(k).zC2 = z2;
        layers(k).IsSmtLay = 2;
        layers(k).vf_local = vf;
    end
end
