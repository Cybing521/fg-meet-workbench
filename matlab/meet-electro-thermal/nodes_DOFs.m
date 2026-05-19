%% 该程序适用于矩形网格划分，但只适用于均匀划分节点坐标
clc; clear;
CaseName = strcat('./CurrentComp/nodes_DOFs');
FileNameRes = strcat(CaseName, '.mat');
Length = 0.3; %长m (Theta^1若为柱状板壳单元，这里为直边长度，单位m)
Wide = 0.3;  %宽m  (Theta^2若为柱状板壳单元，这里为柱状板壳单元的弧度方向的弧度，单位 弧度)
MeshL= 30;  %长的网格个数
MeshW= 30;  %宽的网格个数
MaterialLayers= 10;  %有材料的层数
BoundaryConditions = 'CCCC';  %边界条件为CFSH的排列，先后分别表示左、下、右、上的边界情况
Theory = 'F';   %这里为用到的理论，填写“F”、“T”、“Z”或“M”,F=FOSD,Z=Zigzag,T=TOSD,M=FOSD_HOSD_FOSD
LayersMax = 20; %最多可适用于划分材料的层数
Radius = 0; %若为柱状板则填写半径m
Angle_degree = 0; %此处填写的为与Y轴的夹角，单位为度，与X轴的夹角默认为0度。
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Element_Node_excel
for Element_Node = 1
Grid = MeshL*MeshW;
ClockNodes = zeros(Grid,LayersMax + 10);
Material = zeros(1,LayersMax);
node1 = 1;
k = 1;
Angle = Angle_degree/180*pi;    %角度单位转成rad弧度制
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
            BoundaryConditionR(1,[1,2,3,5]) = ones(1,4);
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

if Theory == 'M'	
	CoordinateDOFs(:,16) = CoordinateDOFs(:,7);
	
    CoordinateDOFs(:,10) = CoordinateDOFs(:,8);
	CoordinateDOFs(:,12) = CoordinateDOFs(:,8);
    CoordinateDOFs(:,14) = CoordinateDOFs(:,8);
    
    CoordinateDOFs(:,11) = CoordinateDOFs(:,9);
    CoordinateDOFs(:,13) = CoordinateDOFs(:,9);
    CoordinateDOFs(:,15) = CoordinateDOFs(:,9);    
elseif Theory == 'Z'
	CoordinateDOFs(:,[10,11]) = CoordinateDOFs(:,[8,9]);
elseif Theory == 'T'
	CoordinateDOFs(:,[10,11]) = CoordinateDOFs(:,[8,9]);
end
end
%% Element_Node_fig
for Element_Node_fig = 1
k = min([1900/(Length+Wide*tan(Angle)),800/Wide]);    %找出合适的缩放比，在保证原始结构长宽比例的情况下使fig最大化

fig_distance_L = 0;
fig_distance_B = 150;
fig_length = (Length+Wide*tan(Angle))*k*0.9;
fig_width = Wide*k*0.9;

table_X = 0:(Length*1000/MeshL):Length*1000;    %定义网格的行数和列数并生成相应向量，单位mm
table_Y = 0:(Wide*1000/MeshW):Wide*1000;

[mesh_x,mesh_y] = meshgrid(table_X,table_Y);    %生成mesh_x和mesh_y矩阵，mesh_x的列相等，mesh_y的行相等，(mesh_x和mesh_y的同一位置可以作为网格坐标)
mesh_x = mesh_x + mesh_y*tan(Angle);    %考虑与y轴的夹角

hfig1 = figure;
set(hfig1,'Position', [fig_distance_L fig_distance_B fig_length fig_width]) %% for deflection plot 长宽不要超过1900，宽不要超过700，否则会跑到屏幕外面

plot(mesh_x,mesh_y,'g',mesh_x',mesh_y','r');  %绘制网格列和行
set(gca,'XTick',table_X);
set(gca,'YTick',table_Y);
set(gca,'Fontangle','italic')
set(gca,'xcolor','m');
set(gca,'ycolor','m');
box off;
xlabel('\rmLength/mm')  %\rm正体
ylabel('\rmWidth/mm')

