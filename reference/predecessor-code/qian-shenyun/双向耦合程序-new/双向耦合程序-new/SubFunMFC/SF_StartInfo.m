%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Subfuntion SF_StartInfo()
%Output the data that was used during calculation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [RunPara] = SF_StartInfo()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp('===================================================================');
disp('::Please choose INTEGRALTION style for FE Model:');
disp('::CASE 0: FEM without ANS formulation.');
disp('::CASE 1: FEM with ANS formulation.');
%%% IsANS = 0, Without using ANS formulation
%%% IsANS = 1, Using ANS formulation
IsANS = input('::(0,1)[0,default]:');
if isempty(IsANS)
    IsANS = 0;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp('===================================================================');
disp('::Do you want to add DAMPING matrix in your FE Model:');
disp('::CASE 0: FEM without Damping matrix.');
disp('::CASE 1: FEM with  Damping matrix.');
%%% IsANS = 0, Without using ANS formulation
%%% IsANS = 1, Using ANS formulation
IsDamp = input('::(0,1)[0,default]:');
if isempty(IsDamp)
    IsDamp = 0;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp('===================================================================');
%%%
disp('::Are you going to simulate LINEAR or NONLINEAR time response?');
disp('::CASE 0: Neither LINEAR or NONLINEAR simulation.');
disp('::CASE 1: LINEAR simulation.');
disp('::CASE 2: NONLINEAR simulation.');
disp('::CASE 3: Both LINEAR and NONLINEAR simulation.');
DoNLSim = input('::(0,1,2,3)[0,default]:');
if isempty(DoNLSim)
    DoNLSim = 0;
end       

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if DoNLSim == 3 || DoNLSim == 3
    disp('===================================================================');
    disp('::Which NONLINEAR theory do you want to use:');
    disp('::CASE 1: RVK5, Refined Von Karman theory with 5 parameters.');
    disp('::CASE 2: MRT5, Moderate Rotation Theory with 5 parameters.');
    disp('::CASE 3: LRT5, Large Rotation Theory with 5 parameters.');
    disp('::CASE 4: LRT56, Large Rotation Theory with 6 parameters.');
    %%% IsANS = 0, Without using ANS formulation
    %%% IsANS = 1, Using ANS formulation
    Theory = input('::(1,2,3,4)[3,default]:');
    if isempty(Theory)
        Theory = 3;
    end
else
    Theory = 0;
end
    

disp('===================================================================');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if IsANS == 0
    disp('>>> ANS: NO'); 
else
    disp('>>> ANS: YES'); 
end

if IsDamp == 0
    disp('>>> DAMPING: NO'); 
else
    disp('>>> DAMPING: YES'); 
end

switch Theory
    case 1
        disp('>>> THEORY: RVK5');
    case 2
        disp('>>> THEORY: MRT5');
    case 3
        disp('>>> THEORY: LRT5');
end

switch DoNLSim
    case 0
        disp('>>> SIMULATION: NO');
    case 1
        disp('>>> SIMULATION: LINEAR');
    case 2
        disp('>>> SIMULATION: NONLINEAR');
    case 3
        disp('>>> SIMULATION: LINEAR and NONLINEAR');
end

disp('-------------------------------------------------------------------');
disp('::Are you sure run the program in your selected style? (Y/N)');
IsStart = input('::(Y/N)[Y,default]:','s');

if isempty(IsStart)
    IsStart = 'Y';
end   

%%%%%%%%%
RunPara = struct('IsANS',IsANS,'DoNLSim',DoNLSim,'IsDamp',IsDamp, ...
                 'Theory',Theory,'IsStart',IsStart);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end
