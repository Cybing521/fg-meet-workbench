function paths = setup_paths()
%SETUP_PATHS  Register workbench and upstream MEET code paths.
%   Override on a new machine: copy config_paths_local.example.m to
%   config_paths_local.m (gitignored).

    thisDir = fileparts(mfilename('fullpath'));
    paths.workbench = thisDir;
    paths.materials = fullfile(thisDir, 'materials');
    paths.tools = fullfile(thisDir, 'tools');
    paths.cases = fullfile(thisDir, 'cases');
    paths.output = fullfile(thisDir, 'output');
    paths.templates = fullfile(thisDir, 'templates');

    localCfg = fullfile(thisDir, 'config_paths_local.m');
    if isfile(localCfg)
        localPaths = config_paths_local();
        paths.meet_elastic = localPaths.meet_elastic;
        paths.subfun = localPaths.subfun;
        if isfield(localPaths, 'meet_electro')
            paths.meet_electro = localPaths.meet_electro;
        end
        if isfield(localPaths, 'meet_magneto')
            paths.meet_magneto = localPaths.meet_magneto;
        end
    else
        paths.meet_elastic = fullfile(thisDir, '..', '钱沈云论文及相关代码', ...
            '双向耦合程序-new', '双向耦合程序-new', 'MEET-elastic-thermal');
        paths.subfun = fullfile(thisDir, '..', '钱沈云论文及相关代码', ...
            '双向耦合程序-new', '双向耦合程序-new', 'SubFunMFC');
    end

    addpath(paths.materials);
    addpath(paths.tools);

    if ~exist(paths.output, 'dir')
        mkdir(paths.output);
    end
    if ~exist(paths.cases, 'dir')
        mkdir(paths.cases);
    end

    fprintf('[fg-meet] workbench: %s\n', paths.workbench);
    fprintf('[fg-meet] MEET elastic: %s\n', paths.meet_elastic);
end
