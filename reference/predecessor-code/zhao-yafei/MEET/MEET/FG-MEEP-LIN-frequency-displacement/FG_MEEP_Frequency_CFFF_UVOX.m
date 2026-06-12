clc;
clear;
addpath(genpath('../SubFunMFC'));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% InputFile = './InputFile/FG-MEEP-F-frequency/U/CFFF-U-index-2-P-0.2.txt';
% OutputFile ='./Results/CFFF-X-index-2-P-0.2.mat';
% UsedDataFile = 'LINEAR_DataUsed.txt';
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %% Get start information
% IsANS = 0;
% IsDamp = 0;
% Theory = 4;
% ThermalNL =3;%;0均匀；1线性；2正弦 ;3热传导
% %% Damping ratio
% DampRatio = 0.8/100;
% IntegSchem = 'G2';
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %% Filename
% if Theory == 1
%     StrTheory = 'RVK5_';
% elseif Theory == 2
%     StrTheory = 'MRT5_';
% elseif Theory == 3
%     StrTheory = 'LRT5_';
% elseif Theory == 4
%     StrTheory = 'LRT56_';
% end
% 
% if IsANS == 0
%     StrANS = 'ANS0_';
% elseif IsANS == 1
%     StrANS = 'ANS1_';
% end
% 
% if IsDamp == 0
%     StrDamp = 'Damp0_';
% elseif IsDamp == 1
%     StrDamp = 'Damp1_';
% end
% CaseName = strcat('./CurrentComp/SSSS_X_index_2_P_02',StrTheory, IntegSchem);
% FileNameRes = strcat(CaseName, '.mat');
% FileNameResFig = strcat(CaseName, '.fig');
% UsedDataFile_NL = strcat(CaseName, '.txt');
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%
% RunPara = struct('IsANS',IsANS,'IsDamp',IsDamp,'Theory',Theory, ...
%                  'IntegSchem',IntegSchem,'DampRatio',DampRatio);
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %% Linear FE computation
%  [GlobMatr,FinitElemInfo,MateProp] = Main_FOSDLIN851T5MEEP_V4(InputFile, ...
%                         OutputFile,UsedDataFile,IsANS,DampRatio,IntegSchem,ThermalNL);
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %% Get needed value from linear calculation
% KuuT = GlobMatr.KuuT;
% KufMT = GlobMatr.KufMT;
% KfuMT = GlobMatr.KfuMT;
% KffMT = GlobMatr.KffMT;
% KfzT=GlobMatr.KfzT;
% KzfT=GlobMatr.KzfT;
% KuzT=GlobMatr.KuzT;
% KzuT=GlobMatr.KzuT;
% KzzT=GlobMatr.KzzT;
% KutT = GlobMatr.KutT;%hzt+
% KftT = GlobMatr.KftT;
% KztT = GlobMatr.KztT;
% KtuT = GlobMatr.KtuT;
% KtfT = GlobMatr.KtfT;
% KtzT = GlobMatr.KtzT;
% FucT = GlobMatr.FucT;     %%% Calculated by linear program
% FusT = GlobMatr.FusT;
% %% Get final  mechanical and electrical dof
% FinalDofM = length(GlobMatr.KuuT(1,:));
% 
% if isempty(GlobMatr.KzzT)
%     FinalDofMEE = 0;
% else
%     FinalDofMEE=length(GlobMatr.KzzT(1,:));
% end
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %% IMPORTANT SETINGS
% %% Initiation 
% %PositionM=684:5:774; %SSSS中心线3方向,沿弧长方向
% PositionM=[680,683:5:773,777];%SSSS中心线2方向,沿弧长方向
% %PositionM=729;
% PositionMEE =1:1200;
% %%%%%
% Qd = zeros(FinalDofM,1);
% Qv = zeros(FinalDofM,1);
% Qa = zeros(FinalDofM,1);
% PhiaM = zeros(FinalDofMEE,1);
% PhisM = zeros(FinalDofMEE,1);
% Mga=zeros(FinalDofMEE,1);
% Mgs=zeros(FinalDofMEE,1);
% QFdva = struct('Qd',Qd,'Qv',Qv,'Qa',Qa,'PhiaM',PhiaM,'PhisM',PhisM,'Mga',Mga,'Mgs',Mgs);
% %%%%%
% ErrorMax = 1E-8;
% PhiaMT = zeros(FinalDofMEE,1);
% MgaT=zeros(FinalDofMEE,1);
% DeltaT = zeros(2,1);
% DeltaT(1,1) = 0;%bottom
% DeltaT(2,1) =100;%top
%    Voltmax=0;
%    Magnetic=0;
%   %PhiaMT(1:1:100)=Voltmax;
%   PhiaMT(1:1:1200)=Voltmax;
% %   PhiaMT(1:2:200)=-Voltmax;
%    MgaT(1:1:1200)=Magnetic;
%  LoadMax=0; %P=23时所加载荷为10062500，P=5时所加载荷2187500
%  FueT = FusT*LoadMax;   %% surface force
%  FutT = -KutT*DeltaT;
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %% Linear
%  Qd = KuuT\FutT;
%  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  %%%%%%%%%%%%%%%%
% for i=1:10   %%在此处输入最高频率阶数
% ElemType = FinitElemInfo.ElemType;
% Node = FinitElemInfo.Node;
% DOFPerNodeM=ElemType(2);
% M = GlobMatr.MuuT;
% K = GlobMatr.KuuT;
% L = chol(K,'lower');
% H = L\M/(L)';
% [EigenVector,EigenValue]=eig(full(H));
% EigenValue = sparse(EigenValue);
% EigenVector = (L')\EigenVector;
% Eigenfrequency=(1/sqrt(EigenValue(i,i)))/(2*pi);
%     frequency ={i,Eigenfrequency};
%     frequency_X_index_2_P_02(i,1:2) = frequency;
% end    
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%%%%%%%%%%%%%%
% X_Disp=0:0.05:1; 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Y_DispLIN=Qd(PositionM);
% %%%%%%%%%%%%%%%%%%%%%%%%%%
% %% save file
% save(FileNameRes,'frequency_X_index_2_P_02');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%
InputFile = './InputFile/FG-MEEP-F-frequency/V/CFFF-V-index-2-P-0.2.txt';
OutputFile ='./Results/CFFF-V-index-2-P-0.2.mat';
UsedDataFile = 'LINEAR_DataUsed.txt';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Get start information
IsANS = 0;
IsDamp = 0;
Theory = 4;
ThermalNL =3;%;0均匀；1线性；2正弦 ;3热传导
%% Damping ratio
DampRatio = 0.8/100;
IntegSchem = 'G2';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Filename
if Theory == 1
    StrTheory = 'RVK5_';
elseif Theory == 2
    StrTheory = 'MRT5_';
elseif Theory == 3
    StrTheory = 'LRT5_';
elseif Theory == 4
    StrTheory = 'LRT56_';
end

if IsANS == 0
    StrANS = 'ANS0_';
elseif IsANS == 1
    StrANS = 'ANS1_';
end

if IsDamp == 0
    StrDamp = 'Damp0_';
elseif IsDamp == 1
    StrDamp = 'Damp1_';
end
CaseName = strcat('./CurrentComp/SSSS_X_index_2_P_02',StrTheory, IntegSchem);
FileNameRes = strcat(CaseName, '.mat');
FileNameResFig = strcat(CaseName, '.fig');
UsedDataFile_NL = strcat(CaseName, '.txt');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
RunPara = struct('IsANS',IsANS,'IsDamp',IsDamp,'Theory',Theory, ...
                 'IntegSchem',IntegSchem,'DampRatio',DampRatio);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Linear FE computation
 [GlobMatr,FinitElemInfo,MateProp] = Main_FOSDLIN851T5MEEP_V4(InputFile, ...
                        OutputFile,UsedDataFile,IsANS,DampRatio,IntegSchem,ThermalNL);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Get needed value from linear calculation
KuuT = GlobMatr.KuuT;
KufMT = GlobMatr.KufMT;
KfuMT = GlobMatr.KfuMT;
KffMT = GlobMatr.KffMT;
KfzT=GlobMatr.KfzT;
KzfT=GlobMatr.KzfT;
KuzT=GlobMatr.KuzT;
KzuT=GlobMatr.KzuT;
KzzT=GlobMatr.KzzT;
KutT = GlobMatr.KutT;%hzt+
KftT = GlobMatr.KftT;
KztT = GlobMatr.KztT;
KtuT = GlobMatr.KtuT;
KtfT = GlobMatr.KtfT;
KtzT = GlobMatr.KtzT;
FucT = GlobMatr.FucT;     %%% Calculated by linear program
FusT = GlobMatr.FusT;
%% Get final  mechanical and electrical dof
FinalDofM = length(GlobMatr.KuuT(1,:));

if isempty(GlobMatr.KzzT)
    FinalDofMEE = 0;
else
    FinalDofMEE=length(GlobMatr.KzzT(1,:));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% IMPORTANT SETINGS
%% Initiation 
%PositionM=684:5:774; %SSSS中心线3方向,沿弧长方向
PositionM=[680,683:5:773,777];%SSSS中心线2方向,沿弧长方向
%PositionM=729;
PositionMEE =1:1200;
%%%%%
Qd = zeros(FinalDofM,1);
Qv = zeros(FinalDofM,1);
Qa = zeros(FinalDofM,1);
PhiaM = zeros(FinalDofMEE,1);
PhisM = zeros(FinalDofMEE,1);
Mga=zeros(FinalDofMEE,1);
Mgs=zeros(FinalDofMEE,1);
QFdva = struct('Qd',Qd,'Qv',Qv,'Qa',Qa,'PhiaM',PhiaM,'PhisM',PhisM,'Mga',Mga,'Mgs',Mgs);
%%%%%
ErrorMax = 1E-8;
PhiaMT = zeros(FinalDofMEE,1);
MgaT=zeros(FinalDofMEE,1);
DeltaT = zeros(2,1);
DeltaT(1,1) = 0;%bottom
DeltaT(2,1) =100;%top
   Voltmax=0;
   Magnetic=0;
  %PhiaMT(1:1:100)=Voltmax;
  PhiaMT(1:1:1200)=Voltmax;
%   PhiaMT(1:2:200)=-Voltmax;
   MgaT(1:1:1200)=Magnetic;
 LoadMax=0; %P=23时所加载荷为10062500，P=5时所加载荷2187500
 FueT = FusT*LoadMax;   %% surface force
 FutT = -KutT*DeltaT;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Linear
 Qd = KuuT\FutT;
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 %%%%%%%%%%%%%%%%
for i=1:10   %%在此处输入最高频率阶数
ElemType = FinitElemInfo.ElemType;
Node = FinitElemInfo.Node;
DOFPerNodeM=ElemType(2);
M = GlobMatr.MuuT;
K = GlobMatr.KuuT;
L = chol(K,'lower');
H = L\M/(L)';
[EigenVector,EigenValue]=eig(full(H));
EigenValue = sparse(EigenValue);
EigenVector = (L')\EigenVector;
Eigenfrequency=(1/sqrt(EigenValue(i,i)))/(2*pi);
    frequency ={i,Eigenfrequency};
    frequency_X_index_2_P_02(i,1:2) = frequency;
end    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%
X_Disp=0:0.05:1; 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Y_DispLIN=Qd(PositionM);
%%%%%%%%%%%%%%%%%%%%%%%%%%
%% save file
save(FileNameRes,'frequency_X_index_2_P_02');