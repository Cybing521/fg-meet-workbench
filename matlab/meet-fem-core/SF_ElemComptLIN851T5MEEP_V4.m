%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Subfuntion SF_ElemComptLIN851T5MFC
%Calculate Muu,Kuu,Kuf,Kff for one element
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ElemMatr]=SF_ElemComptLIN851T5MEEP_V4(EleIndex,MatePropCurrLay, ...
                                   MateProp,LayIndex,FinitElemInfo,IntegSchem,Totalthickness,ThermalNL)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%fs=[0;0;1],external uniform load,[u,v,w]
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Coordinates specification
%%% xG,yG,zG: Global coordinates
%%% xC,yC,zC: Curvalinear coordinates
%%% xL,yL,zL: Local coordinates

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Finite Element information
ElemType = FinitElemInfo.ElemType;
Element = FinitElemInfo.Element;
Node = FinitElemInfo.Node;
ShellTheory = FinitElemInfo.ShellTheory;
[ShellInt,ShellStr] = SF_ShellNotation(ShellTheory(1,1));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Material properties for current layer
Mate_C = MatePropCurrLay.C;
Mate_eM = MatePropCurrLay.eM;
Mate_gM = MatePropCurrLay.gM;
Mate_q = MatePropCurrLay.q;
Mate_k = MatePropCurrLay.k;
Mate_r = MatePropCurrLay.r;
Mate_c = MatePropCurrLay.c;
Density = MatePropCurrLay.Density;
Lay_zC = MatePropCurrLay.Lay_zC;
IsSmtLay = MatePropCurrLay.IsSmtLay;
hE = MatePropCurrLay.hE;
Mate_PyroE = MatePropCurrLay.PyroE;%PyroE,Lamdat
Mate_PyroM = MatePropCurrLay.PyroM;%PyroM,Lamdat
c33 = MatePropCurrLay.c33;
% c33 = MatCurrLayer(1,22); 
Mate_Lamdat = MatePropCurrLay.Lamdat;
totalh = Totalthickness.totalh;
HC=Totalthickness.HC;

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Calculate ElementNum, Nodenum
% NumElem: Total number of element
% NumNode: Total number of node
NumElem = length(Element(:,1));
NumNode = length(Node(:,1));

%% Calculate dofs and matrices size
%%% ElemType = [Node/Elem DOF/Node NumSmtLay DOF/SmtLay NumLay]
NodePerElem = ElemType(1);
DOFPerNodeM = ElemType(2);
NumLay = ElemType(3);
DOFPerMEELay = ElemType(4);
NumMEELay = ElemType(5);
DOFPerElemM = NodePerElem*DOFPerNodeM;
DOFPerElemMEE = NumMEELay*DOFPerMEELay;  % Number of MEE dof per element
% NumLayT = NumLay;
% DOFPerTLay = 1;
% DOFPerElemT = NumLayT*DOFPerTLay;
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Definition of Gauss Point and its weight
switch IntegSchem
    case 'G3'   %% Three gauss points
        GP_3=[-0.774596669241483 0.555555555555556;
               0.774596669241483 0.555555555555556;
               0                 0.888888888888889];        
    case 'G2'   %% Two gauss points
        GP_3=[ 0.5773502691,1.0000;
              -0.5773502691,1.0000];     
    otherwise
end 
   
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Calculate one layer----------------------------------------------Start
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Initiate global matrices for mass, stiffness......
Muu = zeros(DOFPerElemM,DOFPerElemM); 
Kuu = zeros(DOFPerElemM,DOFPerElemM);
   
KufM = zeros(DOFPerElemM,DOFPerElemMEE); 
KffM = zeros(DOFPerElemMEE,DOFPerElemMEE);

Kuz=zeros(DOFPerElemM,DOFPerElemMEE); 
Kfz=zeros(DOFPerElemMEE,DOFPerElemMEE); 
Kzz=zeros(DOFPerElemMEE,DOFPerElemMEE);
 
Kut = zeros(DOFPerElemM,DOFPerElemMEE);
Kft = zeros(DOFPerElemMEE,DOFPerElemMEE);
Kzt = zeros(DOFPerElemMEE,DOFPerElemMEE);
Ktt = zeros(DOFPerElemMEE,DOFPerElemMEE);

Fui = zeros(DOFPerElemM,1); 
Fus = zeros(DOFPerElemM,1); 
Fuc = zeros(DOFPerElemM,1); 
GfiM = zeros(DOFPerElemMEE,1);
GfM = zeros(DOFPerElemMEE,1);
Mzi=zeros(DOFPerElemMEE,1);
Mz=zeros(DOFPerElemMEE,1);
Ft = zeros(DOFPerElemMEE,1); 

