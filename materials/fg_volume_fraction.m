function vf = fg_volume_fraction(z, h, vf0, mode, power_n)
%FG_VOLUME_FRACTION  Local BaTiO3 volume fraction along thickness.
%   z in [-h/2, h/2]; vf0 is nominal (average) volume fraction.
%
%   mode: 'U' | 'V' | 'X' | 'O' | 'P'
%   power_n: exponent for 'P' (default 2)

    if nargin < 5 || isempty(power_n)
        power_n = 2;
    end

    zeta = z / h + 0.5;          % 0 at bottom, 1 at top
    abs_z = abs(z) / (h / 2);    % 0 center, 1 surfaces

    switch upper(mode)
        case 'U'
            vf = vf0;
        case 'V'
            vf = vf0 * zeta;
        case 'X'
            vf = vf0 * abs_z;
        case 'O'
            vf = vf0 * (2 - abs_z);
        case 'P'
            vf = vf0 * zeta.^power_n;
        otherwise
            error('fg_volume_fraction:UnknownMode', 'Unknown FG mode: %s', mode);
    end

    vf = max(0, min(1, vf));
end
