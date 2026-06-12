%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Main function
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc;
clear;
addpath(genpath('../SubFunMFC'));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Difine files
InputFile = './InputFile/FG-MEEP-B/SSSS-FG-MEEP-X.txt';
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
CaseName = strcat('./CurrentComp/FG-U-UTR-dynamic',StrTheory, IntegSchem);
FileNameRes = strcat(CaseName, '.mat');
FileNameResFig = strcat(CaseName, '.fig');
UsedDataFile_NL = strcat(CaseName, '.txt');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
RunPara = struct('IsANS',IsANS,'IsDamp',IsDamp,'Theory',Theory, ...
                 'IntegSchem',IntegSchem,'DampRatio',DampRatio);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Linear FE computation
 [GlobMatr,FinitElemInfo,MateProp] =Main_FOSDLIN851T5MEEP_V4(InputFile, ...
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
DeltaT(2,1) =300;%top
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
   %%%%%%%%%%%%%%%%%
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
TimePara_LIN =[0 2e-5 2e-3];
K_nmk= GlobMatr.KuuT;
F_nmk=FutT;
TimePara = TimePara_LIN;
UsedDataFile_NL = strcat(CaseName, '.txt');
[XY_Value]=SF_NewmarkRefinedMEEP(GlobMatr,K_nmk,F_nmk, ...
                                 TimePara,PositionM,PositionMEE,DeltaT,QFdva,IsDamp);
 %%%%%%%%%%%%%%%%  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%
X_Disp=0:0.05:1; 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
FG_U_UTR_dynamic= XY_Value.Y_Disp;
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% save file
 hfig2=figure;
plot(XY_Value.X_Time,FG_U_UTR_dynamic,'-ob','markersize',5);
ylabel('Displacements (m)');
xlabel('Time(s)');
legend('FG-U-UTR-dynamic');
grid on;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
InputFile = './InputFile/FG-MEEP-B/SSSS-FG-MEEP-X.txt';
OutputFile = [];
UsedDataFile = 'LINEAR_DataUsed.txt';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Get start information
IsANS = 0;
IsDamp = 0;
Theory = 4;
ThermalNL = 1;%;0均匀；1线性；2正弦 ;3热传导
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
CaseName = strcat('./CurrentComp/FG-U-LTR-dynamic',StrTheory, IntegSchem);
FileNameRes = strcat(CaseName, '.mat');
FileNameResFig = strcat(CaseName, '.fig');
UsedDataFile_NL = strcat(CaseName, '.txt');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
RunPara = struct('IsANS',IsANS,'IsDamp',IsDamp,'Theory',Theory, ...
                 'IntegSchem',IntegSchem,'DampRatio',DampRatio);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Linear FE computation
 [GlobMatr,FinitElemInfo,MateProp] =Main_FOSDLIN851T5MEEP_V4(InputFile, ...
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
DeltaT(2,1) =300;%top
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
   %%%%%%%%%%%%%%%%%
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
TimePara_LIN =[0 2e-5 2e-3];
K_nmk= GlobMatr.KuuT;
F_nmk=FutT;
TimePara = TimePara_LIN;
UsedDataFile_NL = strcat(CaseName, '.txt');
[XY_Value]=SF_NewmarkRefinedMEEP(GlobMatr,K_nmk,F_nmk, ...
                                 TimePara,PositionM,PositionMEE,DeltaT,QFdva,IsDamp);
 %%%%%%%%%%%%%%%%  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%
X_Disp=0:0.05:1; 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
FG_U_LTR_dynamic= XY_Value.Y_Disp;
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% save file
 hfig2=figure;
plot(XY_Value.X_Time,FG_U_LTR_dynamic,'-ob','markersize',5);
ylabel('Displacements (m)');
xlabel('Time(s)');
legend('FG-U-LTR-dynamic');
grid on;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
InputFile = './InputFile/FG-MEEP-B/SSSS-FG-MEEP-X.txt';
OutputFile = [];
UsedDataFile = 'LINEAR_DataUsed.txt';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Get start information
IsANS = 0;
IsDamp = 0;
Theory = 4;
ThermalNL = 2;%;0均匀；1线性；2正弦 ;3热传导
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
CaseName = strcat('./CurrentComp/FG-U-STR-dynamic',StrTheory, IntegSchem);
FileNameRes = strcat(CaseName, '.mat');
FileNameResFig = strcat(CaseName, '.fig');
UsedDataFile_NL = strcat(CaseName, '.txt');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
RunPara = struct('IsANS',IsANS,'IsDamp',IsDamp,'Theory',Theory, ...
                 'IntegSchem',IntegSchem,'DampRatio',DampRatio);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Linear FE computation
 [GlobMatr,FinitElemInfo,MateProp] =Main_FOSDLIN851T5MEEP_V4(InputFile, ...
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
DeltaT(2,1) =300;%top
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
   %%%%%%%%%%%%%%%%%
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
TimePara_LIN =[0 2e-5 2e-3];
K_nmk= GlobMatr.KuuT;
F_nmk=FutT;
TimePara = TimePara_LIN;
UsedDataFile_NL = strcat(CaseName, '.txt');
[XY_Value]=SF_NewmarkRefinedMEEP(GlobMatr,K_nmk,F_nmk, ...
                                 TimePara,PositionM,PositionMEE,DeltaT,QFdva,IsDamp);
 %%%%%%%%%%%%%%%%  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%
X_Disp=0:0.05:1; 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
FG_U_STR_dynamic= XY_Value.Y_Disp;
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% save file
 hfig2=figure;
plot(XY_Value.X_Time,FG_U_STR_dynamic,'-ob','markersize',5);
ylabel('Displacements (m)');
xlabel('Time(s)');
legend('FG-U-STR-dynamic');
grid on;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
InputFile = './InputFile/FG-MEEP-B/SSSS-FG-MEEP-X.txt';
OutputFile = [];
UsedDataFile = 'LINEAR_DataUsed.txt';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Get start information
IsANS = 0;
IsDamp = 0;
Theory = 4;
ThermalNL = 3;%;0均匀；1线性；2正弦 ;3热传导
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
CaseName = strcat('./CurrentComp/FG-U-HC-dynamic',StrTheory, IntegSchem);
FileNameRes = strcat(CaseName, '.mat');
FileNameResFig = strcat(CaseName, '.fig');
UsedDataFile_NL = strcat(CaseName, '.txt');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
RunPara = struct('IsANS',IsANS,'IsDamp',IsDamp,'Theory',Theory, ...
                 'IntegSchem',IntegSchem,'DampRatio',DampRatio);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Linear FE computation
 [GlobMatr,FinitElemInfo,MateProp] =Main_FOSDLIN851T5MEEP_V4(InputFile, ...
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
DeltaT(2,1) =300;%top
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
   %%%%%%%%%%%%%%%%%
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
TimePara_LIN =[0 2e-5 2e-3];
K_nmk= GlobMatr.KuuT;
F_nmk=FutT;
TimePara = TimePara_LIN;
UsedDataFile_NL = strcat(CaseName, '.txt');
[XY_Value]=SF_NewmarkRefinedMEEP(GlobMatr,K_nmk,F_nmk, ...
                                 TimePara,PositionM,PositionMEE,DeltaT,QFdva,IsDamp);
 %%%%%%%%%%%%%%%%  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%
X_Disp=0:0.05:1; 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
FG_U_HC_dynamic= XY_Value.Y_Disp;
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% save file
 hfig2=figure;
plot(XY_Value.X_Time,FG_U_HC_dynamic,'-ob','markersize',5);
ylabel('Displacements (m)');
xlabel('Time(s)');
legend('FG-U-HC-dynamic');
grid on;