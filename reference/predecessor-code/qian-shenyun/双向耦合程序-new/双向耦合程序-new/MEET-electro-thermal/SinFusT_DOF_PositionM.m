%% 该程序适用于矩形网格划分，但只适用于均匀划分节点坐标
function [SinFusT_DOF_PositionM] = SinFusT_DOF_PositionM
Length = 1; %长m (Theta^1若为柱状板壳单元，这里为直边长度，单位m)
Wide = 0.1;  %宽m  (Theta^2若为柱状板壳单元，这里为柱状板壳单元的弧度方向的弧度，单位 弧度)
MeshL= 20;  %长的网格个数
MeshW= 5;  %宽的网格个数
MaterialLayers= 10;  %有材料的层数
BoundaryConditions = 'CFFF';  %边界条件为CFSH的排列，先后分别表示左、下、右、上的边界情况
Theory = 'FOSD';   %这里为用到的理论，填写“FOSD”和“Z”
LayersMax = 20; %最多可适用于划分材料的层数
Radius = 0; %若为柱状板则填写半径m
Angle = 0; %此处填写的为与Y轴的夹角，单位为度，与X轴的夹角默认为0度。
%% 节点排布、自由度约束
Grid = MeshL*MeshW;
ClockNodes = zeros(Grid,LayersMax + 10);
Material = zeros(1,LayersMax);
node1 = 1;
k = 1;
Angle = Angle/180*pi;
for i=1:Grid
    if k <= MeshW
        node2 = node1 + 2*MeshW + MeshW + 1 + 1;
        node3 = node2 + 2;
        node4 = node1 + 2;
        if k==1
            node5 = node1 + 2*MeshW + 1;
        else
            node5 = node7;
        end
        node6 = node2 + 1;
        node7 = node5 + 1;
        node8 = node1 + 1;
        nodes(1,:) = [node1,node2,node3,node4,node5,node6,node7,node8];
        for j=1:MaterialLayers
            Material(1,j) = 1;
        end
        ClockNodes(i,:) = [i,NaN,nodes,Material];
        if k==MeshW
            k = 1;
            node1 = node3 - 2*MeshW;
        else
            k = k+1;
            node1 = node4;
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 节点坐标和自由度
NodesNum = (MeshL + 1)*(2*MeshW + 1) + MeshL*(MeshW + 1);
BoundaryConditionL = zeros(1,12);
BoundaryConditionB = zeros(1,12);
BoundaryConditionR = zeros(1,12);
BoundaryConditionU = zeros(1,12);
BoundaryCondition = zeros(1,12);
Iheta3_Fixed = 0;
for i=1:NodesNum
    %左边边界自由度
    if i<=2*MeshW + 1
        if BoundaryConditions(1) == 'C'
            BoundaryConditionL(1,1:5) = ones(1,5);
        elseif BoundaryConditions(1) == 'F'
            
        elseif BoundaryConditions(1) == 'S'
            BoundaryConditionL(1,[2,3,5]) = ones(1,3);
        elseif BoundaryConditions(1) == 'H'
            BoundaryConditionL(1,[1,2,3,5]) = ones(1,4);
        end
    end
   %下边边界自由度
    if rem((i - 1)/(3*MeshW + 2),1)==0 || rem((i - 2*MeshW - 2)/(3*MeshW + 2),1)==0%rem求余数
        if BoundaryConditions(2) == 'C'
            BoundaryConditionB(1,1:5) = ones(1,5);
        elseif BoundaryConditions(2) == 'F'
            
        elseif BoundaryConditions(2) == 'S'
            BoundaryConditionB(1,[1,3,4]) = ones(1,3);
        elseif BoundaryConditions(2) == 'H'
            BoundaryConditionB(1,[1,2,3,4]) = ones(1,4);
        end
    end
    %右边边界自由度
    if i>=NodesNum - 2*MeshW
        if BoundaryConditions(3) == 'C'
            BoundaryConditionR(1,1:5) = ones(1,5);
        elseif BoundaryConditions(3) == 'F'
            
        elseif BoundaryConditions(3) == 'S'
            BoundaryConditionR(1,[2,3,5]) = ones(1,3);
        elseif BoundaryConditions(3) == 'H'
            BoundaryConditionL(1,[1,2,3,5]) = ones(1,4);
        end
    end
   %上边边界自由度    
    if rem((i + 1 + MeshW)/(3*MeshW + 2),1)==0 || rem(i/(3*MeshW + 2),1)==0 %rem求余数
        if BoundaryConditions(4) == 'C'
            BoundaryConditionU(1,1:5) = ones(1,5);
        elseif BoundaryConditions(4) == 'F'
            
        elseif BoundaryConditions(4) == 'S'
            BoundaryConditionU(1,[1,3,4]) = ones(1,3);
        elseif BoundaryConditions(4) == 'H'
            BoundaryConditionU(1,[1,2,3,4]) = ones(1,4);
        end
    end
