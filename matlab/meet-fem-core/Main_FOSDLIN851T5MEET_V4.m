%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Main_FOSDLIN851T5MEEP_V4()
% Main function for computing linear FEM

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Call this Main Function
% InputFile = 'Plate_PZT_Patch_FOSD_851_Input_25Elem.txt';
% OutputFile = 'LIN_FEM_FOSD';
% UsedDataFile = 'DataUsed.txt';
% [GlobMatr,FinitElemInfo,MateProp] = MainFOSDLIN851(InputFile, ...
%                                               OutputFile,UsedDataFile);

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [GlobMatr,FinitElemInfo,MateProp] = Main_FOSDLIN851T5MEET_V4(InputFile, ...
                        OutputFile,UsedDataFile,IsANS,DampRatio,IntegSchem,ThermalNL)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% addpath(genpath('C:\Zhang Shunqi\Our Laboratory\Matlab\NonLinearFEM\SubFunction'));
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% ElemType = [Node/Elem DOF/Node NumSmtLay DOF/SmtLay NumLay]

%% Get data from input file
%%% FinitElemInfo: ElemType,Element,Node
%%% Material: Material parameters for every layer

[FinitElemInfo,Material] = SF_GetInputDataMEEP(InputFile);
[ERROR] = SF_InputFileCheckMEEP(FinitElemInfo,Material);
%%% ERROR: 0, input correct; 1-10, input has mistaks;
if ERROR ~=0
    return
end

ShellTheory = FinitElemInfo.ShellTheory;
[~,ShellStr] = SF_ShellNotation(ShellTheory(1,1));

%% Get material parameters from Material matrix
%%% MateProp{LayIndex,1}.c, MateProp{LayIndex,1}.e, MateProp{LayIndex,1}.g
%%% MateProp{LayIndex,1}.Density, MateProp{LayIndex,1}.Lay_zC
%%% MateProp{LayIndex,1}.IsSmtLay
[MateProp] = SF_GetMatePropMEEP(Material,FinitElemInfo);
%% Initial Global matrices, MuuT,CuuT,KuuT.....
[GlobMatr] = SF_InitGlobMatr(FinitElemInfo);
%% Get Basic values
ElemType = FinitElemInfo.ElemType;
Element = FinitElemInfo.Element;
Node = FinitElemInfo.Node;

NumElem = length(Element(:,1));
NumLay = ElemType(3);
NodePerElem = ElemType(1);

%% Output the data that was use during calculation
 SF_GetUsedData(UsedDataFile,FinitElemInfo,Material,MateProp);
%% Get the whole thickness
[Totalthickness] = SF_Totalthickness(FinitElemInfo,Material,MateProp);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% The start of the Finite element computation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for EleIndex=1:NumElem
    for LayIndex = 1:NumLay
        if Element(EleIndex,NodePerElem+LayIndex) == 1
            %%% Calculate ith layer of structure
            MatePropCurrLay = MateProp{LayIndex,1};
 
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%% Element computation
            %%% IsANS: 1, using ANS formulation; 
            %%%        0, without using ANS formulation
            if IsANS == 1

            else
                 [ElemMatr]=SF_ElemComptLIN851T5MEEP_V4(EleIndex,MatePropCurrLay, ...
                                   MateProp,LayIndex,FinitElemInfo,IntegSchem,Totalthickness,ThermalNL);
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %Assembling
            [GlobMatr]=SF_Assembling(EleIndex,ElemMatr,GlobMatr, ...
                                     FinitElemInfo);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        end
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% For Fus, external surface force
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% External unit surface force
    fs=[0;0;1];
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [ElemMatr] = SF_GetFusVect(EleIndex,FinitElemInfo,fs);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Assembling
    [GlobMatr] = SF_Assembling(EleIndex,ElemMatr,GlobMatr, ...
                               FinitElemInfo);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% The end of the Finite element computation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Add boundary conditions
[GlobMatr] = SF_Condensation(GlobMatr,FinitElemInfo,MateProp);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
FinalDofM = length(GlobMatr.KuuT(1,:));

if isempty(GlobMatr.KffMT)
    FinalDofMEE = 0;
else
    FinalDofMEE=length(GlobMatr.KffMT(1,:));
end
if isempty(GlobMatr.KzzT)
    FinalDofMEE = 0;
else
    FinalDofMEE=length(GlobMatr.KzzT(1,:));
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Calculate damping matrix
if DampRatio < 0
    DampRatio = 0.8/100;
end

Mode_m = 6;

DampRatio_1 = DampRatio;
DampRatio_m = Mode_m*DampRatio_1;

Mode_max = 2.5*Mode_m;
% [GlobMatr] = SF_GetDampingMatrix(DampRatio_1,DampRatio_m,Mode_m, ...
%                                  Mode_max,GlobMatr);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Save workspace variables
if isempty(OutputFile)
   disp('::Matrices have not been stored!');
else
    %% Globle matrices
MuuT = GlobMatr.MuuT;
CuuT = GlobMatr.CuuT;
%%%%%%%%%%双向耦合可能用到的矩阵
% MutT = GlobMatr.MuuT;
% MtuT = GlobMatr.MuuT;
% MttT = GlobMatr.MuuT;
% CutT = GlobMatr.CuuT;
% CtuT = GlobMatr.CuuT;
% CttT = GlobMatr.CuuT;
%%%%%%%%%%%
KuuT = GlobMatr.KuuT;
KufMT = GlobMatr.KufMT;
KfuMT = GlobMatr.KfuMT;
KffMT = GlobMatr.KffMT;

KuzT= GlobMatr.KuzT;
KzuT= GlobMatr.KzuT;
KfzT= GlobMatr.KfzT;
KzfT= GlobMatr.KzfT;
KzzT= GlobMatr.KzzT;

KutT = GlobMatr.KutT;%hzt+
KftT = GlobMatr.KftT;
KztT = GlobMatr.KztT;
KtuT = GlobMatr.KtuT;
KtfT = GlobMatr.KtfT;
KtzT = GlobMatr.KtzT;
KttT = GlobMatr.KttT;

FuiT = GlobMatr.FuiT;
FusT = GlobMatr.FusT;
FucT = GlobMatr.FucT;

GfiMT =GlobMatr.GfiMT;
GfMT = GlobMatr.GfMT;
MzT = GlobMatr.MzT;
MziT = GlobMatr.MziT;
FtT = GlobMatr.FtT;
    %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    M_F2S = MuuT;
    C_F2S = CuuT;
    K_F2S = KuuT;
    F_F2S = FusT;

    [M,C,K,F,S] = SF_FEMtoSSM_3(M_F2S,C_F2S,K_F2S,F_F2S); 
    
    %% save file
    save(OutputFile, 'GlobMatr','FinitElemInfo','MateProp', ...
        'MuuT','CuuT','KuuT','KufMT','KfuMT','KffMT','KfzT','KzfT','KuzT','KzuT','KzzT','FusT','FucT', ...
        'M','C','K','F','S','FinalDofM','FinalDofMEE','ElemType','KutT','KftT','KztT','KttT'); 
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('::Main_FOSDLIN851T5MEEP_V4------%s\n',ShellStr);
fprintf('=====================================================\n');
fprintf('||-------------Successfully Calculated-------------||\n');ss
fprintf('%s\n',datestr(now));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end







