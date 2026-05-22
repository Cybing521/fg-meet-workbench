function patch_input_material(inputPath, layers, headerComment)
%PATCH_INPUT_MATERIAL  Replace MATERIAL START ... MATERIAL END in MEET txt.

    if nargin < 3
        headerComment = '';
    end

    txt = fileread(inputPath);
    startTok = 'MATERIAL START';
    endTok = 'MATERIAL END';

    i0 = strfind(txt, startTok);
    i1 = strfind(txt, endTok);
    if isempty(i0) || isempty(i1)
        error('patch_input_material:MissingBlock', ...
            'MATERIAL block not found in %s', inputPath);
    end

    i0 = i0(1);
    i1 = i1(1) + length(endTok) - 1;

    block = [startTok newline];
    for k = 1:numel(layers)
        block = [block, format_material_line(k, layers(k)), newline]; %#ok<AGROW>
    end
    block = [block, endTok];

    newTxt = [txt(1:i0-1), block, txt(i1+1:end)];
    fid = fopen(inputPath, 'w');
    if fid < 0
        error('patch_input_material:WriteFailed', 'Cannot write %s', inputPath);
    end
    fwrite(fid, newTxt);
    fclose(fid);
end
