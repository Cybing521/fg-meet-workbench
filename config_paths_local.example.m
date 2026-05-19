function paths = config_paths_local()
%CONFIG_PATHS_LOCAL  Copy to config_paths_local.m and edit on the new machine.
%
%   cp config_paths_local.example.m config_paths_local.m
%
% Expected layout (sibling folders under the same parent as fg-meet-workbench):
%
%   your-workdir/
%     fg-meet-workbench/          <-- this repo
%     meet-elastic-thermal/       <-- copy from 钱沈云 .../MEET-elastic-thermal
%     meet-electro-thermal/       <-- optional, Case B
%     meet-magneto-thermal/       <-- optional, Case C
%     meet-subfun/                <-- copy from .../SubFunMFC

    parent = fileparts(fileparts(mfilename('fullpath')));

    paths.meet_elastic = fullfile(parent, 'meet-elastic-thermal');
    paths.meet_electro = fullfile(parent, 'meet-electro-thermal');
    paths.meet_magneto = fullfile(parent, 'meet-magneto-thermal');
    paths.subfun = fullfile(parent, 'meet-subfun');
end
