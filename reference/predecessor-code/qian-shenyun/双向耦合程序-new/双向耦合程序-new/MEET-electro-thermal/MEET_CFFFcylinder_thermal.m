%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Main function 
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc;
clear;
addpath(genpath('../SubFunMFC'));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Difine files
InputFile = './InputFile/Thermal_CFFFcylinder_0.6Vf-30x30-10layer.txt';
OutputFile = [];
UsedDataFile = 'LINEAR_DataUsed.txt';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Get start information
IsANS = 0;
IsDamp = 0;
Theory = 4;     %非线性理论
ThermalNL = 0;%;0均匀；1线性；2正弦 ;3热传导   %温度类型
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
CaseName = strcat('./CurrentComp/MEET_CFFF',StrTheory, IntegSchem);
FileNameRes = strcat(CaseName, '.mat');
FileNameResFig = strcat(CaseName, '.fig');
UsedDataFile_NL = strcat(CaseName, '.txt');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
RunPara = struct('IsANS',IsANS,'IsDamp',IsDamp,'Theory',Theory, ...
                 'IntegSchem',IntegSchem,'DampRatio',DampRatio);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Linear FE computation
[GlobMatr,FinitElemInfo,MateProp] = Main_FOSDLIN851T5MEET_V4(InputFile, ...
                        OutputFile,UsedDataFile,IsANS,DampRatio,IntegSchem,ThermalNL);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Get needed value from linear calculation
KuuT = GlobMatr.KuuT;       %u弹性刚度矩阵
KufMT = GlobMatr.KufMT;     %f电弹刚度矩阵
KfuMT = GlobMatr.KfuMT;    
KffMT = GlobMatr.KffMT;
KfzT=GlobMatr.KfzT;
KzfT=GlobMatr.KzfT;
KuzT=GlobMatr.KuzT;         %z磁弹刚度矩阵
KzuT=GlobMatr.KzuT;
KzzT=GlobMatr.KzzT;
KutT = GlobMatr.KutT;       %t热弹刚度矩阵
KftT = GlobMatr.KftT;
KztT = GlobMatr.KztT;
KtuT = GlobMatr.KtuT;
KtfT = GlobMatr.KtfT;
KtzT = GlobMatr.KtzT;
KttT = GlobMatr.KttT;
FucT = GlobMatr.FucT;      %Calculated by linear program
FusT = GlobMatr.FusT;
%% Get final  mechanical and electrical dof
FinalDofM = length(GlobMatr.KuuT(1,:));

if isempty(GlobMatr.KzzT)
    FinalDofMEE = 0;
else
    FinalDofMEE=length(GlobMatr.KzzT(1,:));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %% 网格划分20X20X10
