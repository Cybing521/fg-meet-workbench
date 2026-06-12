%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Main function
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc;
clear;
addpath(genpath('../SubFunMFC'));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Difine files
InputFile = './InputFile/MEE_CFFF_MEEP.txt';
OutputFile = [];
UsedDataFile = 'LINEAR_DataUsed.txt';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Get start information
IsANS = 0;
IsDamp = 0;
Theory = 4;
ThermalNL =1;%;0均匀；1线性；2正弦 ;3热传导
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
CaseName = strcat('./CurrentComp/Sladek_CCCC_MEE_test',StrTheory, IntegSchem);
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
 PositionM=603;
 PositionMEE =1:960;
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
DeltaT(2,1) = 30;%top
FueT =FucT*0;
FmmT=-KutT*DeltaT; 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Linear
Qd = KuuT\FmmT;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%
% Lamda= 0:0.04:1;
% [XY_Value,QFdva] = Main_StaticNL851T5T56MEEP_NR_V41(InputFile, ...
%     UsedDataFile_NL,PositionM,PositionMEE,FueT,PhiaMT,MgaT,DeltaT,...
% QFdva,IsANS,Theory,ErrorMax,Lamda,IntegSchem,ThermalNL); 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 Y_DispLIN_LRT=Qd(PositionM);
%  Y_DispNL_LRT = XY_Value.Y_Disp;
%  LoadNL = XY_Value.X_Lamda*DeltaT(2,1);
% %  X_Disp=[0.05:0.05:0.95];
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %% save file
% save(FileNameRes,'RunPara','Y_DispLIN_LRT','Qd');
% %Radial
% %% plot
% % X_Disp,
% hfig = figure;
% plot(LoadNL,Y_DispNL_LRT,'-ob','markersize',5);
% ylabel('Center displacement-LTR (m)');
% xlabel('Load');
% % grid on;
% saveas(hfig,FileNameResFig);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% InputFile = './InputFile/MEE_CFFF_MEEP.txt';
% OutputFile = [];
% UsedDataFile = 'LINEAR_DataUsed.txt';
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %% Get start information
% InputFile = './InputFile/MEE_CFFF_MEEP.txt';
% OutputFile = [];
% UsedDataFile = 'LINEAR_DataUsed.txt';
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %% Get start information
% IsANS = 0;
% IsDamp = 0;
% Theory = 1;
% ThermalNL =1;%;0均匀；1线性；2正弦 ;3热传导
% %% Damping ratio
% DampRatio = 0.8/100;
% IntegSchem = 'G2';
% 
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
% CaseName = strcat('./CurrentComp/Sladek_CCCC_MEE_test',StrTheory, IntegSchem);
% FileNameRes = strcat(CaseName, '.mat');
% FileNameResFig = strcat(CaseName, '.fig');
% UsedDataFile_NL = strcat(CaseName, '.txt');
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%
% RunPara = struct('IsANS',IsANS,'IsDamp',IsDamp,'Theory',Theory, ...
%                  'IntegSchem',IntegSchem,'DampRatio',DampRatio);
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %% Linear FE computation
% [GlobMatr,FinitElemInfo,MateProp] = Main_FOSDLIN851T5MEEP_V4(InputFile, ...
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
% if isempty(GlobMatr.KzzT)
%     FinalDofMEE = 0;
% else
%     FinalDofMEE=length(GlobMatr.KzzT(1,:));
% end
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %% IMPORTANT SETINGS
% %% Initiation 
%  PositionM=603;
%  PositionMEE =1:960;
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
% DeltaT(2,1) = 300;%top
% FueT =FucT*0;
% FmmT=-KutT*DeltaT; 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %% Linear
% Qd = KuuT\FmmT;
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%%%%%RWR
% % DLamda0 = 0.04;
% % IsConstantArc = 1;
% % [XY_Value,QFdva] = Main_StaticNL851T5T56MEEP_RWR_V4(InputFile, ...
% %     UsedDataFile_NL,PositionM,PositionMEE,FueT,PhiaMT,MgaT,DeltaT,QFdva, ...
% %     IsANS,Theory,ErrorMax,DLamda0,IsConstantArc,IntegSchem,ThermalNL);
% %%%%%%%%%%%%%%%%%%%
% Lamda= 0:0.04:1;
% [XY_Value,QFdva] = Main_StaticNL851T5T56MEEP_NR_V41(InputFile, ...
%     UsedDataFile_NL,PositionM,PositionMEE,FueT,PhiaMT,MgaT,DeltaT,...
% QFdva,IsANS,Theory,ErrorMax,Lamda,IntegSchem,ThermalNL); 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%%%%%%%%%%%%%%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Y_DispLIN_RVK=Qd(PositionM);
%  Y_DispNL_RVK = XY_Value.Y_Disp;
%  LoadNL = XY_Value.X_Lamda*DeltaT(2,1);
% %  X_Disp=[0.05:0.05:0.95];
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %% save file
% save(FileNameRes,'RunPara','Y_DispLIN_RVK','Qd');
% %Radial
% %% plot
% % X_Disp,
% hfig = figure;
% plot(LoadNL,Y_DispNL_RVK,'-ob','markersize',5);
% ylabel('Center displacement_RVK (m)');
% xlabel('Load');
% % grid on;
% saveas(hfig,FileNameResFig);