end
CoordinateDOFs = zeros(NodesNum,16);
Coordinate = zeros(1,3);%用于储存每一个节点的坐标
    
X_NodeLength = Length/(2*MeshL);%X坐标
Y_NodeLength = Wide/(2*MeshW);%Y坐标    
Z_NodeLength = Radius;%Z坐标

Column_X = 0;
j=1;
for i=1:NodesNum
    Column_X = Column_X + (rem((i - 1)/(3*MeshW + 2),1)==0) + (rem((i - 2*MeshW - 2)/(3*MeshW + 2),1)==0);
    if j<=2*MeshW + 1
        Row_Y = j-1;
    elseif j<=3*MeshW + 2
        Row_Y = (j - 2 - 2*MeshW)*2;
        if j==3*MeshW + 2
            j = 0;
        end
    end
    j = j + 1;
    
    %包括两个角的左边边界自由度
    if i<=2*MeshW + 1	
       if i==1 %左下角自由度
           for k=1:5
                BoundaryCondition(1,k) = BoundaryConditionL(1,k) || BoundaryConditionB(1,k);
           end
       elseif i==2*MeshW + 1   %左上角自由度
           for k=1:5
                BoundaryCondition(1,k) = BoundaryConditionL(1,k) || BoundaryConditionU(1,k);
           end
       else
           BoundaryCondition = BoundaryConditionL;
       end
    
    %包括两个角的右边边界自由度
    elseif i>=NodesNum - 2*MeshW
       if i==NodesNum - 2*MeshW %右下角自由度
           for k=1:5
                BoundaryCondition(1,k) = BoundaryConditionR(1,k) || BoundaryConditionB(1,k);
           end
       elseif i==NodesNum  %右上角自由度
           for k=1:5
                BoundaryCondition(1,k) = BoundaryConditionR(1,k) || BoundaryConditionU(1,k);
           end
       else
           BoundaryCondition = BoundaryConditionR;
       end

    %不包括两个角的下边边界自由度 
    elseif rem((i - 3*MeshW - 3)/(3*MeshW + 2),1)==0 || rem((i - 2*MeshW - 2)/(3*MeshW + 2),1)==0%rem求余数
        BoundaryCondition = BoundaryConditionB;
    %不包括两个角的上边边界自由度     
    elseif rem((i - 2*MeshW - 1)/(3*MeshW + 2),1)==0 || rem(i/(3*MeshW + 2),1)==0 %rem求余数
        BoundaryCondition = BoundaryConditionU;
    else
        BoundaryCondition = zeros(1,12);
    end    
    Coordinate(1,:) = [(Column_X-1)*X_NodeLength + Row_Y*Y_NodeLength*tan(Angle), Row_Y*Y_NodeLength, Z_NodeLength];
    CoordinateDOFs(i,:) = [i,Coordinate,BoundaryCondition];
end      
%% 确定节点自由度
if Theory == 'FOSD'

    DOFPerNodeM = 5;
    
else
    Theory == 'Z'
    CoordinateDOFs(:,[10,11]) = CoordinateDOFs(:,[8,9]);
    DOFPerNodeM = 7;
end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 定义正弦载荷
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% 将压强变为节点压力
Iheta3_Fixed = 0;
if BoundaryConditions(1) ~= 'F'
    Iheta3_Fixed = Iheta3_Fixed + 2*MeshW + 1;
    if BoundaryConditions(2) ~= 'F'
        Iheta3_Fixed = Iheta3_Fixed + 2*MeshL;
        if BoundaryConditions(3) ~= 'F'
            Iheta3_Fixed = Iheta3_Fixed + 2*MeshW;
            if BoundaryConditions(4) ~= 'F'
                Iheta3_Fixed = Iheta3_Fixed + 2*MeshL-1;
            end
        elseif BoundaryConditions(4) ~= 'F'
            Iheta3_Fixed = Iheta3_Fixed + 2*MeshL;
        else
        end
    elseif BoundaryConditions(3) ~= 'F'
            Iheta3_Fixed = Iheta3_Fixed + 2*MeshW+1;
            if BoundaryConditions(4) ~= 'F'
                Iheta3_Fixed = Iheta3_Fixed + 2*MeshL-1;
            end
        elseif BoundaryConditions(4) ~= 'F'
            Iheta3_Fixed = Iheta3_Fixed + 2*MeshL;
    end
