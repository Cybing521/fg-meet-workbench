function result = run_meet_static(caseFile, loadCase, varargin)
%RUN_MEET_STATIC  Static thermo-magneto-electro-elastic solve (bundled MEET FEM).
%
%   result = run_meet_static(caseFile, loadCase)
%   result = run_meet_static(..., 'LoadScale', -15000, 'OutTag', 'U_Vf06')
%
%   loadCase: 'elastic' | 'electro' | 'magneto'  (Case A / B / C)
%   caseFile: path to MEET input txt (from cases/)

    p = inputParser;
    addRequired(p, 'caseFile', @(x) ischar(x) || isstring(x));
    addRequired(p, 'loadCase', @(x) any(strcmpi(x, {'elastic','electro','magneto'})));
    addParameter(p, 'LoadScale', [], @(x) isempty(x) || isnumeric(x));
    addParameter(p, 'Volt', 300, @isnumeric);
    addParameter(p, 'Magnetic', 200, @isnumeric);
    addParameter(p, 'OutTag', '', @ischar);
    parse(p, caseFile, loadCase, varargin{:});

    paths = setup_paths();
    caseFile = char(caseFile);
    if ~isfile(caseFile)
        error('run_meet_static:NoInput', 'Input file not found: %s', caseFile);
    end

    switch lower(loadCase)
        case 'elastic'
            meetDir = paths.meet_elastic;
            defaultLoad = -15000;
        case 'electro'
            meetDir = paths.meet_electro;
            defaultLoad = 0;
        case 'magneto'
            meetDir = paths.meet_magneto;
            defaultLoad = 0;
    end

    if isempty(p.Results.LoadScale)
        loadmax = defaultLoad;
    else
        loadmax = p.Results.LoadScale;
    end

    oldDir = pwd;
    cleanup = onCleanup(@() cd(oldDir)); %#ok<NASGU>
    cd(meetDir);

    InputFile = caseFile;
    OutputFile = [];
    UsedDataFile = fullfile(paths.output, 'LINEAR_DataUsed_runtime.txt');
    IsANS = 0;
    DampRatio = 0.8/100;
    IntegSchem = 'G2';
    Theory = 4;
    ThermalNL = 0;

    [GlobMatr, ~, ~] = Main_FOSDLIN851T5MEET_V4( ...
        InputFile, OutputFile, UsedDataFile, IsANS, DampRatio, IntegSchem, ThermalNL);

    KuuT = GlobMatr.KuuT;
    KutT = GlobMatr.KutT;
    KtuT = GlobMatr.KtuT;
    KttT = GlobMatr.KttT;
    KufMT = GlobMatr.KufMT;
    KuzT = GlobMatr.KuzT;
    FusT = GlobMatr.FusT;

    FinalDofM = size(KuuT, 1);
    FinalDofMEE = size(KttT, 1);
    nMeePerElem = 10;

    PhiaMT = zeros(FinalDofMEE, 1);
    MgaT = zeros(FinalDofMEE, 1);
    PhiaMT(nMeePerElem:nMeePerElem:FinalDofMEE) = -p.Results.Volt;
    PhiaMT(1:nMeePerElem:FinalDofMEE) = p.Results.Volt;
    MgaT(nMeePerElem:nMeePerElem:FinalDofMEE) = -p.Results.Magnetic;
    MgaT(1:nMeePerElem:FinalDofMEE) = p.Results.Magnetic;

    FueT = FusT * loadmax;
    FutT = zeros(FinalDofMEE, 1);

    AA = [KuuT, KutT; KtuT, KttT];
    BB = [FueT; FutT];
    CC = AA \ BB;
    Qd = CC(1:FinalDofM);
    SensM_T = CC(FinalDofM+1:end);

    % 30x30 plate center node (approx.)
    centerIdx = 31 + 30 * 15;
    wCenter = Qd(5 * (centerIdx - 1) + 3);

    result = struct();
    result.loadCase = lower(loadCase);
    result.inputFile = caseFile;
    result.wCenter_m = wCenter;
    result.wCenter_mm = wCenter * 1000;
    result.theta_layers = SensM_T(1:nMeePerElem:min(nMeePerElem*10, numel(SensM_T)));
    result.loadScale = loadmax;
    result.timestamp = datestr(now);

    tag = p.Results.OutTag;
    if isempty(tag)
        [~, tag, ~] = fileparts(caseFile);
    end
    outMat = fullfile(paths.output, sprintf('static_%s_%s.mat', lower(loadCase), tag));
    save(outMat, 'result', 'Qd', 'SensM_T');
    fprintf('Saved %s\n', outMat);
    fprintf('w_center = %.6f mm\n', result.wCenter_mm);
end
