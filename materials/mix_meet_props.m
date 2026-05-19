function out = mix_meet_props(vf, bto, cfo)
%MIX_MEET_PROPS  Voigt-style linear mixture of MEET material rows.
    names = fieldnames(bto);
    out = struct();
    for k = 1:numel(names)
        f = names{k};
        out.(f) = vf * bto.(f) + (1 - vf) * cfo.(f);
    end
end