%% relation between local coordinate and globle coordinate xG,yG
XNode = zeros(NodePerElem,3);
for j = 1:NodePerElem
    [Row,Column]=find(Node(:,1)==Element(EleIndex,j));
    XNode(j,1:3)=Node(Row,2:4);    %XNode,globle coordinate of node
end

%relation between local coordinate and globle coordinate xG,yG
 EleLen = abs(XNode(2,1)-XNode(1,1));
 EleWid = abs(XNode(4,2)-XNode(1,2));

LayHigh = abs(Lay_zC(1)-Lay_zC(2));
%%%%%%%%%%%%%%%%
if ShellInt == 2 || ShellInt == 3
    R = XNode(1,3);
end
%%%%%%
 a = EleLen/2;
 b = EleWid/2;
 h = LayHigh/2;
xC_m = (XNode(1,1)+XNode(2,1))/2;       % xC_m: middle position of xC
% yC_m = (XNode(1,2)+XNode(4,2))/2;       % xC_m: middle position of yC
zC_m = (Lay_zC(1)+Lay_zC(2))/2;         % zC_m: middle line of layer
%% Initiate resultant matrices
Hu = zeros(5,5);
H_C = zeros(13,13);
HeM = zeros(NumMEELay,13);
HgM = zeros(NumMEELay,NumMEELay);
 Hq = zeros(NumMEELay,13);
 Hk = zeros(NumMEELay,NumMEELay);
 Hr = zeros(NumMEELay,NumMEELay);
 Hld = zeros(NumMEELay,13);
 HpE = zeros(NumMEELay,NumMEELay);
 HpM = zeros(NumMEELay,NumMEELay);
 Hc = zeros(NumMEELay,NumMEELay);
A0 = zeros(13,15);
A0_new = zeros(13,18);
LNu = zeros(15,40);
LNu_new = zeros(18,40);
%% Bt %温度的分布规律
% Bt = zeros(1,2);
% switch ThermalNL
%     case 0    %均匀分布
%      Bt(1,1) = -1;
%      Bt(1,2) = 1;
%     case 1     %线性
%      Bt(1,1) = 1/2 - zC_m/totalh;
%      Bt(1,2) = 1/2 + zC_m/totalh;
%     case 2      %正弦
%      Bt(1,1) = cos(pi/2*(0.5+zC_m/totalh));
%      Bt(1,2) = 1 - cos(pi/2*(0.5+zC_m/totalh));
%      case 3   %%%热传导
%          HC1=0;
%          for i = 1:LayIndex
%              Mate_Current_layer = MateProp{i,1};
%              HC_Current = Mate_Current_layer.HC_Current;  
%              cc=1/HC_Current;
%             HC1 = HC1 + cc*LayHigh;
%          end        
%         Bt(1,1) = 1-HC1/HC;
%         Bt(1,2) = HC1/HC;
% end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% BfM,Bz, Bt
BfM = zeros(NumMEELay,NumMEELay);
Bz = zeros(NumMEELay,NumMEELay);
Bt = zeros(NumMEELay,NumMEELay);
for i=1:NumMEELay
   if  IsSmtLay == 2 
        BfM(i,i)=-1/(hE);
        Bz(i,i)=-1/(hE);
        Bt(i,i)= 1 ;
   else
        BfM(i,i)=0;
        Bz(i,i)=0;
        Bt(i,i)=0;
   end
end
%% PE
    PE = zeros(DOFPerElemMEE,DOFPerElemMEE);
   for ij = 1:DOFPerElemMEE
       PE(ij,ij) = Mate_PyroE;
   end
   %% PM
    PM = zeros(DOFPerElemMEE,DOFPerElemMEE);
   for ij = 1:DOFPerElemMEE
       PM(ij,ij) = Mate_PyroM;
   end
   %% PM
    MC = zeros(DOFPerElemMEE,DOFPerElemMEE);
   for ij = 1:DOFPerElemMEE
       MC(ij,ij) = c33;
   end
