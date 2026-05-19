%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Subfuntion SF_ElemComptLIN851T5MFC
%Calculate Muu,Kuu,Kuf,Kff for one element
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ElemMatr]=SF_ElemComptLIN851T5MFC_V4(EleIndex,MatePropCurrLay, ...
                                         FinitElemInfo,IntegSchem)
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
Mate_c = MatePropCurrLay.c;
Mate_e = MatePropCurrLay.e;
Mate_g = MatePropCurrLay.g;
Density = MatePropCurrLay.Density;
Lay_zC = MatePropCurrLay.Lay_zC;
IsSmtLay = MatePropCurrLay.IsSmtLay;
hE = MatePropCurrLay.hE;

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
NumSmtLay = ElemType(3);
DOFPerSmtLayE = ElemType(4);

DOFPerElemM = NodePerElem*DOFPerNodeM;
DOFPerElemE = NumSmtLay*DOFPerSmtLayE;
DOFTotalM = NumNode*DOFPerNodeM;
DOFTotalE = NumElem*DOFPerElemE;

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
Kuf = zeros(DOFPerElemM,DOFPerElemE); 
Kff = zeros(DOFPerElemE,DOFPerElemE);

Fui = zeros(DOFPerElemM,1); 
Fus = zeros(DOFPerElemM,1); 
Fuc = zeros(DOFPerElemM,1); 
Gfi = zeros(DOFPerElemE,1);
Gf = zeros(DOFPerElemE,1);

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
Hc = zeros(13,13);
He = zeros(NumSmtLay,13);
Hg = zeros(NumSmtLay,NumSmtLay);
A0 = zeros(13,15);
LNu = zeros(15,40);

%% Bf
Bf = zeros(NumSmtLay,NumSmtLay);
for i = 1:NumSmtLay
    if IsSmtLay == 1
        Bf(i,i) = -1/(hE);
    else
        Bf(i,i) = 0;
    end
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
        case 3  % 3, SPHERE
            mu = (1 + zC/R)^2;
            s1 = R/(R+zC);      s2 = 1/(R+zC);
    end
    NormS = diag([s1*s1,s2*s2,s1*s2,s2,s1]);
    %%%%%%%%%%
    Hu = Hu + GP_3(i,2)*Density*Zu'*Zu*mu*h;
    Hc = Hc + GP_3(i,2)*H1'*NormS'*Mate_c*NormS*H1*mu*h;
    He = He - GP_3(i,2)*Mate_e*NormS*H1*mu*h;
    Hg = Hg - GP_3(i,2)*Mate_g*mu*h;
end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Surface integration
for i=1:length(GP_3(:,1))
    for j=1:length(GP_3(:,1))
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
            case 3      % SPHERE
                a1 = 1;             a2 = 1/(R^2*(sin(xC/R))^2);
                b1 = -1/R;          b2 = -R*(sin(xC/R))^2;
                t1 = -cot(xC/R)/R;  t2 = R*sin(xC/R)*cos(xC/R);
                k1 = R*sin(xC/R);   k2 = cos(xC/R);
                s1 = 1;             s2 = 1/(sin(xC/R));
        end
        %%%%%%%%%%%%%%%%%%%
        c1 = a1*b1;     c2 = a2*b2;         %%
        Sqrt_a = sqrt(1/(a1*a2));
        
        %% Define Noem and Kth matrices
        Norm = diag([s1*s1,s2*s2,s1*s2,s1*s1,s2*s2,s1*s2,s1*s1,s2*s2,s1*s2, ...
                     s2,s1,s2,s1]);
        Kth = diag([1,1,k1,k1,1,1,1,1,k1,k1,1,k1,1,1,k1]);
        Kth(3,12) = k2;
        Kth(9,15) = k2;
        
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
        DN(1,1) = 1/(4*a)*(1-yL)*(2*xL+yL);
        DN(1,2) = 1/(4*b)*(1-xL)*(xL+2*yL);
        DN(2,1) = 1/(4*a)*(1-yL)*(2*xL-yL);
        DN(2,2) = 1/(4*b)*(1+xL)*(-xL+2*yL);
        DN(3,1) = 1/(4*a)*(1+yL)*(2*xL+yL);
        DN(3,2) = 1/(4*b)*(1+xL)*(xL+2*yL);
        DN(4,1) = 1/(4*a)*(1+yL)*(2*xL-yL);
        DN(4,2) = 1/(4*b)*(1-xL)*(-xL+2*yL);
        DN(5,1) = -1/(a)*xL*(1-yL);
        DN(5,2) = -1/(2*b)*(1-xL^2);
        DN(6,1) = 1/(2*a)*(1-yL^2);
        DN(6,2) = -1/(b)*(1+xL)*yL;
        DN(7,1) = -1/(a)*xL*(1+yL);
        DN(7,2) = 1/(2*b)*(1-xL^2);
        DN(8,1) = -1/(2*a)*(1-yL^2);
        DN(8,2) = -1/(b)*(1-xL)*yL;

        %% Nu matrix
        IM = eye(DOFPerNodeM,DOFPerNodeM);              %IM(5,5)
        Nu = [N(1)*IM, N(2)*IM, N(3)*IM, N(4)*IM, ...
              N(5)*IM, N(6)*IM, N(7)*IM, N(8)*IM];

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
               
        %% A0_C: A0 in curvalinear coordinates
        %%% A0_C =  Norm*A0*Kth;
        
        %% Bl matrix
        Bl = Norm*A0*Kth*LNu;
        
        %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        Muu = Muu + GP_3(i,2)*GP_3(j,2)*Nu'*Hu*Nu*Sqrt_a*a*b;
        Kuu = Kuu + GP_3(i,2)*GP_3(j,2)*Bl'*Hc*Bl*Sqrt_a*a*b;
        Kuf = Kuf + GP_3(i,2)*GP_3(j,2)*Bl'*He'*Bf*Sqrt_a*a*b;
        Kff = Kff + GP_3(i,2)*GP_3(j,2)*Bf'*Hg*Bf*Sqrt_a*a*b;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    end
end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
Kfu = Kuf';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Calculate one layer----------------------------------------------------End
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Construct ElemMatr, return value
ElemMatr = struct('Muu',Muu,'Kuu',Kuu','Kuf',Kuf,'Kfu',Kfu,'Kff',Kff, ...
                  'Fui',Fui,'Fus',Fus,'Fuc',Fuc,'Gfi',Gfi,'Gf',Gf);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('::SF_ElemComptLIN851T5MFC_V4--%s-------------EleIndex=%d\n', ...
                ShellStr,EleIndex);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end


