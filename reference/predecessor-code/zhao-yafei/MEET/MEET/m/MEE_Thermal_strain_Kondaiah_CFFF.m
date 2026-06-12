%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Main function
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc;
clear;
addpath(genpath('../SubFunMFC'));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Difine files
InputFile = './InputFile/Kondaiah_CFFF.txt';
OutputFile = [];
UsedDataFile = 'LINEAR_DataUsed.txt';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Get start information
IsANS = 0;
IsDamp = 0;
Theory = 3;
ThermalNL =0;%;0均匀；1线性；2正弦 ;3热传导
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
CaseName = strcat('./CurrentComp/FOSD');
FileNameRes = strcat(CaseName, '.mat');
UsedDataFile_NL = strcat(CaseName, '.txt');
FigureName = strcat(CaseName, '.fig');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
RunPara = struct('IsANS',IsANS,'IsDamp',IsDamp,'Theory',Theory, ...
                 'IntegSchem',IntegSchem,'DampRatio',DampRatio);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Linear FE computation
 [GlobMatr,FinitElemInfo,MateProp] = Main_FOSDLIN851T5MEEP_V4(InputFile, ...
                        OutputFile,UsedDataFile,IsANS,DampRatio,IntegSchem,ThermalNL);
[~,Material] = SF_GetInputDataMEEP(InputFile);                 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Output the data that was use during calculation
ShellTheory = FinitElemInfo.ShellTheory;
[ShellInt,ShellStr] = SF_ShellNotation(ShellTheory(1,1));
ElemType = FinitElemInfo.ElemType;
Element = FinitElemInfo.Element;
Node = FinitElemInfo.Node;

NumLay = ElemType(3);
NodePerElem = ElemType(1);

[NumNode,~] = size(Node);
[NumElem,~] = size(Element);
%% IMPORTANT SETINGS
LayInsertPoint = 2;%每一层在厚度方向上需要插入的点的个数
SF_GetUsedData(UsedDataFile,FinitElemInfo,Material,MateProp);
    H_total = 0;
    zC_InsertPoint = zeros(NumLay*LayInsertPoint,1);
for LayIndex = 1:NumLay
    MatePropCurrLay = MateProp{LayIndex,1};
    Lay_zC = MatePropCurrLay.Lay_zC;
    H_total = H_total + abs(Lay_zC(1)-Lay_zC(2)); 
    zC_InsertPoint((LayIndex-1)*LayInsertPoint+1:LayIndex*LayInsertPoint,1) = Lay_zC(1):(Lay_zC(2)-Lay_zC(1))/(LayInsertPoint-1):Lay_zC(2);
end
for i = 1:length(zC_InsertPoint)    %厚度方向计算的应变点的个数
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
[SinFusT_DOF_PositionM] = SinFusT_DOF_PositionM;
%FusT = SinFusT_DOF_PositionM.SinFusT;%正弦载荷，最大值为1N
PositionM_h = SinFusT_DOF_PositionM.PositionM_h;%水平中心线Theta3方向自由度位置
PositionM_v = SinFusT_DOF_PositionM.PositionM_v;%竖直中心线Theta3方向自由度位置
DOFPerNodeM = SinFusT_DOF_PositionM.DOFPerNodeM;
Length = SinFusT_DOF_PositionM.Length;
Wide = SinFusT_DOF_PositionM.Wide;
MeshL = SinFusT_DOF_PositionM.MeshL;
MeshW = SinFusT_DOF_PositionM.MeshW;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% IMPORTANT SETINGS
%% Initiation 
PhiaMT = zeros(FinalDofMEE,1);
MgaT=zeros(FinalDofMEE,1);
DeltaT = zeros(2,1);
DeltaT(1,1) = 0;%bottom
DeltaT(2,1) =100;%top
Voltmax=0;
Magnetic=0;
  PhiaMT(1:1:200)=Voltmax;
  PhiaMT(1:1:200)=-Voltmax;
  MgaT(1:1:200)=Magnetic;
 LoadMax=0; 
 FueT = FusT*LoadMax;   %% surface force;
 FuaT = -KufMT *PhiaMT;
 FutT = -KutT *DeltaT;
 Qd = KuuT\FutT;
 Qd_restore = Qd;
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Transform matrix of strain components matrix into strain matrix
%% 修改  zC  可以查看不同厚度位置的应变
zC = zC_InsertPoint(i,1);
H1 = [1 0 0 zC 0  0  zC^3 0    0    0 0 0     0;
      0 1 0 0  zC 0  0    zC^3 0    0 0 0     0;
      0 0 1 0  0  zC 0    0    zC^3 0 0 0     0;
      0 0 0 0  0  0  0    0    0    1 0 zC^2  0;
      0 0 0 0  0  0  0    0    0    0 1 0     zC^2];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
