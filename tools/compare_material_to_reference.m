function report = compare_material_to_reference(genPath, refPath)
%COMPARE_MATERIAL_TO_REFERENCE  Max relative diff of MATERIAL rows.

    gLines = read_material_rows(genPath);
    rLines = read_material_rows(refPath);
    n = min(numel(gLines), numel(rLines));

    maxRel = 0;
    for k = 1:n
        g = sscanf(gLines{k}, '%f')';
        r = sscanf(rLines{k}, '%f')';
        nCol = min(numel(g), numel(r));
        for c = 2:nCol  % skip layer index
            denom = max(abs(r(c)), eps);
            maxRel = max(maxRel, abs(g(c) - r(c)) / denom);
        end
    end

    report.maxRelDiff = maxRel;
    report.nLayers = n;
    fprintf('Material compare: %s vs %s\n', genPath, refPath);
    fprintf('  layers=%d  maxRelDiff=%.4e\n', n, maxRel);
end

function lines = read_material_rows(fpath)
    raw = fileread(fpath);
    i0 = strfind(raw, 'MATERIAL START');
    i1 = strfind(raw, 'MATERIAL END');
    block = raw(i0(1)+length('MATERIAL START'):i1(1)-1);
    lines = {};
    for ln = splitlines(block)
        t = strtrim(ln{1});
        if isempty(t) || startsWith(t, '%')
            continue;
        end
        if ~isempty(regexp(t, '^\d', 'once'))
            lines{end+1} = t; %#ok<AGROW>
        end
    end
end
