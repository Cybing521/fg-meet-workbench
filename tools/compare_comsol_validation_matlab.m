function compare_comsol_validation_matlab(comsolCsv, meetMat, caseFile, pointOut, logOut, summaryOut, runTag, caseId, fgMode, vf0, bc, comsolMesh, notesExtra, runDate)
%COMPARE_COMSOL_VALIDATION_MATLAB Compare COMSOL point CSV with MEET .mat output.
% This mirrors compare_comsol_validation_general.py but uses MATLAB to read
% MEET .mat files, avoiding a scipy dependency during COMSOL validation runs.

if nargin < 14
    runDate = string(datetime("today", "Format", "yyyy-MM-dd"));
end

rows = readtable(comsolCsv, "TextType", "string");
[coords, matlabWByNode] = loadMeetDisplacementByCoord(caseFile, meetMat);

matlabWm = zeros(height(rows), 1);
for i = 1:height(rows)
    target = round([rows.x_m(i), rows.y_m(i), rows.z_m(i)], 8);
    match = find(all(abs(coords - target) < 5e-9, 2), 1);
    if isempty(match)
        error("No MEET node coordinate matched COMSOL point %s at [%g %g %g].", ...
            rows.point_id(i), rows.x_m(i), rows.y_m(i), rows.z_m(i));
    end
    matlabWm(i) = matlabWByNode(match);
end

rows.matlab_w_m = matlabWm;
rows.matlab_w_mm = 1000.0 * matlabWm;
rows.diff_w_mm = rows.comsol_w_mm - rows.matlab_w_mm;
rows.rel_err_w_pct = abs(rows.diff_w_mm) ./ max(abs(rows.matlab_w_mm), 1e-15) * 100.0;

ensureParent(pointOut);
writetable(rows, pointOut);

centerIdx = find(rows.point_id == "p8", 1);
if isempty(centerIdx)
    error("COMSOL CSV does not contain point_id p8: %s", comsolCsv);
end
maxAbsDiff = max(abs(rows.diff_w_mm));
maxRelErr = max(rows.rel_err_w_pct);
meanRelErr = mean(rows.rel_err_w_pct);
notes = sprintf("15-point comparison; max_abs_diff_mm=%.6g; max_rel_err_pct=%.6g; mean_rel_err_pct=%.6g", ...
    maxAbsDiff, maxRelErr, meanRelErr);
if strlength(string(notesExtra)) > 0
    notes = notes + "; " + string(notesExtra);
end

logRow = table( ...
    string(caseId), string(fgMode), string(vf0), "elastic", string(bc), ...
    rows.matlab_w_mm(centerIdx), rows.comsol_w_mm(centerIdx), rows.rel_err_w_pct(centerIdx), ...
    "", "", "", "30x30 MEET", string(comsolMesh), string(notes), string(runDate));
logRow.Properties.VariableNames = { ...
    'case_id', 'fg_mode', 'vf0', 'load_case', 'bc', ...
    'matlab_w_mm', 'comsol_w_mm', 'rel_err_w_pct', ...
    'matlab_theta_K', 'comsol_theta_K', 'rel_err_theta_pct', ...
    'matlab_mesh', 'comsol_mesh', 'notes', 'date' ...
};
appendTable(logRow, logOut);

summaryRow = table( ...
    string(runTag), string(caseId), string(comsolCsv), ...
    rows.matlab_w_mm(centerIdx), rows.comsol_w_mm(centerIdx), rows.rel_err_w_pct(centerIdx), ...
    maxAbsDiff, maxRelErr, meanRelErr, string(comsolMesh), string(notesExtra), string(runDate));
summaryRow.Properties.VariableNames = { ...
    'run_tag', 'case_id', 'comsol_csv', ...
    'matlab_w_p8_mm', 'comsol_w_p8_mm', 'center_rel_err_pct', ...
    'max_abs_diff_mm', 'max_rel_err_pct', 'mean_rel_err_pct', ...
    'comsol_mesh', 'notes', 'date' ...
};
appendTable(summaryRow, summaryOut);

fprintf("Wrote %s\n", pointOut);
fprintf("Updated %s\n", logOut);
fprintf("Updated %s\n", summaryOut);
end

function [coords, wByNode] = loadMeetDisplacementByCoord(caseFile, meetMat)
nodes = parseCaseNodes(caseFile);
data = load(meetMat);
if isfield(data, "TQd")
    tqd = data.TQd(:);
else
    tqd = restoreFullTqd(nodes, data.Qd(:));
end
if numel(tqd) ~= numel(nodes) * 5
    error("Full TQd length mismatch: %d vs %d.", numel(tqd), numel(nodes) * 5);
end

coords = zeros(numel(nodes), 3);
wByNode = zeros(numel(nodes), 1);
for i = 1:numel(nodes)
    coords(i, :) = nodes(i).coord;
    wByNode(i) = tqd((i - 1) * 5 + 3);
end
end

function nodes = parseCaseNodes(caseFile)
text = fileread(caseFile);
startIdx = strfind(text, "NODE START");
endIdx = strfind(text, "NODE END");
if isempty(startIdx) || isempty(endIdx)
    error("Case file does not contain NODE START/END: %s", caseFile);
end
block = extractBetween(text, startIdx(1) + strlength("NODE START"), endIdx(1) - 1);
lines = splitlines(block);
nodes = struct("id", {}, "coord", {}, "flags", {});
for i = 1:numel(lines)
    line = char(strtrim(erase(lines(i), ";")));
    if isempty(line) || ~isstrprop(line(1), "digit")
        continue;
    end
    values = sscanf(line, "%f").';
    if numel(values) < 9
        continue;
    end
    nodes(end + 1).id = round(values(1)); %#ok<AGROW>
    nodes(end).coord = round(values(2:4), 8);
    nodes(end).flags = round(values(5:9));
end
end

function tqd = restoreFullTqd(nodes, qd)
tqd = zeros(numel(nodes) * 5, 1);
qIndex = 1;
for i = 1:numel(nodes)
    for j = 1:5
        fullIndex = (i - 1) * 5 + j;
        if nodes(i).flags(j) == 0
            if qIndex > numel(qd)
                error("Reduced Qd length mismatch while restoring full TQd.");
            end
            tqd(fullIndex) = qd(qIndex);
            qIndex = qIndex + 1;
        else
            tqd(fullIndex) = 0.0;
        end
    end
end
if qIndex - 1 ~= numel(qd)
    error("Reduced Qd length mismatch: consumed %d, length %d.", qIndex - 1, numel(qd));
end
end

function ensureParent(pathValue)
parent = fileparts(pathValue);
if parent ~= "" && ~isfolder(parent)
    mkdir(parent);
end
end

function appendTable(row, outputPath)
ensureParent(outputPath);
if isfile(outputPath)
    writetable(row, outputPath, "WriteMode", "append", "WriteVariableNames", false);
else
    writetable(row, outputPath);
end
end
