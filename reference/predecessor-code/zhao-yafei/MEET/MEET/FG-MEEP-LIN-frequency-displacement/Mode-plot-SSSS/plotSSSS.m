clc,clear;
load('SSSS-O-index-2-P-0.2.mat')

Mode_order = 10;
order = 10;%期望被输出的模�??
DispMode = Mode_order;%首先选择想要输出的模态数
[EigenVector,EigenValue]=SF_ModesAnalysis(DispMode,GlobMatr, ...
                                                   FinitElemInfo);
Nodeinfo = FinitElemInfo.Node;
ElemInfo = FinitElemInfo.Element;

NumX = 10;%横向和纵向的单元�?
NumY = 10;
NumNode_X = 2*NumX+1;%�?侧的节点数，这里考虑对称的有限元划分
NumNode_Y = 2*NumY+1;%�?侧的节点数，这里考虑对称的有限元划分
NumNode_X1 = NumX+1;%�?侧插值的节点数，这里考虑对称的有限元划分
NumNode_Y1 = NumY+1;%�?侧插值的节点数，这里考虑对称的有限元划分
NumDof = length(EigenVector(:,1));
Elem_corner = unique(ElemInfo(:,1:4));%取出单元角点的编�?
%% 获得�?有节点的三方向位移，单元坐标值等
%四边�?支下的条�?
BCL = [0 NaN NaN 0 NaN];
BCR = [NaN 0 NaN NaN 0];
BCB = [0 NaN NaN 0 NaN];
BCT = [NaN 0 NaN NaN 0];
BCXzeros = zeros(1,NumX-1);
BCYzeros = zeros(1,NumY+1)';
count=length(find(BCL==0));
for ord =2
%乘count的原因是还剩余count个自由度
        L = EigenVector(1:NumNode_X*count-4,ord);
        mid_pre = EigenVector(NumNode_X*count-4+1:NumDof-NumNode_X*count+4,ord);
        R = EigenVector(NumDof-NumNode_X*count+1+4:end,ord);

for i = 1:NumX-1
    B_indices11(i) = ((i-1)*((NumNode_Y-2)*5+2*4+(NumNode_X1-2)*5))+50;%角结点第�?个自由度
    B_indices12(i) = ((i-1)*((NumNode_Y-2)*5+2*4+(NumNode_X1-2)*5))+51;%角结点第二个自由�?
    T_indices11(i) = ((i-1)*((NumNode_Y-2)*5+2*4+(NumNode_X1-2)*5))+50+(NumNode_Y-2)*5+2;%角结�?
    T_indices12(i) = ((i-1)*((NumNode_Y-2)*5+2*4+(NumNode_X1-2)*5))+50+(NumNode_Y-2)*5+2+1;%角结�?
end

for ii = 1:NumX
    B_indices21(ii) = ((ii-1)*((NumNode_Y-2)*5+2*4+(NumNode_X1-2)*5))+1;%中间结点
    B_indices22(ii) = ((ii-1)*((NumNode_Y-2)*5+2*4+(NumNode_X1-2)*5))+2;%中间结点
    T_indices21(ii) = ((ii-1)*((NumNode_Y-2)*5+2*4+(NumNode_X1-2)*5))+(NumNode_Y1-2)*5+2;%中间结点
    T_indices22(ii) = ((ii-1)*((NumNode_Y-2)*5+2*4+(NumNode_X1-2)*5))+(NumNode_Y1-2)*5+2+1;%中间结点
end

% T = [mid_pre(T_indices11) mid_pre(T_indices12) mid_pre(T_indices21) mid_pre(T_indices22)];
% B = [mid_pre(B_indices11) mid_pre(B_indices12) mid_pre(B_indices21) mid_pre(B_indices22)]; 
indices = [T_indices11,T_indices12,T_indices21,T_indices22,B_indices11,B_indices12,B_indices21,B_indices22];
mid_pre(indices) = [];
mid = mid_pre;
mid_w = mid(3:5:end); %三方向位�?
for j = 1:NumX
    for jj = 1:NumY-1
        interp_indices1(jj,j) = (j-1)*(2*NumY-1+NumY-1)+jj;
    end
end
for j = 1:NumX-1
    for jj = 1:NumY
        interp_indices2(jj,j) = (j-1)*(2*NumY-1+NumY-1)+(jj*2-1)+9;
    end
end

interp_indices1 = reshape(interp_indices1,1,[]);
interp_indices2 = reshape(interp_indices2,1,[]);
interp_indices = [interp_indices1 interp_indices2];
mid_w(interp_indices) = [];
mid_w_corner = mid_w;
shape_pre = reshape(mid_w_corner,NumX-1,NumY-1);
shape_tb = [BCXzeros;shape_pre;BCXzeros];
shape = [BCYzeros shape_tb BCYzeros];
figure
surf(shape)
shading interp
colorbar

end