% %% IMPORTANT SETINGS
% %% Initiation 
% PositionMx=98:150:6098;   %CFFF单边固支圆柱壳，半径400mm，直边200mm，厚度为2.4mm，网格20X20，y=0.1m时中心线
% PositionMy=3003:5:3198;   %CFFF单边固支圆柱壳，半径400mm，直边200mm，厚度为2.4mm，网格20X20，x=0.1m时中心线
% PositionMEE =1:4000;
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
% DelT=zeros(FinalDofMEE,1);
% %%%%%%%%%%
% Loadmax = -2000;
% Voltmax = 0;
% Magnetic = 0;
% %划分10层  网格20X20 
%    PhiaMT(10:10:4000) = -Voltmax;
%    PhiaMT(1:10:4000) = Voltmax;
%    MgaT(10:10:4000) = -Magnetic;
%    MgaT(1:10:4000) = Magnetic; 
% %%%%%%%%%%
% FueT = FusT*Loadmax;
% FuaT = -KufMT*PhiaMT;
% FumT = -KuzT*MgaT;
% FutT = -KutT*DelT;
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %% Linear
% %先计算位移再计算温差
% % Qd = KuuT\FueT;  
% % Tot_DOF_MEET = length(KttT(:,1));
% % AA = KttT;
% % BB = -KtuT*Qd;
% % CC = AA\BB;
% % SensM_T = CC(1:Tot_DOF_MEET);
% %由压电方程计算温差
% % FuaT=zeros(8000,1);
% %     Tot_DOF_MEET = length(KuuT(:,1));
% %     AA=[KuuT,KufMT; KfuMT,KffMT];
% %     BB=[FueT; FuaT];
% %     CC=AA\BB;
% %     Qd = CC(1:Tot_DOF_MEET);
% %     SensM_T = CC(Tot_DOF_MEET+1:end); 
% %由热弹性本构方程计算温差
% FutT=zeros(4000,1);
%     Tot_DOF_MEET = length(KuuT(:,1));
%     AA=[KuuT,KutT; KtuT,KttT];
%     BB=[FueT; FutT];
%     CC=AA\BB;
%     Qd = CC(1:Tot_DOF_MEET);
%     SensM_T = CC(Tot_DOF_MEET+1:end);     
% %200mm*200mm*2.4mm圆柱壳
% X_Disp=0:0.005:0.2; 
% X_Disp1=0:0.005:0.2; 
% %CFFF单边固支y=0.1m以及x=0.1m的z向位移
% Y_DispLIN1=1000*Qd(PositionMx);
% Y_DispLIN2=1000*Qd(PositionMy);
%  Y1 = [Y_DispLIN1];
%  Y2 = [0;Y_DispLIN2];
% % 分别绘制x和y方向中心线的图
% % 创建一个图形窗口并使用子图
% figure;
% % 绘制y=0.1m时沿x方向的中心线位移
% subplot(2, 1, 1);
% plot(X_Disp, Y1, '-ob', 'markersize', 5);
% ylabel('Centerline Displacement (mm)');
% xlabel('x-Distance');
% title('y=0.1m along X-axis z-Displacement');
% grid on;
% % 绘制x=0.1m时沿x方向的中心线位移
% subplot(2, 1, 2);
% plot(X_Disp1, Y2, '-ob', 'markersize', 5);
% ylabel('Centerline Displacement (mm)');
% xlabel('y-Distance');
% title('x=0.1m along Y-axis z-Displacement');
% grid on;
% %输出前十阶频率
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
%     frequency_CFFF20x20(i,1:2) = frequency;
% end 
% %% 网格划分10X10X10
% %% IMPORTANT SETINGS
% %% Initiation 
% PositionMx=48:75:1548;   %CFFF单边固支圆柱壳，半径400mm，直边200mm，厚度为2.4mm，网格20X20，y=0.1m时中心线
% PositionMy=753:5:848;   %CFFF单边固支圆柱壳，半径400mm，直边200mm，厚度为2.4mm，网格20X20，x=0.1m时中心线
% PositionMEE =1:1000;
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
% DelT=zeros(FinalDofMEE,1);
% %%%%%%%%%%
% Loadmax = -2000;
% Voltmax = 0;
% Magnetic = 0;
% %划分10层  网格10X10 
%    PhiaMT(10:10:1000) = -Voltmax;
%    PhiaMT(1:10:1000) = Voltmax;
%    MgaT(10:10:1000) = -Magnetic;
%    MgaT(1:10:1000) = Magnetic; 
% %%%%%%%%%%
% FueT = FusT*Loadmax;
% FuaT = -KufMT*PhiaMT;
% FumT = -KuzT*MgaT;
% FutT = -KutT*DelT;
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %% Linear
% %先计算位移再计算温差
% % Qd = KuuT\FueT;  
% % Tot_DOF_MEET = length(KttT(:,1));
% % AA = KttT;
% % BB = -KtuT*Qd;
% % CC = AA\BB;
% % SensM_T = CC(1:Tot_DOF_MEET);
% %由压电方程计算温差
% % FuaT=zeros(8000,1);
% %     Tot_DOF_MEET = length(KuuT(:,1));
% %     AA=[KuuT,KufMT; KfuMT,KffMT];
% %     BB=[FueT; FuaT];
% %     CC=AA\BB;
% %     Qd = CC(1:Tot_DOF_MEET);
% %     SensM_T = CC(Tot_DOF_MEET+1:end); 
% %由热弹性本构方程计算温差
% FutT=zeros(1000,1);
%     Tot_DOF_MEET = length(KuuT(:,1));
%     AA=[KuuT,KutT; KtuT,KttT];
%     BB=[FueT; FutT];
%     CC=AA\BB;
%     Qd = CC(1:Tot_DOF_MEET);
%     SensM_T = CC(Tot_DOF_MEET+1:end);     
% %200mm*200mm*2.4mm圆柱壳
% X_Disp=0:0.01:0.2; 
% X_Disp1=0:0.01:0.2; 
% %CFFF单边固支y=0.1m以及x=0.1m的z向位移
% Y_DispLIN1=1000*Qd(PositionMx);
% Y_DispLIN2=1000*Qd(PositionMy);
%  Y1 = [Y_DispLIN1];
%  Y2 = [0;Y_DispLIN2];
% % 分别绘制x和y方向中心线的图
% % 创建一个图形窗口并使用子图
% figure;
% % 绘制y=0.1m时沿x方向的中心线位移
% subplot(2, 1, 1);
% plot(X_Disp, Y1, '-ob', 'markersize', 5);
% ylabel('Centerline Displacement (mm)');
% xlabel('x-Distance');
% title('y=0.1m along X-axis z-Displacement');
% grid on;
% % 绘制x=0.1m时沿x方向的中心线位移
% subplot(2, 1, 2);
% plot(X_Disp1, Y2, '-ob', 'markersize', 5);
% ylabel('Centerline Displacement (mm)');
% xlabel('y-Distance');
% title('x=0.1m along Y-axis z-Displacement');
% grid on;
%% 网格划分30X30X10
%% IMPORTANT SETINGS
%% Initiation 
PositionMx=148:225:13648;   %CFFF单边固支圆柱壳，半径600mm，直边300mm，厚度为6mm，网格30X30，y=0.15m时中心线
% PositionMx=6752:5:7047;   %CFFF单边固支圆柱壳，半径600mm，直边300mm，厚度为6mm，网格30X30，x=0.15m时中心线环向位移
PositionMy=6753:5:7048;   %CFFF单边固支圆柱壳，半径600mm，直边300mm，厚度为6mm，网格30X30，x=0.15m时中心线径向位移
PositionMEE =1:9000;
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
DelT=zeros(FinalDofMEE,1);
%%%%%%%%%%
Loadmax = 0;
Voltmax = 4800;
Magnetic = 0;
%划分10层  网格30X30 
   PhiaMT(10:10:9000) = Voltmax;
   PhiaMT(1:10:9000) = -Voltmax;
   MgaT(10:10:9000) = -Magnetic;
   MgaT(1:10:9000) = Magnetic; 