if Theory == 'M'
	title([num2str(MeshL),'*',num2str(MeshW),' \rm\color{magenta}Mixed \color{red}Node'],'Fontname','黑体','Fontsize',16)
elseif Theory == 'Z'
	title([num2str(MeshL),'*',num2str(MeshW),' \rm\color{magenta}Zigzag \color{red}Node'],'Fontname','黑体','Fontsize',16)
elseif Theory == 'F'
    title([num2str(MeshL),'*',num2str(MeshW),' \rm\color{magenta}FOSD \color{red}Node'],'Fontname','黑体','Fontsize',16)
elseif Theory == 'T'
    title([num2str(MeshL),'*',num2str(MeshW),' \rm\color{magenta}TOSD \color{red}Node'],'Fontname','黑体','Fontsize',16)
end

for i = 1:NodesNum
mark_x = CoordinateDOFs(i,2)*1000;  %单位mm
mark_y = CoordinateDOFs(i,3)*1000;
text(mark_x,mark_y,'o','color','y','HorizontalAlign','center', 'VerticalAlign','middle') %在当前节点位置做标记,居中
text(mark_x,mark_y,num2str(i),'color','k','HorizontalAlign','center', 'VerticalAlign','middle')   %写出节点序号，居中
end
for ElementIndex = 1:Grid
    %计算单元中心点坐标
    Element_x = 0;
    Element_y = 0;
    for j = [3,5]   %单元的第1、3的节点在ClockNodes的第3、5列
        NodeIndex = ClockNodes(ElementIndex,j); %找出对角节点序号
        Element_x = Element_x + CoordinateDOFs(NodeIndex,2)*1000/2;  %单位mm
        Element_y = Element_y + CoordinateDOFs(NodeIndex,3)*1000/2;
    end
   text(Element_x,Element_y,num2str(ElementIndex),'color','k','HorizontalAlign','center', 'VerticalAlign','middle');   %标出单元序号，居中
   line('XData',Element_x, 'YData',Element_y,'LineStyle','none', 'Marker','o', 'MarkerSize',16,'MarkerFaceColor','none', 'MarkerEdgeColor','k');    %画圆，居中
end
end
%% Element_DOFs_fig
for Element_DOFs_fig = 1
%% 约束后标出节点最后一个自由度序号
hfig2 = figure;
set(hfig2,'Position', [fig_distance_L+100 fig_distance_B-50 fig_length fig_width]) %% for deflection plot 长宽不要超过1900，宽不要超过700，否则会跑到屏幕外面

plot(mesh_x,mesh_y,'g',mesh_x',mesh_y','r');  %绘制网格列和行
set(gca,'XTick',table_X);
set(gca,'YTick',table_Y);
set(gca,'Fontangle','italic')
set(gca,'xcolor','m');
set(gca,'ycolor','m');
box off;
xlabel('\rmLength/mm')  %\rm正体
ylabel('\rmWidth/mm')

if Theory == 'M'
	title([num2str(MeshL),'*',num2str(MeshW),' \rm\color{magenta}Mixed \color{red}DOFs'],'Fontname','黑体','Fontsize',16)
elseif Theory == 'Z'
	title([num2str(MeshL),'*',num2str(MeshW),' \rm\color{magenta}Zigzag \color{red}DOFs'],'Fontname','黑体','Fontsize',16)
elseif Theory == 'F'
    title([num2str(MeshL),'*',num2str(MeshW),' \rm\color{magenta}FOSD \color{red}DOFs'],'Fontname','黑体','Fontsize',16)
elseif Theory == 'T'
    title([num2str(MeshL),'*',num2str(MeshW),' \rm\color{magenta}TOSD \color{red}DOFs'],'Fontname','黑体','Fontsize',16)
end

