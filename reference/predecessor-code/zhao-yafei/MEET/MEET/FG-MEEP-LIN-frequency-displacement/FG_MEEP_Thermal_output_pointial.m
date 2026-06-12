%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Main function
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc;
clear;
addpath(genpath('../SubFunMFC'));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Difine files
InputFile = './InputFile/FG-MEEP-B/SSSS-FG-MEEP-U.txt';
OutputFile = [];
UsedDataFile = 'LINEAR_DataUsed.txt';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Get start information
IsANS = 0;
IsDamp = 0;
Theory = 4;
ThermalNL = 0;%;0均匀；1线性；2正弦 ;3热传导
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
CaseName = strcat('./CurrentComp/Mahesh_CCCC',StrTheory, IntegSchem);
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
%PositionM=684:5:774; %SSSS中心线3方向,沿弧长方向
%PositionM=[680,683:5:773,777];%SSSS中心线2方向,沿弧长方向
PositionM=729;
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
%    MgaT(1:2:200)=-Magnetic;
  %LoadMax= 2.12e7;
 LoadMax=0; %P=23时所加载荷为10062500，P=5时所加载荷2187500
 FueT = FusT*LoadMax;   %% surface force
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
 Qd = KuuT\FutT;
   %%%%%%%%%%%%%%%%%
 Tot_DOF_MEE = length(KffMT(:,1));
AA=[KffMT,KfzT; KzfT,KzzT];
    BB=[-KfuMT*Qd-KftT*DeltaT; -KzuT*Qd-KztT*DeltaT];
    CC=AA\BB;
    SensM_E = CC(1:Tot_DOF_MEE);
    SensM_M = CC(Tot_DOF_MEE+1:end); 
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
TimePara_LIN =[0 2e-5 1e-3];
K_nmk= GlobMatr.KuuT;
F_nmk=FutT;
TimePara = TimePara_LIN;
UsedDataFile_NL = strcat(CaseName, '.txt');
[XY_Value]=SF_NewmarkRefinedMEE(GlobMatr,K_nmk,F_nmk,TimePara,PositionM,PositionMEE,DeltaT,QFdva,IsDamp);
 %%%%%%%%%%%%%%%%  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%
X_Disp=0:0.05:1; 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Y_DispLIN=Qd(PositionM);
Y_DispLIN= XY_Value.Y_Disp;
% Y = [0;Y_DispLIN;0];
%  LoadNL = XY_Value.X_Lamda*100;
%   Y_DispNL= XY_Value.Y_Disp;
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% plot
% %%%%%%%%%计算中间11层电压值，所有层都为2,dynamic
SensMag_M12 = sum(XY_Value.Y_SensM_E(:,12:12:1200),2)/100;
SensMag_M11 = sum(XY_Value.Y_SensM_E(:,11:12:1200),2)/100;
SensMag_M10 = sum(XY_Value.Y_SensM_E(:,10:12:1200),2)/100;
SensMag_M9 = sum(XY_Value.Y_SensM_E(:,9:12:1200),2)/100;
SensMag_M8 = sum(XY_Value.Y_SensM_E(:,8:12:1200),2)/100;
SensMag_M7 = sum(XY_Value.Y_SensM_E(:,7:12:1200),2)/100;
SensMag_M6 = sum(XY_Value.Y_SensM_E(:,6:12:1200),2)/100;
SensMag_M5 = sum(XY_Value.Y_SensM_E(:,5:12:1200),2)/100; 
SensMag_M4 = sum(XY_Value.Y_SensM_E(:,4:12:1200),2)/100; 
SensMag_M3 = sum(XY_Value.Y_SensM_E(:,3:12:1200),2)/100; 
SensMag_M2 = sum(XY_Value.Y_SensM_E(:,2:12:1200),2)/100;  
SensMag_M1 = sum(XY_Value.Y_SensM_E(:,1:12:1200),2)/100;
 %%%计算每层输出电势与磁势.stasic
SensMag_M = zeros(12,1);
SensMag_M(1)=sum(SensM_M(1:12:1200))/100; %第1层输出电压平均值
SensMag_M(2)=sum(SensM_M(2:12:1200))/100; %第3层输出电压平均值
SensMag_M(3)=sum(SensM_M(3:12:1200))/100; %第3层输出电压平均值
SensMag_M(4)=sum(SensM_M(4:12:1200))/100;%第4层输出电压平均值
SensMag_M(5)=sum(SensM_M(5:12:1200))/100;%第5层输出电压平均值
SensMag_M(6)=sum(SensM_M(6:12:1200))/100; %第6层输出电压平均值
SensMag_M(7)=sum(SensM_M(7:12:1200))/100;%第7层输出电压平均值
SensMag_M(8)=sum(SensM_M(8:12:1200))/100; %第8层输出电压平均值
SensMag_M(9)=sum(SensM_M(9:12:1200))/100; %第9层输出电压平均值
SensMag_M(10)=sum(SensM_M(10:12:1200))/100; %第10层输出电压平均值
SensMag_M(11)=sum(SensM_M(11:12:1200))/100; %第11层输出电压平均值
SensMag_M(12)=sum(SensM_M(12:12:1200))/100; %第11层输出电压平均值
SensMag_M_output= struct('SensMag_M',SensMag_M);
%% save file
%  hfig2=figure;
% %plot( X_Disp,Y_DispLIN,'-ob','markersize',5);
% plot(XY_Value.X_Time,Y_DispLIN,'-ob','markersize',5);
% ylabel('Displacements (m)');
% %xlabel('\Theta^2/b');
% xlabel('Time(s)');
% grid on;
hfig = figure;
plot(XY_Value.X_Time,SensMag_M1,'-+','markersize',5); hold on;
plot(XY_Value.X_Time,SensMag_M2,'-*','markersize',5); hold on;
plot(XY_Value.X_Time,SensMag_M3,'-<','markersize',5); hold on;
plot(XY_Value.X_Time,SensMag_M4,'->','markersize',5); hold on;
plot(XY_Value.X_Time,SensMag_M5,'-x','markersize',5); hold on;
plot(XY_Value.X_Time,SensMag_M6,'-p','markersize',5); hold on;
plot(XY_Value.X_Time,SensMag_M7,'-h','markersize',5); hold on;
plot(XY_Value.X_Time,SensMag_M8,'-d','markersize',5); hold on;
plot(XY_Value.X_Time,SensMag_M9,'-s','markersize',5); hold on;
plot(XY_Value.X_Time,SensMag_M10,'-ob','markersize',5); hold on;
plot(XY_Value.X_Time,SensMag_M11,'-o','markersize',5); hold on;
plot(XY_Value.X_Time,SensMag_M12,'-.','markersize',5); 
