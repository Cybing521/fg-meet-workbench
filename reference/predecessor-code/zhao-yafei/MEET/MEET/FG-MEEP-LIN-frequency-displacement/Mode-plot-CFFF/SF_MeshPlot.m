function [x_dis,y_dis,Z_dis] = SF_MeshPlot(FinitElemInfo,Qd)
%% %%%%%%%%%%%%%3D z向位移
Node = FinitElemInfo.Node;
z_dis=zeros(size(Node,1),1);
%ConsNum 所有自由度
for ic = 1:size(Node,1)
 ConsNum = length(find(Node(1:(ic-1),5:9)==1))...
 +length(find(Node(ic,5:6)==1));
 if Node(ic,7)==1
   z_dis(ic)=0;
 else
     Position3D = Node(ic,1)*5-ConsNum-2;
     z_dis(ic)=Qd(Position3D);
 end
end
%% x coordinate
xn=Node(:,2);
x_allNum = xn(1); %提取不同的所有x坐标
kk= 2;
for i = 1:length(xn)
     switch length(x_allNum)
            case 1
            EleFlag1 =  i;
            case 2
            EleFlag2 =  i;
        end
    for ii = 1:length(x_allNum)
        if x_allNum(ii) == xn(i)
            flag = 1;
            break;
        else
            flag = 0;
        end
    end      
   if flag == 0
      x_allNum(kk) = xn(i);
      kk = kk+1;
   end
end
x_LenNodeNum = EleFlag2 - 1;
x_dis = xn(1:x_LenNodeNum:end); 

%% y coordinate
yn=Node(:,3);

y_dis = yn(EleFlag1:(EleFlag2-1)); 
%% z coordinate
Z_dis=[];
iz=1;
for iz=1:size(x_dis,1)
Z_dis(:,iz)= z_dis((1+(iz-1)*(EleFlag2-1)):2:((1+(iz-1)*(EleFlag2-1))+(ii-1)));%%%%
end

end