%%%%%%%%%%
FueT = FusT*Loadmax;
FuaT = -KufMT*PhiaMT;
FumT = -KuzT*MgaT;
FutT = -KutT*DelT;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Linear
% % 先计算位移再计算温差
% Qd = KuuT\FueT;  
% Tot_DOF_MEET = length(KttT(:,1));
% AA = KttT;
% BB = -KtuT*Qd;
% CC = AA\BB;
% SensM_T = CC(1:Tot_DOF_MEET);
%由压电方程计算温差
% FuaT=zeros(8000,1);
%     Tot_DOF_MEET = length(KuuT(:,1));
%     AA=[KuuT,KufMT; KfuMT,KffMT];
%     BB=[FueT; FuaT];
%     CC=AA\BB;
%     Qd = CC(1:Tot_DOF_MEET);
%     SensM_T = CC(Tot_DOF_MEET+1:end); 
%由热弹性本构方程计算温差
    FutT=zeros(9000,1);
    Tot_DOF_MEET = length(KuuT(:,1));
    AA=[KuuT,KutT; KtuT,KttT];
    BB=[FuaT; FutT];
    CC=AA\BB;
    Qd = CC(1:Tot_DOF_MEET);
    SensM_T = CC(Tot_DOF_MEET+1:end);
%300mm*300mm*6mm圆柱壳
X_Disp=0:0.005:0.3; 
X_Disp1=0:0.005:0.3; 
%CFFF单边固支y=0.15m以及x=0.15m的z向位移
Y_DispLIN1=1000*Qd(PositionMx);
Y_DispLIN2=1000*Qd(PositionMy);
 Y1 = [Y_DispLIN1];
 Y2 = [0;Y_DispLIN2];
