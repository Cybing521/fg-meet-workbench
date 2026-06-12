%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Subfuntion SF_GetAnMatr_RVK5()
%Get An matrix
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ShellInt,ShellStr] = SF_ShellNotation(Shell)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% PLATE -----------  1 
%%% CYLINDER --------  2 
%%% SPHERE ----------  3 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
switch Shell
    case 'PLATE'
        ShellInt = 1;
        ShellStr = 'PLATE';
    case 'CYLINDER'
        ShellInt = 2;
        ShellStr = 'CYLINDER';
    case 'SPHERE'
        ShellInt = 3;
        ShellStr = 'SPHERE';
    case 1
        ShellInt = 1;
        ShellStr = 'PLATE';
    case 2
        ShellInt = 2;
        ShellStr = 'CYLINDER';
    case 3
        ShellInt = 3;
        ShellStr = 'SPHERE';
    otherwise         %%% default value
        ShellInt = 1;
        ShellStr = 'PLATE';
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end