end
k = Iheta3_Fixed/(MeshL*MeshW)*(1/6); %对总力的修正  或采用张老师的方式，角-1/12，边1/3（故被约束的边1/3-2*1/12=1/6） 
FT = (1+k)*Wide*Length;   %单位压强对应的总力
F_node = FT/(NodesNum);   %将力平均分到各个节点上
FusT = zeros(NodesNum*DOFPerNodeM,1);
for i=1:NodesNum
    FusT((i-1)*DOFPerNodeM+3,:) = F_node*sin(CoordinateDOFs(i,2)/Length*pi)*sin(CoordinateDOFs(i,3)/Wide*pi);
%     FusT((i-1)*DOFPerNodeM+3,:) = F_node;
end
%% 删除被约束元素
Node = zeros(NodesNum, DOFPerNodeM);
Node(:,:) = CoordinateDOFs(:,5:5+DOFPerNodeM-1);

for NodeIndex = NodesNum:-1:1
    for DOFMIndex = DOFPerNodeM:-1:1
        if Node(NodeIndex,DOFMIndex) == 1
            DeletIndex=(NodeIndex-1)*DOFPerNodeM+DOFMIndex;
            FusT(DeletIndex,:)=[];
        end
    end
end
SinFusT = FusT;

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 中心线PositionM  每两个点间的距离都是一个单元长度
InitPositionM_Node_h = MeshW+1:3*MeshW+2:NodesNum; %Theta1方向的中心线节点序号
PositionM_h = zeros(1,length(InitPositionM_Node_h));
for PositionM_NodeIndex = 1:length(InitPositionM_Node_h)
    NodeIndex = InitPositionM_Node_h(PositionM_NodeIndex);
    Fixed_DOF_Num = sum(sum(CoordinateDOFs(1:NodeIndex-1,5:5+DOFPerNodeM-1)));
    PositionM_h(1,PositionM_NodeIndex) =...
        (InitPositionM_Node_h(1,PositionM_NodeIndex) - 1)*DOFPerNodeM + 3 - Fixed_DOF_Num; %中心线节点在Theta3方向自由度位置
end
% 如果左右两端Theta3方向自由度被限制，删除对应节点
if BoundaryConditions(1) == 'F'
else
    PositionM_h(:,1) = [];
end
if BoundaryConditions(3) == 'F'
else
    PositionM_h(:,end) = [];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Cycle_Num = round(MeshL/2); %为了适用于偶数或奇数网格
if rem(MeshL,2) ==0
	Node_interval = 2;
    PositionM_Begin = Cycle_Num*(3*MeshW + 2) + 1 + Node_interval;
    PositionM_End = Cycle_Num*(3*MeshW+2) + 2*MeshW + 1;
else
    Node_interval = 1;
    PositionM_Begin = Cycle_Num*(3*MeshW + 2) - MeshW + Node_interval;
    PositionM_End = Cycle_Num*(3*MeshW+2);
end
InitPositionM_Node_v = PositionM_Begin:Node_interval:PositionM_End; %Theta2方向的中心线节点序号(不包括最下面一个节点)
InitPositionM_v = (InitPositionM_Node_v-1)*DOFPerNodeM+3;
PositionM_v = InitPositionM_v -...
    sum(sum(CoordinateDOFs(1:PositionM_Begin-1,5:5+DOFPerNodeM-1)));%中心线节点在Theta3方向自由度位置
% 若下端Theta3方向自由度没被限制，增加对应节点；如果上端Theta3方向自由度被限制，删除对应节点。
if BoundaryConditions(2) == 'F'
    PositionM_v = [PositionM_v(1,1)-7,PositionM_v];
else
end

if BoundaryConditions(4) == 'F'
else
    PositionM_v(:,end) = [];
end
%% 矩阵保存
SinFusT_DOF_PositionM = struct('ClockNodes',ClockNodes,'CoordinateDOFs',CoordinateDOFs,'DOFPerNodeM',DOFPerNodeM,...
    'SinFusT',SinFusT,'PositionM_h',PositionM_h,'PositionM_v',PositionM_v,'Length',Length,'Wide',Wide,'MeshL',MeshL,'MeshW',MeshW);

%% 如果不是以子程序运行，可以用下面方式保存为.mat文件
% CaseName = strcat('./CurrentComp/SinFusT_DOF_PositionM');
% FileNameRes = strcat(CaseName, '.mat');
% save(FileNameRes,'ClockNodes','CoordinateDOFs','Sin_FusT','PositionM_h','PositionM_v');
% clearvars -EXCEPT FileNameRes
% load(FileNameRes)
% clear FileNameRes

end