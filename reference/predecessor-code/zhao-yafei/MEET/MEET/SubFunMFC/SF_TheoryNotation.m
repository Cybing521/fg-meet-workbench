%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Subfuntion SF_GetAnMatr_RVK5()
%Get An matrix
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [TheoryInt,TheoryStr] = SF_TheoryNotation(Theory)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% RVK5 --------  1 
%%% MRT5 --------  2 
%%% LRT5 --------  3 
%%% LRT56 -------  4 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
switch Theory
    case 'RVK5'
        TheoryInt = 1;
        TheoryStr = 'RVK5';
    case 'MRT5'
        TheoryInt = 2;
        TheoryStr = 'MRT5';
    case 'LRT5'
        TheoryInt = 3;
        TheoryStr = 'LRT5';
    case 'LRT56'
        TheoryInt = 4;
        TheoryStr = 'LRT56';
    case 1
        TheoryInt = 1;
        TheoryStr = 'RVK5';
    case 2
        TheoryInt = 2;
        TheoryStr = 'MRT5';
    case 3
        TheoryInt = 3;
        TheoryStr = 'LRT5';
    case 4
        TheoryInt = 4;
        TheoryStr = 'LRT56';
    otherwise         %%% default value
        TheoryInt = 1;
        TheoryStr = 'RVK5';
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end