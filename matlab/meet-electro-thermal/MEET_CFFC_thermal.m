%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Main function 
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc;
clear;
addpath(genpath('../SubFunMFC'));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Difine files
InputFile = './InputFile/Thermal_CFFCplate_0.6Vf-30x30-10layer.txt';
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
CaseName = strcat('./CurrentComp/Thermal_CFFCplate_0.6Vf-30x30-10layer',StrTheory, IntegSchem);
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %% 网格划分20X20X10
% %% IMPORTANT SETINGS
% %% Initiation 
% PositionMx=53:150:5903;   %CFFC邻边固支方板300mm*300mm*6mm，网格20X20，y=0.15m
% PositionMy=2803:5:2998;   %CFFC邻边固支方板300mm*300mm*6mm，网格20X20，x=0.15m
% % PositionMy=2898:5:3098;   %单边固支/对边固支方板300mm*300mm*6mm，网格20X20，x=0.15m
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
% Loadmax = -15000;
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
% X_Disp=0:0.0075:0.3; 
% X_Disp1=0:0.015:0.3; 
% %CFFF单边固支y=0.15m以及y=0m的z向位移
% Y_DispLIN1=1000*Qd(PositionMx);
% Y_DispLIN2=1000*Qd(PositionMy);
%  Y1 = [0;Y_DispLIN1];
%  Y2 = [Y_DispLIN2;0];
% %% 计算每层输出平均温差
% % 假设 SensM_T 是一个一维数组
% num_layers = 10;
% SensM_T_values = zeros(1, num_layers);
% % 使用循环计算每层的输出温差
% for i = 1:num_layers
%     SensM_T_values(i) = sum(SensM_T(i:10:4000)) / 400;
% end
% % % 如果需要，可以将结果显示出来
% % for i = 1:num_layers
% %     fprintf('第%d层输出温差: %.2f\n', i, SensM_T_values(i));
% % end
% % 创建一个新的图形窗口
% hfig = figure;
% 
% % 创建表格数据
% layer_indices = (1:num_layers)';
% data = [layer_indices, SensM_T_values'];
% % 创建表格列名称
% columnNames = {'层', '温差'};
% % 创建表格
% uitable('Parent', hfig, 'Data', data, 'ColumnName', columnNames,...
%         'Position', [20 20 600 400]); % 调整位置和大小
% %% 分别绘制x和y方向中心线的图
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

% %% 网格划分20X20X20
% %% IMPORTANT SETINGS
% %% Initiation 
% PositionMx=53:155:6098;   %CFFF单边固支方板300mm*300mm*6mm，网格20X20，y=0.15m固定端沿自由端中心线
% PositionMy=108:310:5998;   %CFFF单边固支方板300mm*300mm*6mm，网格20X20，y=0m固定端沿自由端中心线
% % PositionMy=2898:5:3098;   %单边固支/对边固支方板300mm*300mm*6mm，网格20X20，x=0.15m
% PositionMEE =1:8000;
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
% %%%%%
% Loadmax = 0;
% Voltmax = 300;
% Magnetic = 0;
% %划分20层  网格20X20 
%    PhiaMT(20:20:8000) = Voltmax;
%    PhiaMT(1:20:8000) = -Voltmax;
%    MgaT(20:20:8000) = -Magnetic;
%    MgaT(1:20:8000) = Magnetic; 
% %%%%%   
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
% % %由压电方程计算温差
% % FuaT=zeros(8000,1);
% %     Tot_DOF_MEET = length(KuuT(:,1));
% %     AA=[KuuT,KufMT; KfuMT,KffMT];
% %     BB=[FueT; FuaT];
% %     CC=AA\BB;
% %     Qd = CC(1:Tot_DOF_MEET);
% %     SensM_T = CC(Tot_DOF_MEET+1:end); 
% %由热弹性本构方程计算温差
% FutT=zeros(8000,1);
%     Tot_DOF_MEET = length(KuuT(:,1));
%     AA=[KuuT,KutT; KtuT,KttT];
%     BB=[FuaT; FutT];
%     CC=AA\BB;
%     Qd = CC(1:Tot_DOF_MEET);
%     SensM_T = CC(Tot_DOF_MEET+1:end);
%     
% X_Disp=0:0.0075:0.3; 
% X_Disp1=0:0.015:0.3; 
%  %CFFF单边固支y=0.15m以及y=0m的z向位移
% Y_DispLIN1=1000*Qd(PositionMx);
% Y_DispLIN2=1000*Qd(PositionMy);
%  Y1 = [0;Y_DispLIN1];
%  Y2 = [0;Y_DispLIN2];
% %% 计算每层输出平均电势
% % 假设 SensM_T 是一个一维数组
% num_layers = 20;
% SensM_T_values = zeros(1, num_layers);
% % 使用循环计算每层的输出温差
% for i = 1:num_layers
%     SensM_T_values(i) = sum(SensM_T(i:20:8000)) / 400;
% end
% % % 如果需要，可以将结果显示出来
% % for i = 1:num_layers
% %     fprintf('第%d层输出温差: %.2f\n', i, SensM_T_values(i));
% % end
% % 创建一个新的图形窗口
% hfig = figure;
% % 创建表格数据
% layer_indices = (1:num_layers)';
% data = [layer_indices, SensM_T_values'];
% % 创建表格列名称
% columnNames = {'层', '温差'};
% % 创建表格
% uitable('Parent', hfig, 'Data', data, 'ColumnName', columnNames,...
%         'Position', [20 20 600 400]); % 调整位置和大小
% %% 分别绘制x和y方向中心线的图
% % 创建一个图形窗口并使用子图
% figure;
% % 绘制y=0.15m时沿x方向的中心线位移
% subplot(2, 1, 1);
% plot(X_Disp, Y1, '-ob', 'markersize', 5);
% ylabel('Centerline Displacement (mm)');
% xlabel('x-Distance');
% title('y=0.15m along X-axis z-Displacement');
% grid on;
% % 绘制y=0m时沿x方向的中心线位移
% subplot(2, 1, 2);
% plot(X_Disp1, Y2, '-ob', 'markersize', 5);
% ylabel('Centerline Displacement (mm)');
% xlabel('y-Distance');
% title('y=0m along X-axis z-Displacement');
% grid on;
%% 网格划分30X30X10
%% IMPORTANT SETINGS
%% Initiation 
PositionMx=78:225:13353;   %CFFC邻边固支方板300mm*300mm*6mm，网格30X30，y=0.15m固定端沿自由端中心线
PositionMy=153:450:13203;   %CFFC邻边固支方板300mm*300mm*6mm，网格30X30，y=0m固定端沿自由端中心线
% PositionMy=6598:5:6898;   %CFFC邻边固支方板300mm*300mm*6mm，网格30X30，x=0.15m
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

Loadmax = 0;
Voltmax = 300;
Magnetic = 0;
%划分10层  网格30X30 
   PhiaMT(10:10:9000) = Voltmax;
   PhiaMT(1:10:9000) = -Voltmax;
   MgaT(10:10:9000) = -Magnetic;
   MgaT(1:10:9000) = Magnetic; 
%%%%%   
FueT = FusT*Loadmax;
FuaT = -KufMT*PhiaMT;
FumT = -KuzT*MgaT;
FutT = -KutT*DelT;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Linear
%先计算位移再计算温差
% Qd = KuuT\FuaT;  
% Tot_DOF_MEET = length(KttT(:,1));
% AA = KttT;
% BB = -KtuT*Qd;
% CC = AA\BB;
% SensM_T = CC(1:Tot_DOF_MEET);
% %由压电方程计算温差
% FuaT=zeros(8000,1);
%     Tot_DOF_MEET = length(KuuT(:,1));
%     AA=[KuuT,KufMT; KfuMT,KffMT];
%     BB=[FueT; FuaT];
%     CC=AA\BB;
% %     Qd = CC(1:Tot_DOF_MEET);
%     SensM_T = CC(Tot_DOF_MEET+1:end);  
%由热弹性本构方程计算温差
FutT=zeros(9000,1);
    Tot_DOF_MEET = length(KuuT(:,1));
    AA=[KuuT,KutT; KtuT,KttT];
    BB=[FuaT; FutT];
    CC=AA\BB;
    Qd = CC(1:Tot_DOF_MEET);
    SensM_T = CC(Tot_DOF_MEET+1:end);
%%%%%      
X_Disp=0:0.005:0.3; 
X_Disp1=0:0.01:0.3; 
 %CFFF单边固支y=0.15m以及y=0m的z向位移
Y_DispLIN1=1000*Qd(PositionMx);
Y_DispLIN2=1000*Qd(PositionMy);
 Y1 = [0;Y_DispLIN1];
 Y2 = [0;Y_DispLIN2];
% %% 计算每层输出平均电势
% % 假设 SensM_T 是一个一维数组
% num_layers = 10;
% SensM_T_values = zeros(1, num_layers);
% % 使用循环计算每层的输出温差
% for i = 1:num_layers
%     SensM_T_values(i) = sum(SensM_T(i:10:9000)) / 900;
% end
% % % 如果需要，可以将结果显示出来
% % for i = 1:num_layers
% %     fprintf('第%d层输出温差: %.2f\n', i, SensM_T_values(i));
% % end
% % 创建一个新的图形窗口
% hfig = figure;
% % 创建表格数据
% layer_indices = (1:num_layers)';
% data = [layer_indices, SensM_T_values'];
% % 创建表格列名称
% columnNames = {'层', '温差'};
% % 创建表格
% uitable('Parent', hfig, 'Data', data, 'ColumnName', columnNames,...
%         'Position', [20 20 600 400]); % 调整位置和大小
%% 分别绘制x和y方向中心线的图
% 创建一个图形窗口并使用子图
figure;
% 绘制y=0.15m时沿x方向的中心线位移
subplot(2, 1, 1);
plot(X_Disp, Y1, '-ob', 'markersize', 5);
ylabel('Centerline Displacement (mm)');
xlabel('x-Distance');
title('y=0.15m along X-axis z-Displacement');
grid on;
% 绘制y=0m时沿x方向的中心线位移
subplot(2, 1, 2);
plot(X_Disp1, Y2, '-ob', 'markersize', 5);
ylabel('Centerline Displacement (mm)');
xlabel('y-Distance');
title('y=0m along X-axis z-Displacement');
grid on;