%% Resultant matrices, Hu, Hc, He, Hg
for i = 1:length(GP_3(:,1))
    zL = GP_3(i,1);
    zC = zC_m + h*zL;
    Zu = [1 0 0 zC 0;
          0 1 0 0  zC;
          0 0 1 0  0  ];
    H1 = [1 0 0 zC 0  0  zC^2 0    0    0 0 0  0;
          0 1 0 0  zC 0  0    zC^2 0    0 0 0  0;
          0 0 1 0  0  zC 0    0    zC^2 0 0 0  0;
          0 0 0 0  0  0  0    0    0    1 0 zC 0;
          0 0 0 0  0  0  0    0    0    0 1 0  zC;];
    
    %% determinant of mu
    %%% ShellInt: 1,PLATE; 2, CYLINDER; 3, SPHERE
    switch ShellInt
        case 1  % 1,PLATE
            mu = 1;
            %%% s1 = |g^{1}|,s2 = |g^{2}|, in the terms including zC only
            s1 = 1;         s2 = 1;     
        case 2  % 2, CYLINDER
            mu = 1 + zC/R;
            s1 = 1;         s2 = 1/(R+zC);
%             s1 = 1;         s2 = 1;
        case 3  % 3, SPHERE
            mu = (1 + zC/R)^2;
            s1 = R/(R+zC);      s2 = 1/(R+zC);
    end
    NormS = diag([s1*s1,s2*s2,s1*s2,s2,s1]);
    %%%%%%%%%%
    Hu = Hu + GP_3(i,2)*Density*Zu'*Zu*mu*h;
    H_C = H_C + GP_3(i,2)*H1'*NormS'*Mate_C*NormS*H1*mu*h;   
%     H_C = H_C + GP_3(i,2)*H1'*Mate_C*H1*mu*h;   
    HeM = HeM - GP_3(i,2)*Mate_eM*NormS*H1*mu*h;
%     HeM = HeM - GP_3(i,2)*Mate_eM*H1*mu*h;
    HgM = HgM - GP_3(i,2)*Mate_gM*mu*h;
    Hq = Hq - GP_3(i,2)*Mate_q*NormS*H1*mu*h;
%     Hq = Hq - GP_3(i,2)*Mate_q*H1*mu*h;
    Hk = Hk - GP_3(i,2)*Mate_k*mu*h;
    Hr = Hr - GP_3(i,2)*Mate_r*mu*h;
    Hld = Hld - GP_3(i,2)*Mate_Lamdat*NormS*H1*mu*h;
%     Hld = Hld - GP_3(i,2)*Mate_Lamdat*H1*mu*h;
    HpE = HpE - GP_3(i,2)*PE*mu*h;
    HpM = HpM - GP_3(i,2)*PM*mu*h;
    Hc = Hc - GP_3(i,2)*Mate_c*mu*h;
%     Hc = Hc - GP_3(i,2)*MC*mu*h;
end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Surface integration
for i=1:length(GP_3(:,1))
    for j=1:length(GP_3(:,1))
        zL = GP_3(i,1);
        zC = zC_m + h*zL;
        
        xL=GP_3(i,1);
        yL=GP_3(j,1);
        xC = xC_m + a*xL;        
        %% Coordinates adaption
        %%% ShellInt: 1,PLATE; 2, CYLINDER; 3, SPHERE
        switch ShellInt
            case 1      % PLATE
                a1 = 1;         a2 = 1;     %% a1 = a^{11},a1 = a^{22}
                b1 = 0;         b2 = 0;     %% b1 = a_{11},a1 = a_{22}
                t1 = 0;         t2 = 0;     %%
                k1 = 1;         k2 = 0;     %% coeffient for Theta
                %%% s1 = |g^{1}|,s2 = |g^{2}|, in the terms including xC
                s1 = 1;         s2 = 1;     
            case 2      % CYLINDER
                a1 = 1;         a2 = 1/(R^2);
                b1 = 0;         b2 = -R;
                t1 = 0;         t2 = 0;
                k1 = R;         k2 = 0;
                s1 = 1;         s2 = 1; 
%                 s1 = 1;         s2 = 1/(R+zC);
            case 3      % SPHERE
                a1 = 1;             a2 = 1/(R^2*(sin(xC/R))^2);
                b1 = -1/R;          b2 = -R*(sin(xC/R))^2;
                t1 = -cot(xC/R)/R;  t2 = R*sin(xC/R)*cos(xC/R);
                k1 = R*sin(xC/R);   k2 = cos(xC/R);
                s1 = 1;             s2 = 1/(sin(xC/R));
        end
        %%%%%%%%%%%%%%%%%%%
        c1 = a1*b1;     c2 = a2*b2;
        Sqrt_a = sqrt(1/(a1*a2));
        
        %% Define Noem and Kth matrices
        Norm = diag([s1*s1,s2*s2,s1*s2,s1*s1,s2*s2,s1*s2,s1*s1,s2*s2,s1*s2, ...
                     s2,s1,s2,s1]);
        Kth = diag([1,1,k1,k1,1,1,1,1,k1,k1,1,k1,1,1,k1]);
        Kth(3,12) = k2;
        Kth(9,15) = k2;
        % Kth_new
        Kth_new = diag([1,1,k1,k1,1,1,1,1,k1,k1,1,1,1,k1,1,1,k1,1]);
        Kth_new(3,14) = k2;
        Kth_new(9,17) = k2;
