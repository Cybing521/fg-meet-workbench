function paths = config_paths_local()
%CONFIG_PATHS_LOCAL  Optional path overrides (copy to config_paths_local.m).
%
%   By default all paths resolve inside this repository under matlab/.
%   Only edit this file if you keep solvers in a non-standard location.

    thisDir = fileparts(fileparts(mfilename('fullpath')));
    paths.meet_fem_core = fullfile(thisDir, 'matlab', 'meet-fem-core');
    paths.meet_elastic = fullfile(thisDir, 'matlab', 'meet-elastic-thermal');
    paths.meet_electro = fullfile(thisDir, 'matlab', 'meet-electro-thermal');
    paths.meet_magneto = fullfile(thisDir, 'matlab', 'meet-magneto-thermal');
    paths.subfun = paths.meet_fem_core;
end
