function layers = build_layer_materials(nLayer, h, vf0, fgMode, varargin)
%BUILD_LAYER_MATERIALS  Layer-wise MEET material rows for FG-MEE plate.
%   layers(k) has fields for layer k (bottom -> top), including zC1, zC2.

    [bto, cfo] = get_bto_cfo_meet_props();

    power_n = 2;
    if ~isempty(varargin)
        power_n = varargin{1};
    end

    dz = h / nLayer;
    layers = repmat(struct(), nLayer, 1);

    for k = 1:nLayer
        z1 = -h/2 + (k - 1) * dz;
        z2 = -h/2 + k * dz;
        zMid = 0.5 * (z1 + z2);

        vf = fg_volume_fraction(zMid, h, vf0, fgMode, power_n);
        props = mix_meet_props(vf, bto, cfo);

        layers(k) = props;
        layers(k).zC1 = z1;
        layers(k).zC2 = z2;
        layers(k).IsSmtLay = 2;
        layers(k).vf_local = vf;
    end
end