%         Kth = [1  0  0  0  0  0  0  0  0  0  0  0  0  0  0;
%                0  1  0  0  0  0  0  0  0  0  0  0  0  0  0;
%                0  0  k1 0  0  0  0  0  0  0  0  k2 0  0  0;
%                0  0  0  k1 0  0  0  0  0  0  0  0  0  0  0;
%                0  0  0  0  1  0  0  0  0  0  0  0  0  0  0;
%                0  0  0  0  0  1  0  0  0  0  0  0  0  0  0;
%                0  0  0  0  0  0  1  0  0  0  0  0  0  0  0;
%                0  0  0  0  0  0  0  1  0  0  0  0  0  0  0;
%                0  0  0  0  0  0  0  0  k1 0  0  0  0  0  k2;
%                0  0  0  0  0  0  0  0  0  k1 0  0  0  0  0;
%                0  0  0  0  0  0  0  0  0  0  1  0  0  0  0;
%                0  0  0  0  0  0  0  0  0  0  0  k1 0  0  0;
%                0  0  0  0  0  0  0  0  0  0  0  0  1  0  0;
%                0  0  0  0  0  0  0  0  0  0  0  0  0  1  0;
%                0  0  0  0  0  0  0  0  0  0  0  0  0  0  k1];           
        %% Kv matrix
        Kv = diag([1,k1,1,1,k1]);
        
        %% shape function
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
        %%% Jacobian
        Jacobian = zeros(2,2);
        for ii=1:2  %Jacobian的行和列
            for jj=1:2  %偏导的坐标轴（Jacobian对应的列）
                for kk=1:8  %节点序号
                    Jacobian(ii,jj) =  Jacobian(ii,jj) + Jacobian_DN(kk,ii)*XNode(kk,jj);
                end
            end
        end
        detJ=det(Jacobian);
        DN = zeros(8,2);                
        for k = 1:NodePerElem
            DN(k,:) = (Jacobian\[Jacobian_DN(k,1);Jacobian_DN(k,2)])';
        end
        %% Nu matrix
        IM = eye(DOFPerNodeM,DOFPerNodeM);              %IM(5,5)
        Nu = [N(1)*IM, N(2)*IM, N(3)*IM, N(4)*IM, ...
              N(5)*IM, N(6)*IM, N(7)*IM, N(8)*IM];    %Nu(5,40)

        %% LNu matrix, LNu = Lu*Nu
        IM = [1 0 0 0 0;
              0 1 0 0 0;
              0 0 1 0 0;
              0 0 0 1 0;
              0 0 0 0 1 ];
        %%%
        LNuTemp = [DN(1,1)*IM,DN(2,1)*IM,DN(3,1)*IM,DN(4,1)*IM, ...
                   DN(5,1)*IM,DN(6,1)*IM,DN(7,1)*IM,DN(8,1)*IM ];
        %%%
        LNu(1,:) = LNuTemp(1,:);
        LNu(3,:) = LNuTemp(2,:);
        LNu(5,:) = LNuTemp(3,:);
        LNu(7,:) = LNuTemp(4,:);
        LNu(9,:) = LNuTemp(5,:);
        LNu_new(1,:) = LNuTemp(1,:);
        LNu_new(3,:) = LNuTemp(2,:);
        LNu_new(5,:) = LNuTemp(3,:);
        LNu_new(7,:) = LNuTemp(4,:);
        LNu_new(9,:) = LNuTemp(5,:);
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
        
        LNu_new(2,:) = LNuTemp(1,:);
        LNu_new(4,:) = LNuTemp(2,:);
        LNu_new(6,:) = LNuTemp(3,:);
        LNu_new(8,:) = LNuTemp(4,:);
        LNu_new(10,:) = LNuTemp(5,:);
        LNu_new(11,:) = Nu(1,:);
        LNu_new(12,:) = Nu(2,:);
        LNu_new(13,:) = Nu(3,:);
        LNu_new(14,:) = Nu(4,:);
        LNu_new(15,:) = Nu(5,:);