% 分别绘制x和y方向中心线的图
% 创建一个图形窗口并使用子图
figure;
% 绘制y=0.15m时沿x方向的中心线位移
subplot(2, 1, 1);
plot(X_Disp, Y1, '-ob', 'markersize', 5);
ylabel('Centerline Displacement (mm)');
xlabel('x-Distance');
title('y=0.15m along X-axis z-Displacement');
grid on;
% 绘制x=0.15m时沿x方向的中心线位移
subplot(2, 1, 2);
plot(X_Disp1, Y2, '-ob', 'markersize', 5);
ylabel('Centerline Displacement (mm)');
xlabel('y-Distance');
title('x=0.15m along Y-axis z-Displacement');
grid on;
SensTem_T = zeros(10,1);
SensTem_T(1)=sum(SensM_T(1:10:9000))/900; %第1层输出电压平均值
SensTem_T(2)=sum(SensM_T(2:10:9000))/900; %第3层输出电压平均值
SensTem_T(3)=sum(SensM_T(3:10:9000))/900; %第3层输出电压平均值
SensTem_T(4)=sum(SensM_T(4:10:9000))/900;%第4层输出电压平均值
SensTem_T(5)=sum(SensM_T(5:10:9000))/900;%第5层输出电压平均值
SensTem_T(6)=sum(SensM_T(6:10:9000))/900; %第6层输出电压平均值
SensTem_T(7)=sum(SensM_T(7:10:9000))/900;%第7层输出电压平均值
SensTem_T(8)=sum(SensM_T(8:10:9000))/900; %第8层输出电压平均值
SensTem_T(9)=sum(SensM_T(9:10:9000))/900; %第9层输出电压平均值
SensTem_T(10)=sum(SensM_T(10:10:9000))/900; %第10层输出电压平均值
% %% 网格划分15X15X20
% %% IMPORTANT SETINGS
% %% Initiation 
% PositionMx=73:225:3448;   %CFFF单边固支圆柱壳，半径600mm，直边300mm，厚度为6mm，网格15X15，y=0.15m时中心线
% % PositionMx=6752:5:7047;   %CFFF单边固支圆柱壳，半径600mm，直边300mm，厚度为6mm，网格15X15，x=0.15m时中心线环向位移
% PositionMy=1728:5:1798;   %CFFF单边固支圆柱壳，半径600mm，直边300mm，厚度为6mm，网格15X15，x=0.15m时中心线径向位移
% PositionMEE =1:2250;
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
% DelT=zeros(FinalDofMEE,1);
% %%%%%%%%%%
% Loadmax = -16000;
% Voltmax = 0;
% Magnetic = 0;
% %划分10层  网格15X15 
%    PhiaMT(10:10:2250) = -Voltmax;
%    PhiaMT(1:10:2250) = Voltmax;
%    MgaT(10:10:2250) = -Magnetic;
%    MgaT(1:10:2250) = Magnetic; 
% % %划分20层  网格15X15 
% %    PhiaMT(20:20:4500) = -Voltmax;
% %    PhiaMT(1:20:4500) = Voltmax;
% %    MgaT(20:20:4500) = -Magnetic;
% %    MgaT(1:20:4500) = Magnetic; 
% %%%%%%%%%%
% FueT = FusT*Loadmax;
% FuaT = -KufMT*PhiaMT;
% FumT = -KuzT*MgaT;
% FutT = -KutT*DelT;
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %% Linear
% % % 先计算位移再计算温差
% % Qd = KuuT\FueT;  
% % Tot_DOF_MEET = length(KttT(:,1));
% % AA = KttT;
% % BB = -KtuT*Qd;
% % CC = AA\BB;
% % SensM_T = CC(1:Tot_DOF_MEET);
% %由压电方程计算温差
% % FuaT=zeros(8000,1);
% %     Tot_DOF_MEET = length(KuuT(:,1));
% %     AA=[KuuT,KufMT; KfuMT,KffMT];
% %     BB=[FueT; FuaT];
% %     CC=AA\BB;
% %     Qd = CC(1:Tot_DOF_MEET);
% %     SensM_T = CC(Tot_DOF_MEET+1:end); 
% %由热弹性本构方程计算温差
% FutT=zeros(2250,1);
%     Tot_DOF_MEET = length(KuuT(:,1));
%     AA=[KuuT,KutT; KtuT,KttT];
%     BB=[FueT; FutT];
%     CC=AA\BB;
%     Qd = CC(1:Tot_DOF_MEET);
%     SensM_T = CC(Tot_DOF_MEET+1:end);     
% %300mm*300mm*6mm圆柱壳
% X_Disp=0:0.02:0.3; 
% X_Disp1=0:0.02:0.3; 
% %CFFF单边固支y=0.15m以及x=0.15m的z向位移
% Y_DispLIN1=1000*Qd(PositionMx);
% Y_DispLIN2=1000*Qd(PositionMy);
%  Y1 = [Y_DispLIN1];
%  Y2 = [0;Y_DispLIN2];
% % 分别绘制x和y方向中心线的图
% % 创建一个图形窗口并使用子图
% figure;
% % 绘制y=0.15m时沿x方向的中心线位移
% subplot(2, 1, 1);
% plot(X_Disp, Y1, '-ob', 'markersize', 5);
% ylabel('Centerline Displacement (mm)');
% xlabel('x-Distance');
% title('y=0.15m along X-axis z-Displacement');
% grid on;
% % 绘制x=0.15m时沿x方向的中心线位移
% subplot(2, 1, 2);
% plot(X_Disp1, Y2, '-ob', 'markersize', 5);
% ylabel('Centerline Displacement (mm)');
% xlabel('y-Distance');
% title('x=0.15m along Y-axis z-Displacement');
% grid on;
% %% 网格划分20X20X10
% %% IMPORTANT SETINGS
% %% Initiation 
% PositionMx=98:150:6098;   %CFFF单边固支圆柱壳，半径600mm，直边300mm，厚度为6mm，网格30X30，y=0.15m时中心线
% PositionMy=3003:5:3198;   %CFFF单边固支圆柱壳，半径600mm，直边300mm，厚度为6mm，网格30X30，x=0.15m时中心线
% PositionMEE =1:4000;
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
% DelT=zeros(FinalDofMEE,1);
% %%%%%%%%%%
% Loadmax = -16000;
% Voltmax = 0;
% Magnetic = 0;
% %划分10层  网格20X20 
%    PhiaMT(10:10:4000) = -Voltmax;
%    PhiaMT(1:10:4000) = Voltmax;
%    MgaT(10:10:4000) = -Magnetic;
%    MgaT(1:10:4000) = Magnetic; 
% %%%%%%%%%%
% FueT = FusT*Loadmax;
% FuaT = -KufMT*PhiaMT;
% FumT = -KuzT*MgaT;
% FutT = -KutT*DelT;
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %% Linear
% % % 先计算位移再计算温差
% % Qd = KuuT\FueT;  
% % Tot_DOF_MEET = length(KttT(:,1));
% % AA = KttT;
% % BB = -KtuT*Qd;
% % CC = AA\BB;
% % SensM_T = CC(1:Tot_DOF_MEET);
% %由压电方程计算温差
% % FuaT=zeros(8000,1);
% %     Tot_DOF_MEET = length(KuuT(:,1));
% %     AA=[KuuT,KufMT; KfuMT,KffMT];
% %     BB=[FueT; FuaT];
% %     CC=AA\BB;
% %     Qd = CC(1:Tot_DOF_MEET);
% %     SensM_T = CC(Tot_DOF_MEET+1:end); 
% %由热弹性本构方程计算温差
% FutT=zeros(4000,1);
%     Tot_DOF_MEET = length(KuuT(:,1));
%     AA=[KuuT,KutT; KtuT,KttT];
%     BB=[FueT; FutT];
%     CC=AA\BB;
%     Qd = CC(1:Tot_DOF_MEET);
%     SensM_T = CC(Tot_DOF_MEET+1:end);     
% %300mm*300mm*6mm圆柱壳
% X_Disp=0:0.0075:0.3; 
% X_Disp1=0:0.0075:0.3; 
% %CFFF单边固支y=0.15m以及x=0.15m的z向位移
% Y_DispLIN1=1000*Qd(PositionMx);
% Y_DispLIN2=1000*Qd(PositionMy);
%  Y1 = [Y_DispLIN1];
%  Y2 = [0;Y_DispLIN2];
% % 分别绘制x和y方向中心线的图
% % 创建一个图形窗口并使用子图
% figure;
% % 绘制y=0.15m时沿x方向的中心线位移
% subplot(2, 1, 1);
% plot(X_Disp, Y1, '-ob', 'markersize', 5);
% ylabel('Centerline Displacement (mm)');
% xlabel('x-Distance');
% title('y=0.15m along X-axis z-Displacement');
% grid on;
% % 绘制x=0.15m时沿x方向的中心线位移
% subplot(2, 1, 2);
% plot(X_Disp1, Y2, '-ob', 'markersize', 5);
% ylabel('Centerline Displacement (mm)');
% xlabel('y-Distance');
% title('x=0.15m along Y-axis z-Displacement');
% grid on;