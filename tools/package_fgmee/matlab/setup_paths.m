function paths = setup_paths()
%SETUP_PATHS Register only the paths shipped in the minimal FG-MEE package.

    matlabDir = fileparts(mfilename('fullpath'));
    codeDir = fileparts(matlabDir);
    packageRoot = fileparts(codeDir);

    paths.package_root = packageRoot;
    paths.workbench = packageRoot;
    paths.cases = fullfile(packageRoot, 'cases');
    paths.output = fullfile(packageRoot, 'results', 'recomputed', 'cache');
    paths.matlab_root = matlabDir;
    paths.meet_fem_core = fullfile(matlabDir, 'lib', 'meet_core');
    paths.meet_elastic = paths.meet_fem_core;
    paths.meet_electro = paths.meet_fem_core;
    paths.meet_magneto = paths.meet_fem_core;
    paths.subfun = paths.meet_fem_core;

    addpath(matlabDir);
    addpath(fullfile(matlabDir, 'jobs'));
    addpath(fullfile(matlabDir, 'lib'));
    addpath(paths.meet_fem_core);

    if ~isfolder(paths.output)
        mkdir(paths.output);
    end
    fprintf('[fgmee-minimal] package root: %s\n', paths.package_root);
end