%         LNu_new(16,:) = Nu(6,:);
%         LNu_new(17,:) = Nu(7,:);
%         LNu_new(18,:) = Nu(8,:);
        %% A0 matrix
        A0(1,[1,13]) = [1, -b1];
        A0(2,[4,11,13]) = [1, t2 , -b2];           
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
        %% A0_new matrix
        A0_new(1,[1,15]) = [1, -b1];
        A0_new(2,[4,13,15]) = [1, t2 , -b2];           
        A0_new(3,[2,3,14]) = [1, 1, 2*t1];
        A0_new(4,[1,7,15,18]) = [-a1*b1, 1, a1*b1^2, -b1];
        A0_new(5,[4,10,13,15,16,18]) = [-a2*b2, 1, -a2*b2*t2, a2*b2^2, t2, -b2];
        A0_new(6,[2,3,8,9,14,17]) = [-a1*b1,-a2*b2,1,1,-a2*b2*t1-a1*b1*t1,2*t1];
        A0_new(7,[7,18]) = [-a1*b1, a1*b1^2];
        A0_new(8,[10,16,18]) = [-a2*b2, -a2*b2*t2, a2*b2^2];
        A0_new(9,[8,9,17]) = [-a1*b1, -a2*b2, -a2*b2*t1-a1*b1*t1];
        A0_new(10,[6,14,17]) = [1, c2, 1];
        A0_new(11,[5, 13, 16]) = [1, c1, 1];
        A0_new(12,[12,15]) = [1, c2-a2*b2];
        A0_new(13,[11,16]) = [1, c1-a1*b1];
        %% A0_C: A0 in curvalinear coordinates
        %%% A0_C =  Norm*A0*Kth;        
        %% Bl matrix
        Bl = Norm*A0*Kth*LNu;
%         Bl = A0*LNu;
        %%%%%%%%%%%%%%       
        %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     
        Muu = Muu + GP_3(i,2)*GP_3(j,2)*Nu'*Hu*Nu*Sqrt_a*detJ;
        Kuu = Kuu + GP_3(i,2)*GP_3(j,2)*Bl'*H_C*Bl*Sqrt_a*detJ;
%         Kuu = Kuu + GP_3(i,2)*GP_3(j,2)*Bl'*H_C*Bl*detJ;
        KufM = KufM + GP_3(i,2)*GP_3(j,2)*Bl'*HeM'*BfM*Sqrt_a*detJ;
        KffM = KffM + GP_3(i,2)*GP_3(j,2)*BfM'*HgM*BfM*Sqrt_a*detJ;
        
        Kuz = Kuz + GP_3(i,2)*GP_3(j,2)*Bl'*Hq'*Bz*Sqrt_a*detJ;
        Kfz = Kfz + GP_3(i,2)*GP_3(j,2)*BfM'*Hk*Bz*Sqrt_a*detJ;
        Kzz = Kzz + GP_3(i,2)*GP_3(j,2)*Bz'*Hr*Bz*Sqrt_a*detJ;
        
        Kut = Kut + GP_3(i,2)*GP_3(j,2)*Bl'*Hld'*Bt*Sqrt_a*detJ;
%         Kut = Kut + GP_3(i,2)*GP_3(j,2)*Bl'*Hld'*Bt*detJ;
        Kft = Kft + GP_3(i,2)*GP_3(j,2)*BfM'*HpE*Bt*Sqrt_a*detJ;
        Kzt = Kzt + GP_3(i,2)*GP_3(j,2)*Bz'*HpM*Bt*Sqrt_a*detJ;
        Ktt = Ktt + GP_3(i,2)*GP_3(j,2)*Bt'*Hc*Bt*Sqrt_a*detJ;
%         Ktt = Ktt + GP_3(i,2)*GP_3(j,2)*Bt'*Hc*Bt*detJ;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    end
end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
KfuM = KufM';
Kzf = Kfz';
Kzu = Kuz';
Ktf = Kft';
Ktu = Kut';
Ktz = Kzt';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Calculate one layer----------------------------------------------------End
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Construct ElemMatr, return value

 ElemMatr = struct('Muu',Muu,'Kuu',Kuu',...
 'KufM',KufM,'KfuM',KfuM,'KffM',KffM,'Kfz',Kfz,'Kzf',Kzf,'Kzz',Kzz,'Kuz',Kuz,'Kzu',Kzu, ...
                   'Fui',Fui,'Fus',Fus,'Fuc',Fuc, ...
                   'Kut',Kut,'Kft',Kft,'Ktu',Ktu,'Ktf',Ktf,...
                   'Ktz',Ktz,'Kzt',Kzt,'Ktt',Ktt,'GfiM',GfiM,'GfM',GfM,'Mzi',Mzi,'Mz',Mz,'Ft',Ft);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('::SF_ElemComptLIN851T5MFC_V4--%s-------------EleIndex=%d\n', ...
                ShellStr,EleIndex);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end