%% Stress calculation
% Gaussian点在自然坐标系中的位置
XY_Local = [-1/sqrt(3),1/sqrt(3),1/sqrt(3),-1/sqrt(3);
            -1/sqrt(3),-1/sqrt(3),1/sqrt(3),1/sqrt(3)];
N_Linear_Jacobian = zeros(4,4);
%% Stress calculation
NodeElemCord = zeros(8,3);  %%% Node coordinates in one element
Strain_Plate = zeros(NumNode,length(H1(:,1))); %每个单元角点的应变单独占一行，每个角点有5个应变，即有5列（这里初始应变矩阵给了单元边的中间节点的位置，后面需要删除）
Stress_Plate = zeros(NumNode,length(H1(:,1))); %每个单元角点的应力单独占一行，每个角点有5个应力，即有5列（这里初始应力矩阵给了单元边的中间节点的位置，后面需要删除）
PosME = 5;  % First postion of mechanical dof (first one) and electrical dof (second)
for NodeIndex = 1:NumNode
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% For Qd restore
    %%% PosME(1): Start position of electrical dof
    for DOFMIndex = 1:DOFPerNodeM
        if Node(NodeIndex,PosME+DOFMIndex-1) == 1
            RestoreIndex=(NodeIndex-1)*DOFPerNodeM+DOFMIndex;
            Qd_restore = [Qd_restore(1:RestoreIndex-1,1);0;Qd_restore(RestoreIndex:length(Qd_restore),1)];%恢复行
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for EleIndex = 1:NumElem    
    XNode = zeros(NodePerElem,3);
    for j = 1:NodePerElem
        [Row,Column]=find(Node(:,1)==Element(EleIndex,j));
        XNode(j,1:3)=Node(Row,2:4);    %XNode,globle coordinate of node 
    end
    if ShellInt == 2 || ShellInt == 3
	R = XNode(1,3);
    end
%% Coordinates adaption
%%% ShellInt: 1,PLATE; 2, CYLINDER;
        switch ShellInt
            case 1      % PLATE
                a1 = 1;         a2 = 1;     %% a1 = a^{11},a1 = a^{22}
                b1 = 0;         b2 = 0;     %% b1 = a_{11},a1 = a_{22}
                t1 = 0;         t2 = 0;     %% Christoffel symbol
                k1 = 1;         k2 = 0;     %% coeffient for Theta %GYS 这个有什么作用？
                %%% s1 = |g^{1}|,s2 = |g^{2}|, in the terms including xC
                s1 = 1;         s2 = 1;     
            case 2      % CYLINDER
                a1 = 1;         a2 = 1/(R^2);
                b1 = 0;         b2 = -R;
                t1 = 0;         t2 = 0;
                k1 = R;         k2 = 0;
                s1 = 1;         s2 = 1;
        end
        %%%%%%%%%%%%%%%%%%%
        c1 = a1*b1;     c2 = a2*b2;         %%
        Sqrt_a = sqrt(1/(a1*a2));    
