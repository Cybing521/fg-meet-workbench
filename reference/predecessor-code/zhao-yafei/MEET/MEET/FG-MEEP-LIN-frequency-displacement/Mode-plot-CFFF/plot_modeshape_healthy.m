clc,clear;
load('EigenVector_health.mat')
load('CFFF-U-index-2-P-0.2.mat')
Nodeinfo = FinitElemInfo.Node;
ElemInfo = FinitElemInfo.Element;
Mode_order =4;%首先选择想要输出的模态数
NumNode_Oneside = 21;%一侧的节点数，这里考虑对称的有限元划分
NumHole = 0;%中间孔洞欠缺单元数（其中一列）
NumX = 10;%横向和纵向的单元数
NumY = 10;
%% 获得所有节点的三方向位移，单元坐标值等
is_health = 1;%1是健康，0是非健康
z_dis = EigenVector(3:5:end,:); % 1079个w方向自由度，5395个模态
pre_dis = zeros(NumNode_Oneside,length(EigenVector(1,:)));%被边界限制了自由度，因此位移值是0，需要在后续补充上
%下面是加上了被限制自由度处的位移值，现在是完整的含有所有节点的w方向位移
z_dis_total = [pre_dis;z_dis];
% %下面是最大坐标点的坐标值,用来限定坐标图轴
% xmin = min(Nodeinfo(:,2));
% ymin = min(Nodeinfo(:,3));
% xmax = max(Nodeinfo(:,2));
% ymax = max(Nodeinfo(:,3));
% zmin = min(min(z_dis_total));
% zmax = max(max(z_dis_total));
%x,y坐标及z的位移值
X = Nodeinfo(:,2);
Y = Nodeinfo(:,3);
Z = z_dis_total(:,Mode_order);%含插值点的
%% 把每个节点值对应到对应形状的矩阵去
Elem_corner = unique(ElemInfo(:,1:4));%取出单元角点的编号
Z1 = zeros(length(Elem_corner),1);
for i = 1:length(Elem_corner)
        Z1(i) = Z(Elem_corner(i));
end
count = 1;%循环内计数用
shape = NaN(NumX+1,NumY+1);%预先准备一个和模型外围大小一致的矩阵
switch is_health
case 0
            
            for i = 1:NumX+1
                for j = 1:NumY+1

                        if(NumHole<=i && 2*NumHole-2>=i) &&  (NumHole<=j && 2*NumHole-2>=j)
                            shape(i,j) = NaN;
                        else
                            shape(j,i) = Z1(count);
                            count = count+1;

                        end


            %                 if (i > NumHole && j > NumHole && i <= 2 * NumHole && j <= 2 * NumHole)
            %                     shape(i,j) = NaN;
            %                 else
            %                     shape(i,j) = Z(count);
            %                     count = count + 1;   
            %                 end
            %                 disp(['i: ', num2str(i), ' j: ', num2str(j),' count:',num2str(count)]); % 输出当前循环节点的位置
                end
            end
case 1
            for i = 1:NumX+1
                for j = 1:NumY+1
                    shape(j,i) = Z1(count);
                    count = count+1;
                end
            end
end
            figure

surf(shape)
shading interp
colorbar









%画图，先画简单的散点图看是否正确
% figure
% scatter3(X,Y,Z);
% hold on
% img1 = gcf;
% % 定义绘图区域
% figure
% [xi,yi] = meshgrid(xmin:0.005:xmax,ymin:0.005:ymax);
% zi =griddata(X,Y,Z,xi,yi);
% img2 = pcolor(xi,yi,zi);
% % 
% figure
% final = intersect(img1,img2);
% % 进行三维插值
% val_interp = interp2(x,y,Z,'cubic');
% 
% % 绘制三维表面
% surf(X,Y,Z,val_interp);
% xlabel('X');
% ylabel('Y');
% zlabel('Z');
% colorbar;
% title('三维插值图');
