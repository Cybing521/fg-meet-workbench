%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Main function
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc;
clear;
addpath(genpath('../SubFunMFC'));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Difine files
InputFile = './InputFile/FGPM_CFFF.txt';
OutputFile = [];
UsedDataFile = 'LINEAR_DataUsed.txt';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Get start information
IsANS = 0;
IsDamp = 0;
Theory = 4;
ThermalNL = 0;%;0=LIN；1=NL1；2=NL2
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
[GlobMatr,FinitElemInfo,MateProp] = Main_FOSDLIN851T5MFC_V4(InputFile, ...
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
% PositionM=[729:74:1395];%theat1,四边简支，3方向，中心线一半
%PositionM=748;  %4边固支中心点3方向
PositionM=6098; %4边简支中心点3方向
% PositionM=691; %4边铰支中心点3方向
 %PositionM=710; %HSHS中心点3方向
PositionMEE =1:4000;
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
DeltaT(2,1) = 5;%top
   Voltmax=0;
   Magnetic=0;
  %PhiaMT(1:1:100)=Voltmax;
  PhiaMT(1:1:4000)=Voltmax;
%   PhiaMT(1:2:200)=-Voltmax;
   MgaT(1:1:4000)=Magnetic;
%    MgaT(1:2:200)=-Magnetic;
  %LoadMax= 2.12e7;
% LoadMax= 0;
% FueT = FusT*LoadMax;   %% surface force
 %FuaT =-KufPT*PhiaPT;
%  LoadMax =1.06e6*5;
%   FueT =FusT*LoadMax;    %% tip force
%FueT =FucT*3750;
% FumT=-KufMT*PhiaMT;
% FmmT=-KuzT*MgaT;
 FutT = -KutT*DeltaT;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Linear
%  Qd1 = KuuT\FumT;
%  Qd2 = KuuT\FmmT;
%  Qd=abs(Qd1)+abs(Qd2);
% Qd = KuuT\FueT;
%Qd = KuuT\FueT;
  %FuaT=-KufMT*PhiaMT;
   Qd = KuuT\FutT;
 %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TimePara_LIN =[0 1e-5 1.8e-3];
% K_nmk= GlobMatr.KuuT;
% F_nmk=FueT;
% TimePara = TimePara_LIN;
% UsedDataFile_NL = strcat(CaseName, '.txt');
% [XY_Value]=SF_NewmarkRefinedMEE(GlobMatr,K_nmk,F_nmk,TimePara,PositionM,PositionE,PositionMEE,QFdva,IsDamp);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%
% for i=1:10   %%在此处输入最高频率阶数
% ElemType = FinitElemInfo.ElemType;
% Node = FinitElemInfo.Node;
% DOFPerNodeM=ElemType(2);
% M = GlobMatr.MuuT;
% K = GlobMatr.KuuT;
% KufPT = GlobMatr.KufPT;
% KufMT = GlobMatr.KufMT;
% KuzT=GlobMatr.KuzT;
% KfuPT = KufPT';
% KfuMT = KufMT';
% KzuT = KuzT';
% L = chol(K,'lower');
% H = L\M/(L)';
% [EigenVector,EigenValue]=eig(full(H));
% EigenValue = sparse(EigenValue);
% EigenVector = (L')\EigenVector;
% Eigenfrequency=(1/sqrt(EigenValue(i,i)))/(2*pi);
%     frequency ={i,Eigenfrequency};
%     frequency1(i,1:2) = frequency;
% end 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 Y_DispLIN=Qd(PositionM)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% save file
%Radial
%% plot
% Y = [Y_DispNL;0];
% hfig = figure;
% %plot(XY_Value.X_Time,XY_Value.Y_Disp/0.519e-3,'-ob','markersize',5);
% % hfig2=figure(2);
% %plot((LoadNL*0.254^4)/((2.13e11)*0.012^4),Y_DispNL/0.012,'-ob','markersize',5);%机械载荷归一化
% %plot((LoadNL*0.254*(6.37e-9))/((0.012^2)*8.86),Y_DispNL/0.012,'-ob','markersize',5);  %电载荷归一化
% ylabel('Center displacement (m)');
% xlabel('Load');
% grid on;
% saveas(hfig,FileNameResFig);