%% Define Noem and Kth matrices
Norm = diag([s1*s1,s2*s2,s1*s2,s1*s1,s2*s2,s1*s2,s1*s1,s2*s2,s1*s2,s2,s1,s2,s1]);
Kth = diag([1,1,k1,k1,1,1,1,1,k1,k1,1,k1,1,1,k1]);%GYS 这个有什么作用？为什么是这样的？
%% A0 matrix
        A0(1,[1,13]) = [1, -b1];
        A0(2,[4,11,13]) = [1, t2, -b2];           
        A0(3,[2,3,12]) = [1, 1, 2*t1];
        A0(4,[1,7,13]) = [-a1*b1, 1, a1*b1^2];
        A0(5,[4,10,11,13,14]) = [-a2*b2, 1, -a2*b2*t2, a2*b2^2, t2];
        A0(6,[2,3,8,9,12,15]) = [-a1*b1,-a2*b2,1,1,-a2*b2*t1-a1*b1*t1,2*t1];
        A0(7,7) = -a1*b1;
        A0(8,[10,14]) = [-a2*b2, -a2*b2*t2];
        A0(9,[8,9,15]) = [-a1*b1, -a2*b2, -a2*b2*t1-a1*b1*t1];
        A0(10,[6,12,15]) = [1, c2, 1];
        A0(11,[5, 11, 14]) = [1, c1, 1];
        A0(12,15) = c2-a2*b2;
        A0(13,14) = c1-a1*b1; 
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    ElementCurr = FinitElemInfo.Element(EleIndex,:);
    for j = 1:8
        [Row,Column]=find(Node(:,1)==ElementCurr(j));%找出当前单元第j个节点对应的行（也就是节点序号）
        NodeElemCord(j,1:3)=Node(Row,2:4);    %XNode,globle coordinate of node 
        Qd_Elem((j-1)*DOFPerNodeM+1:j*DOFPerNodeM,1) = ...
            Qd_restore((ElementCurr(j)-1)*DOFPerNodeM+1:ElementCurr(j)*DOFPerNodeM);%将单元各节点位移从总结果位移向量中复制出来
    end
	Strain_Gaussian = zeros(length(XY_Local(1,:)),5);
    Stress_Gaussian = zeros(length(XY_Local(1,:)),5);
    for StressIndex = 1:length(XY_Local(1,:))
        xL = XY_Local(1,StressIndex);
        yL = XY_Local(2,StressIndex); %单元中计算应力的位置分别拿出来
        % Linear shape function
        N_Linear(1)=1/4*(1-xL)*(1-yL);
        N_Linear(2)=1/4*(1+xL)*(1-yL);
        N_Linear(3)=1/4*(1+xL)*(1+yL);
        N_Linear(4)=1/4*(1-xL)*(1+yL);
        N_Linear_Jacobian(StressIndex,:) = [N_Linear(1),N_Linear(2),N_Linear(3),N_Linear(4)];
        %%% shape function
        N(1)=1/4*(1-xL)*(1-yL)*(-xL-yL-1);
        N(2)=1/4*(1+xL)*(1-yL)*(xL-yL-1);
        N(3)=1/4*(1+xL)*(1+yL)*(xL+yL-1);
        N(4)=1/4*(1-xL)*(1+yL)*(-xL+yL-1);
        N(5)=1/2*(1-xL^2)*(1-yL);
        N(6)=1/2*(1-yL^2)*(1+xL);
        N(7)=1/2*(1-xL^2)*(1+yL);
        N(8)=1/2*(1-yL^2)*(1-xL);
        %%% Derivative of shape function
        Jacobian_DN(1,1) = 1/4*(1-yL)*(2*xL+yL);
        Jacobian_DN(1,2) = 1/4*(1-xL)*(xL+2*yL);
        Jacobian_DN(2,1) = 1/4*(1-yL)*(2*xL-yL);
        Jacobian_DN(2,2) = 1/4*(1+xL)*(-xL+2*yL);
        Jacobian_DN(3,1) = 1/4*(1+yL)*(2*xL+yL);
        Jacobian_DN(3,2) = 1/4*(1+xL)*(xL+2*yL);
        Jacobian_DN(4,1) = 1/4*(1+yL)*(2*xL-yL);
        Jacobian_DN(4,2) = 1/4*(1-xL)*(-xL+2*yL);
        Jacobian_DN(5,1) = -1*xL*(1-yL);
        Jacobian_DN(5,2) = -1/2*(1-xL^2);
        Jacobian_DN(6,1) = 1/2*(1-yL^2);
        Jacobian_DN(6,2) = -1*(1+xL)*yL;
        Jacobian_DN(7,1) = -xL*(1+yL);
        Jacobian_DN(7,2) = 1/2*(1-xL^2);
        Jacobian_DN(8,1) = -1/2*(1-yL^2);
        Jacobian_DN(8,2) = -1*(1-xL)*yL; 
        %%% calculate the coordinates for the stress point
        %%% Jacobian
        Jacobian = zeros(2,2);
        for ii=1:2  %Jacobian的行
            for jj=1:2  %Jacobian对应的列（偏导的坐标轴）
                for kk=1:8  %节点序号
                    Jacobian(ii,jj) =  Jacobian(ii,jj) + Jacobian_DN(kk,ii)*XNode(kk,jj);
                end
            end
        end
        
        DN = zeros(8,2);                
        for k = 1:NodePerElem
            DN(k,:) = (Jacobian\[Jacobian_DN(k,1);Jacobian_DN(k,2)])';
        end
        %%%
        IM = eye(DOFPerNodeM,DOFPerNodeM);              %IM(5,5)
        Nu = [N(1)*IM, N(2)*IM, N(3)*IM, N(4)*IM, ...
              N(5)*IM, N(6)*IM, N(7)*IM, N(8)*IM];
          
        LNuTemp = [DN(1,1)*IM,DN(2,1)*IM,DN(3,1)*IM,DN(4,1)*IM, ...
                   DN(5,1)*IM,DN(6,1)*IM,DN(7,1)*IM,DN(8,1)*IM ];
        %%%
        LNu(1,:) = LNuTemp(1,:);
        LNu(3,:) = LNuTemp(2,:);
        LNu(5,:) = LNuTemp(3,:);
        LNu(7,:) = LNuTemp(4,:);
        LNu(9,:) = LNuTemp(5,:);
        %%%
        LNuTemp = [DN(1,2)*IM,DN(2,2)*IM,DN(3,2)*IM,DN(4,2)*IM, ...
                   DN(5,2)*IM,DN(6,2)*IM,DN(7,2)*IM,DN(8,2)*IM ];
        %%%
        LNu(2,:) = LNuTemp(1,:);
        LNu(4,:) = LNuTemp(2,:);
        LNu(6,:) = LNuTemp(3,:);
        LNu(8,:) = LNuTemp(4,:);
        LNu(10,:) = LNuTemp(5,:);
        LNu(11,:) = Nu(1,:);
        LNu(12,:) = Nu(2,:);
        LNu(13,:) = Nu(3,:);
        LNu(14,:) = Nu(4,:);
        LNu(15,:) = Nu(5,:);     
        %% B_comp Strain components matrix of IntegralPoint       
        B_comp = Norm*A0*Kth*LNu;
        B = H1*B_comp;
        Strain_Gaussian(StressIndex,:) = (B*Qd_Elem)';
    end
        Strain_corner = N_Linear_Jacobian\Strain_Gaussian;   %只求单元4个角的应力应变值
        Stress_corner = (MateProp{ceil(i/LayInsertPoint),1}.c*(Strain_corner)')';
    for m = 1:length(XY_Local(1,:))
            Strain_Plate(Element(EleIndex,m),:) = Strain_Plate(Element(EleIndex,m),:) + Strain_corner(m,:);
            Stress_Plate(Element(EleIndex,m),:) = Stress_Plate(Element(EleIndex,m),:) + Stress_corner(m,:);
    end

end

Mid_node = 0;
for EleIndex = NumElem:-1:1
	for m = length(XY_Local(1,:))+1:NodePerElem
        Mid_node = Mid_node + 1;
        DeletIndex(Mid_node,1) = Element(EleIndex,m);
	end
end
DeletIndex = unique(DeletIndex);%删除DeletIndex中相同的数
% [Y,~]=sort(DeletIndex,'descend');%降序排序
Strain_Plate(DeletIndex,:) = []; %%%删除应变矩阵中单元边的中间节点对应的行（上述没有计算）
Stress_Plate(DeletIndex,:) = []; %%%删除应力矩阵中单元边的中间节点对应的行（上述没有计算）

Divide_2 = zeros(MeshL-1,2);
for j = 1:(MeshL+1)*(MeshW+1)
    for k = 1:MeshL-1
        Divide_2(k,:) = [k*(MeshW + 1) + 1, (k + 1)*(MeshW + 1)];%这些点应力应变除以2
    end
end
Divide_2 = reshape(Divide_2,1,[]);
Divide_2 = sort([Divide_2 2:MeshW ((MeshL+1)*(MeshW+1)-MeshW)+1:(MeshL+1)*(MeshW+1)-1]);
Divide_1 = [1 (1+MeshW) ((MeshL+1)*(MeshW+1)) ((MeshL+1)*(MeshW+1)-MeshW)];%这些点应力应变除以1
Strain_Plate = Strain_Plate/4;
Stress_Plate = Stress_Plate/4;
Strain_Plate(Divide_2,:) = Strain_Plate(Divide_2,:)*2;
Stress_Plate(Divide_2,:) = Stress_Plate(Divide_2,:)*2;
Strain_Plate(Divide_1,:) = Strain_Plate(Divide_1,:)*4;
Stress_Plate(Divide_1,:) = Stress_Plate(Divide_1,:)*4;
%% 节点 应力
%中间点  stain11 和 stress11 (Pa)
strain_11 = Strain_Plate(((MeshW+1)*(MeshL/2)+MeshW/2+1),1); 
eval(['strain_11_',num2str(i),'= strain_11']);
X_strain_11(1,i) = strain_11;
stress_11 = Stress_Plate(((MeshW+1)*(MeshL/2)+MeshW/2+1),1); 
eval(['stress_11_',num2str(i),'= stress_11']);
X_stress_11(1,i) = stress_11;

%中间点  stain22 和 stress22 (Pa)
strain_22 = Strain_Plate(((MeshW+1)*(MeshL/2)+MeshW/2+1),2); 
eval(['strain_22_',num2str(i),'= strain_22']);
X_strain_22(1,i) = strain_22;
stress_22 = Stress_Plate(((MeshW+1)*(MeshL/2)+MeshW/2+1),2); 
eval(['stress_22_',num2str(i),'= stress_22']);
X_stress_22(1,i) = stress_22;

%左下角  stain12 和 stress12 (Pa)
strain_12 = Strain_Plate(((MeshW+1)*(MeshL/2)+MeshW/2+1),3); 
eval(['strain_12_',num2str(i),'= strain_12']);
X_strain_12(1,i) = strain_12;
stress_12 = Stress_Plate(((MeshW+1)*(MeshL/2)+MeshW/2+1),3); 
eval(['stress_12_',num2str(i),'= stress_12']);
X_stress_12(1,i) = stress_12;

%下边中点 stain23 和 stress23 (Pa)
strain_23 = Strain_Plate(((MeshW+1)*(MeshL/2)+MeshW/2+1),4); 
eval(['strain_23_',num2str(i),'= strain_23']);
X_strain_23(1,i) = strain_23;
stress_23 = Stress_Plate(((MeshW+1)*(MeshL/2)+MeshW/2+1),4); 
eval(['stress_23_',num2str(i),'= stress_23']);
X_stress_23(1,i) = stress_23;

%左边中点 stain13 和 stress13 (Pa)
strain_13 = Strain_Plate(((MeshW+1)*(MeshL/2)+MeshW/2+1),5); 
eval(['strain_13_',num2str(i),'= strain_13']);
X_strain_13(1,i) = strain_13;
stress_13 = Stress_Plate(((MeshW+1)*(MeshL/2)+MeshW/2+1),5); 
eval(['stress_13_',num2str(i),'= stress_13']);
X_stress_13(1,i) = stress_13;
end
Y_Num_Thickness = zC_InsertPoint';
%% 绘图
%中间点 strain_11和stress11
% hfig_strain_11 = figure;
% set(hfig_strain_11,'Position', [0 300 440 330]) % 定义窗口到电脑屏幕左边的距离是0，到电脑屏幕下方的距离是300，图片width=440 ,height=330
% plot(X_strain_11,Y_Num_Thickness*1000,'-O');%,X,Y(mm)
% xlabel('Strain');
% ylabel('\Theta^3 (mm)');
% legend('\epsilon_{11}');
% grid on;
% saveas(hfig_strain_11,FigureName);
% X_strain_11 = X_strain_11';

hfig_stress_11 = figure;
set(hfig_stress_11,'Position', [0 300 440 330]) % 定义窗口到电脑屏幕左边的距离是0，到电脑屏幕下方的距离是300，图片width=440 ,height=330
plot((X_stress_11),(Y_Num_Thickness/0.012),'-O');%,X(Pa),Y(mm)
xlabel('Stress (Pa)');
ylabel('\Theta^3 (mm)');
legend('\sigma_{11}');
grid on;
saveas(hfig_stress_11,FigureName);
X_stress_11 = X_stress_11';
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %中间点 strain_22和stress22
% hfig_strain_22 = figure;
% set(hfig_strain_22,'Position', [0 300 440 330]) % 定义窗口到电脑屏幕左边的距离是0，到电脑屏幕下方的距离是300，图片width=440 ,height=330
% plot(X_strain_22,Y_Num_Thickness*1000,'-O');%Y(mm)
% xlabel('Strain');
% ylabel('\Theta^3 (mm)');
% legend('\epsilon_{22}');
% grid on;
% saveas(hfig_strain_22,FigureName);
% X_strain_22 = X_strain_22';
% 
% hfig_stress_22 = figure;
% set(hfig_stress_22,'Position', [0 300 440 330]) % 定义窗口到电脑屏幕左边的距离是0，到电脑屏幕下方的距离是300，图片width=440 ,height=330
% plot(X_stress_22,Y_Num_Thickness*1000,'-O');%,X(Pa),Y(mm)
% xlabel('Stress (Pa)');
% ylabel('\Theta^3 (mm)');
% legend('\sigma_{22}');
% grid on;
% saveas(hfig_stress_22,FigureName);
% X_stress_22 = X_stress_22';
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %左下角 strain_12和stress12
% hfig_strain_12 = figure;
% set(hfig_strain_12,'Position', [0 300 440 330]) % 定义窗口到电脑屏幕左边的距离是0，到电脑屏幕下方的距离是300，图片width=440 ,height=330
% plot(X_strain_12,Y_Num_Thickness*1000,'-O');%Y(mm)
% xlabel('Strain');
% ylabel('\Theta^3 (mm)');
% legend('\epsilon_{12}');
% grid on;
% saveas(hfig_strain_12,FigureName);
% X_strain_12 = X_strain_12';
% 
% hfig_stress_12 = figure;
% set(hfig_stress_12,'Position', [0 300 440 330]) % 定义窗口到电脑屏幕左边的距离是0，到电脑屏幕下方的距离是300，图片width=440 ,height=330
% plot(X_stress_12,Y_Num_Thickness*1000,'-O');%,X(Pa),Y(mm)
% xlabel('Stress (Pa)');
% ylabel('\Theta^3 (mm)');
% legend('\sigma_{12}');
% grid on;
% saveas(hfig_stress_12,FigureName);
% X_stress_12 = X_stress_12';
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %下边中点 strain23和stress23
% hfig_strain_23 = figure;
% set(hfig_strain_23,'Position', [0 300 440 330]) % 定义窗口到电脑屏幕左边的距离是0，到电脑屏幕下方的距离是300，图片width=440 ,height=330
% plot(X_strain_23,Y_Num_Thickness*1000,'-O');%Y(mm)
% xlabel('Strain');
% ylabel('\Theta^3 (mm)');
% legend('\epsilon_{23}');
% grid on;
% saveas(hfig_strain_23,FigureName);
% X_strain_23 = X_strain_23';
% 
% hfig_stress_23 = figure;
% set(hfig_stress_23,'Position', [0 300 440 330]) % 定义窗口到电脑屏幕左边的距离是0，到电脑屏幕下方的距离是300，图片width=440 ,height=330
% plot(X_stress_23,Y_Num_Thickness*1000,'-O');%X(Pa),Y(mm)
% xlabel('Stress (Pa)');
% ylabel('\Theta^3 (mm)');
% legend('\sigma_{23}');
% grid on;
% saveas(hfig_stress_23,FigureName);
% X_stress_23 = X_stress_23';
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %左边中点 strain13和stress13
% hfig_strain_13 = figure;
% set(hfig_strain_13,'Position', [0 300 440 330]) % 定义窗口到电脑屏幕左边的距离是0，到电脑屏幕下方的距离是300，图片width=440 ,height=330
% plot(X_strain_13,Y_Num_Thickness*1000,'-O');%Y(mm)
% xlabel('Strain');
% ylabel('\Theta^3 (mm)');
% legend('\epsilon_{13}');
% grid on;
% saveas(hfig_strain_13,FigureName);
% X_strain_13 = X_strain_13';
% 
% hfig_stress_13 = figure;
% set(hfig_stress_13,'Position', [0 300 440 330]) % 定义窗口到电脑屏幕左边的距离是0，到电脑屏幕下方的距离是300，图片width=440 ,height=330
% plot(X_stress_13,Y_Num_Thickness*1000,'-O');%X(Pa),Y(mm)
% xlabel('Stress (Pa)');
% ylabel('\Theta^3 (mm)');
% legend('\sigma_{13}');
% grid on;
% saveas(hfig_stress_13,FigureName);
% X_stress_13 = X_stress_13';
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Y_DispLIN = Qd(PositionM_v(5)); 
% %% save file
% save(FileNameRes,'RunPara','Y_Num_Thickness','X_stress_11');