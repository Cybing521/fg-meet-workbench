clc;clear;
addpath(genpath('../SubFunMFC'));
% load('stiffness_change.mat');
load('./Global_Matrix/plate_9x9_h.mat');
DispMode = 1;
[EigenVector,EigenValue]=SF_ModesAnalysis(DispMode,GlobMatr, ...
                                                   FinitElemInfo);
                                               
% for kk = 1:6
    kk = 2;%振型
    NumDof = length(EigenVector);
    NumColumn = 9;
    NumRow = 9;
    mode = EigenVector(3:5:NumDof,kk);
    W_Dof = length(mode);
    shape_2 = zeros(NumRow+1,NumColumn+1);
    for i = 1:NumColumn+1
       if i == 1
           shape_2(:,1) = zeros(NumColumn+1,1);
       elseif    1<i && i<NumColumn+1
           shape_2(:,i) = mode((i-1)*29+1-19:2:(i-1)*29+19-19);

       else
           shape_2(:,NumColumn+1) = zeros(NumColumn+1,1);
       end

    end
%     figure
%     surf(shape)
%% 循环输出振型
%     exportgraphics(gcf,['s',num2str(i),'.pdf'],'ContentType','vector');%
%     saveas(gcf,['m',num2str(i),'.png']);
%     img =gcf;  %获取当前画图的句柄
%     print(img, '-dpng', '-r600', ['m',num2str(kk),'.png'])         %即可得到对应格式和期望dpi的图像
    
% end
