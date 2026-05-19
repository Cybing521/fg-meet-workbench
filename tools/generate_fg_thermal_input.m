function outPath = generate_fg_thermal_input(opts)
%GENERATE_FG_THERMAL_INPUT  Clone template and write FG layer materials.
%
% opts fields:
%   templatePath  - base MEET txt (mesh/BC unchanged)
%   outPath       - output file
%   vf0, fgMode, nLayer, h
%   power_n (optional, for P-type)

    if ~isfield(opts, 'power_n'), opts.power_n = 2; end
    if ~isfield(opts, 'h'), opts.h = 6e-3; end
    if ~isfield(opts, 'nLayer'), opts.nLayer = 10; end

    if ~exist(fileparts(opts.outPath), 'dir')
        mkdir(fileparts(opts.outPath));
    end
    copyfile(opts.templatePath, opts.outPath);

    layers = build_layer_materials(opts.nLayer, opts.h, opts.vf0, opts.fgMode, opts.power_n);
    comment = sprintf('FG %s Vf0=%.2f auto-generated', opts.fgMode, opts.vf0);
    patch_input_material(opts.outPath, layers, comment);
    outPath = opts.outPath;
end