Node_DOF_order = 0;
for i = 1:NodesNum
	if Theory == 'F'
        Node_DOFs = 5;
        Condense_DOF = sum(CoordinateDOFs(i,5:5+Node_DOFs-1));
        if Condense_DOF == 5
            Boundary_condition = 'C';
        elseif Condense_DOF == 4
            Boundary_condition = 'H';
        elseif Condense_DOF == 3
            Boundary_condition = 'S';
        else
            Boundary_condition = [];
        end
	end
    
    if Theory == 'Z'
        Node_DOFs = 7;
        Condense_DOF = sum(CoordinateDOFs(i,5:5+Node_DOFs-1));
        if Condense_DOF == 7
            Boundary_condition = 'C';
        elseif Condense_DOF == 5
            Boundary_condition = 'H';
        elseif Condense_DOF == 4
            Boundary_condition = 'S';
        else
            Boundary_condition = [];
        end
    end
    
    if Theory == 'T'
        Node_DOFs = 7;
        Condense_DOF = sum(CoordinateDOFs(i,5:5+Node_DOFs-1));
        if Condense_DOF == 7
            Boundary_condition = 'C';
        elseif Condense_DOF == 5
            Boundary_condition = 'H';
        elseif Condense_DOF == 4
            Boundary_condition = 'S';
        else
            Boundary_condition = [];
        end
    end
    
    if Theory == 'M'
        Node_DOFs = 12;
        Condense_DOF = sum(CoordinateDOFs(i,5:5+Node_DOFs-1));
        if Condense_DOF == 12
            Boundary_condition = 'C';
        elseif Condense_DOF == 10
            Boundary_condition = 'H';
        elseif Condense_DOF == 7
            Boundary_condition = 'S';
        else
            Boundary_condition = [];
        end
    end
    
    Node_DOF_order = Node_DOF_order + Node_DOFs - Condense_DOF;
    mark_x = CoordinateDOFs(i,2)*1000;  %单位mm
    mark_y = CoordinateDOFs(i,3)*1000;
    if Boundary_condition == 'C'
        str = Boundary_condition;
        text(mark_x,mark_y,str,'color','b','HorizontalAlign','center', 'VerticalAlign','middle') %对被固定（C）的节点位置做标记,居中
    elseif Boundary_condition == 'H'
        str = [Boundary_condition,num2str(Node_DOF_order)];
        text(mark_x,mark_y,str,'color','b','HorizontalAlign','center', 'VerticalAlign','middle') %对铰支（H）的节点位置做标记,同时写出最后自由度序号,居中
    elseif Boundary_condition == 'S'
        str = [Boundary_condition,num2str(Node_DOF_order)];
        text(mark_x,mark_y,str,'color','b','HorizontalAlign','center', 'VerticalAlign','middle') %对简支（S）的节点位置做标记,同时写出最后自由度序号,居中
    else
        str = num2str(Node_DOF_order);
        text(mark_x,mark_y,str,'color','k','HorizontalAlign','center', 'VerticalAlign','middle') %对自由节点写出最后自由度序号,居中
    end
end

for ElementIndex = 1:Grid
    %计算单元中心点坐标
    Element_x = 0;
    Element_y = 0;
    for j = [3,5]   %单元的第1、3的节点在ClockNodes的第3、5列
        NodeIndex = ClockNodes(ElementIndex,j); %找出对角节点序号
        Element_x = Element_x + CoordinateDOFs(NodeIndex,2)*1000/2;  %单位mm
        Element_y = Element_y + CoordinateDOFs(NodeIndex,3)*1000/2;
    end
    text(Element_x,Element_y,num2str(ElementIndex),'color','k','HorizontalAlign','center', 'VerticalAlign','middle');   %标出单元序号，居中
    line('XData',Element_x, 'YData',Element_y,'LineStyle','none', 'Marker','o', 'MarkerSize',16,'MarkerFaceColor','none', 'MarkerEdgeColor','k');    %画圆，居中
end
end
%%
clearvars -except ClockNodes CoordinateDOFs
% save(FileNameRes,'ClockNodes','CoordinateDOFs');