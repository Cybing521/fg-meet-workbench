function paths = setup_paths()
%SETUP_PATHS  Register workbench, bundled MATLAB solvers, and tool paths.
%   Optional override: config_paths_local.m (gitignored).

    thisDir = fileparts(mfilename('fullpath'));
    paths.workbench = thisDir;
    paths.materials = fullfile(thisDir, 'materials');
    paths.tools = fullfile(thisDir, 'tools');
    paths.cases = fullfile(thisDir, 'cases');
    paths.output = fullfile(thisDir, 'output');
    paths.templates = fullfile(thisDir, 'templates');
    paths.comsol = fullfile(thisDir, 'comsol');
    paths.reference = fullfile(thisDir, 'reference');

    paths.matlab_root = fullfile(thisDir, 'matlab');
    paths.meet_fem_core = fullfile(paths.matlab_root, 'meet-fem-core');
    paths.meet_elastic = fullfile(paths.matlab_root, 'meet-elastic-thermal');
    paths.meet_electro = fullfile(paths.matlab_root, 'meet-electro-thermal');
    paths.meet_magneto = fullfile(paths.matlab_root, 'meet-magneto-thermal');
    paths.fg_reference = fullfile(paths.reference, 'fg-meep-sample-inputs');

    % Back-compat aliases used by older scripts
    paths.subfun = paths.meet_fem_core;

    localCfg = fullfile(thisDir, 'config_paths_local.m');
    if isfile(localCfg)
        localPaths = config_paths_local();
        fn = fieldnames(localPaths);
        for i = 1:numel(fn)
            paths.(fn{i}) = localPaths.(fn{i});
        end
        if isfield(localPaths, 'subfun') && ~isfield(localPaths, 'meet_fem_core')
            paths.meet_fem_core = localPaths.subfun;
            paths.subfun = localPaths.subfun;
        end
    end

    addpath(paths.materials);
    addpath(paths.tools);
    addpath(paths.matlab_root);
    addpath(genpath(paths.meet_fem_core));

    if ~exist(paths.output, 'dir')
        mkdir(paths.output);
    end
    if ~exist(paths.cases, 'dir')
        mkdir(paths.cases);
    end

    fprintf('[fg-meet] workbench: %s\n', paths.workbench);
    fprintf('[fg-meet] meet-elastic: %s\n', paths.meet_elastic);
    fprintf('[fg-meet] meet-fem-core: %s\n', paths.meet_fem_core);
end
