%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Subfuntion SF_ElemComptNL851T5MFC_V3
%Calculate Muu,Kuu,Kuf,Kff for one element
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ElemMatr]=SF_ElemComptNL851T5MEEP_V4(EleIndex,MatePropCurrLay, ...
                                           MateProp,LayIndex,FinitElemInfo,TQFdva,IntegSchem,Totalthickness,ThermalNL)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%fs=[0;0;1],external uniform load,[u,v,w]

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Coordinates specification
%%% xG,yG,zG: Global coordinates
%%% xC,yC,zC: Curvalinear coordinates
%%% xL,yL,zL: Local coordinates

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
%%% Finite Element information
ElemType = FinitElemInfo.ElemType;
Element = FinitElemInfo.Element;
Node = FinitElemInfo.Node;
ShellTheory = FinitElemInfo.ShellTheory;

[ShellInt,ShellStr] = SF_ShellNotation(ShellTheory(1,1));
[TheoryInt,TheoryStr] = SF_TheoryNotation(ShellTheory(2,1));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Material properties for current layer
Mate_c = MatePropCurrLay.c;
Mate_eM = MatePropCurrLay.eM;
Mate_gM = MatePropCurrLay.gM;
 Mate_q = MatePropCurrLay.q;
 Mate_k = MatePropCurrLay.k;
 Mate_r = MatePropCurrLay.r;
Density = MatePropCurrLay.Density;
Lay_zC = MatePropCurrLay.Lay_zC;
IsSmtLay = MatePropCurrLay.IsSmtLay;
hE = MatePropCurrLay.hE;
Mate_PyroE = MatePropCurrLay.PyroE;%PyroE,Lamdat
Mate_PyroM = MatePropCurrLay.PyroM;%PyroM,Lamdat
Mate_Lamdat = MatePropCurrLay.Lamdat;
totalh = Totalthickness.totalh;
HC=Totalthickness.HC;
%%
%%% Get TQd,TQv,TQa
TQd = TQFdva.TQd;
% TQv = TQFdva.TQv;
TQa = TQFdva.TQa;
TPhiaM = TQFdva.TPhiaM;
TPhisM = TQFdva.TPhisM;
TMga = TQFdva.TMga;
TMgs= TQFdva.TMgs;
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Calculate ElementNum, Nodenum
%%% NumElem: Total number of element
%%% NumNode: Total number of node
% NumElem = length(Element(:,1));
% NumNode = length(Node(:,1));

%% Calculate dofs and matrices size
%%% ElemType = [Node/Elem DOF/Node NumSmtLay DOF/SmtLay NumLay]

NodePerElem = ElemType(1);
DOFPerNodeM = ElemType(2);
%NumLay = ElemType(3);
 DOFPerMEELay = ElemType(4);  
 NumMEELay = ElemType(5); 


 
DOFPerElemM = NodePerElem*DOFPerNodeM;
DOFPerElemMEE = NumMEELay*DOFPerMEELay;  % Number of MEE dof per element


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Calculate one layer----------------------------------------------Start
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initiate global matrices for mass, stiffness......
%%% Nonlinear case
Muu1 = zeros(DOFPerElemM,DOFPerElemM); 
Kuu1 = zeros(DOFPerElemM,DOFPerElemM);  
Kg1 = zeros(DOFPerElemM,DOFPerElemM);    

KufM1 = zeros(DOFPerElemM,DOFPerElemMEE); 
KffM1 = zeros(DOFPerElemMEE,DOFPerElemMEE);
Kuz1 = zeros(DOFPerElemM,DOFPerElemMEE);
Kfz1=zeros(DOFPerElemMEE,DOFPerElemMEE);
Kzf1=zeros(DOFPerElemMEE,DOFPerElemMEE);
Kzz1=zeros(DOFPerElemMEE,DOFPerElemMEE);
Kut1 = zeros(DOFPerElemM,2);
Kft1 = zeros(DOFPerElemMEE,2);
Kzt1 = zeros(DOFPerElemMEE,2);
Ktf1 = zeros(2,DOFPerElemMEE);
Ktz1 = zeros(2,DOFPerElemMEE);

%%% In-balance force,machenical part
Fuu1 = zeros(DOFPerElemM,1); 
FufM1 = zeros(DOFPerElemM,1);
Fuz1 = zeros(DOFPerElemM,1);
Fut1 = zeros(DOFPerElemM,1);
%%% In-balance force,MEE part
FfuM1 = zeros(DOFPerElemMEE,1);
FffM1 = zeros(DOFPerElemMEE,1);
Fzu1 = zeros(DOFPerElemMEE,1);
Fzz1 = zeros(DOFPerElemMEE,1);
Ffz1=zeros(DOFPerElemMEE,1);
Fzf1=zeros(DOFPerElemMEE,1);
%%% In-balance force, thermal part
Fft1 = zeros(DOFPerElemMEE,1);
Fzt1 = zeros(DOFPerElemMEE,1);

%%% External force
Fus = zeros(DOFPerElemM,1); 
Fuc = zeros(DOFPerElemM,1); 
GfM = zeros(DOFPerElemMEE,1);
Mz=zeros(DOFPerElemMEE,1);
%% Define element displacement vector Qde,
Qde = zeros(DOFPerElemM,1);
Qae = zeros(DOFPerElemM,1);
for i = 1:NodePerElem
    TQIndex = (Element(EleIndex,i)-1)*DOFPerNodeM+1: ...
               Element(EleIndex,i)*DOFPerNodeM;
    QeIndex = (i-1)*DOFPerNodeM+1:i*DOFPerNodeM;
    Qde(QeIndex,1) = TQd(TQIndex,1);
    Qae(QeIndex,1) = TQa(TQIndex,1);
end

%% Define voltage vector of element, PhiaeM, PhiseM
PhiaeM = zeros(DOFPerElemMEE,1);
PhiseM = zeros(DOFPerElemMEE,1);
TPhIndexM = (EleIndex-1)*DOFPerElemMEE+1:EleIndex*DOFPerElemMEE;
PheIndex = 1:DOFPerElemMEE;
PhiaeM(PheIndex) = TPhiaM(TPhIndexM);
PhiseM(PheIndex) = TPhisM(TPhIndexM);
%% Define voltage vector of element, Mgae, Mgse
Mgae = zeros(DOFPerElemMEE,1);
Mgse= zeros(DOFPerElemMEE,1);
TPhIndexMM = (EleIndex-1)*DOFPerElemMEE+1:EleIndex*DOFPerElemMEE;
PheIndex = 1:DOFPerElemMEE;
Mgae(PheIndex) = TMga(TPhIndexMM);
Mgse(PheIndex) = TMgs(TPhIndexMM);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DeltaT=zeros(2,1);
%% relation between local coordinate and globle coordinate x,y
XNode = zeros(NodePerElem,3);
for j = 1:NodePerElem
    [Row,Column]=find(Node(:,1)==Element(EleIndex,j));
    XNode(j,1:3)=Node(Row,2:4);    %XNode,globle coordinate of node 
end

%%% relation between local coordinate and globle coordinate x,y
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
xC_m = (XNode(2,1)+XNode(1,1))/2;       % xC_m: middle position of xC
zC_m = (Lay_zC(1)+Lay_zC(2))/2;         %zC_m middle line of layer

%% Resultant matrices
Hu = zeros(5,5);
Hc = zeros(13,13);
HeM = zeros(NumMEELay,13);
HgM = zeros(NumMEELay,NumMEELay);
Hq = zeros(NumMEELay,13);
Hk = zeros(NumMEELay,NumMEELay);
Hr = zeros(NumMEELay,NumMEELay); 
 Hld = zeros(13,1);
 HpE = zeros(DOFPerElemMEE,1);
 HpM = zeros(DOFPerElemMEE,1);
A0 = zeros(13,15);
% An = zeros(13,15); 
% Sug = zeros(15,15);     % Sug = Suu + Suf
Nt = zeros(15,40);     % Nt: derivative of shape function matrix
%% Bt %温度的分布规律
Bt = zeros(1,2);
switch ThermalNL
    case 0    %均匀分布
     Bt(1,1) = -1;
     Bt(1,2) = 1;
    case 1     %线性
     Bt(1,1) = 1/2 - zC_m/totalh;
     Bt(1,2) = 1/2 + zC_m/totalh;
    case 2      %正弦
     Bt(1,1) = cos(pi/2*(0.5+zC_m/totalh));
     Bt(1,2) = 1 - cos(pi/2*(0.5+zC_m/totalh));
     case 3   %%%热传导   
         HC1=0;
         for i = 1:LayIndex
             Mate_Current_layer = MateProp{i,1};
             HC_Current = Mate_Current_layer.HC_Current;  
             cc=1/HC_Current;
            HC1 = HC1 + cc*LayHigh;
         end        
        Bt(1,1) = 1-HC1/HC;
        Bt(1,2) = HC1/HC;
end
%% BfP，BfM,Bz
BfM = zeros(NumMEELay,NumMEELay);
Bz = zeros(NumMEELay,NumMEELay);

   for i=1:NumMEELay
    if  IsSmtLay == 2 
    BfM(i,i)=-1/(hE);
    Bz(i,i)=-1/(hE); 
    else
    BfM(i,i)=0;
    Bz(i,i)=0; 
    end
   end
%% PE
    PE = zeros(DOFPerElemMEE,1);
   for i = 1:DOFPerElemMEE
       PE(i,1) = Mate_PyroE;
   end
   %% PM
    PM = zeros(DOFPerElemMEE,1);
   for i = 1:DOFPerElemMEE
       PM(i,1) = Mate_PyroM;
   end
%% Resultant matrices, Hu, Hc, He, Hg
for i=1:length(GP_3(:,1))
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
    %%% Normalization transformation matrix of strain, part of ...
    Ken = diag([s1*s1,s2*s2,s1*s2,s2,s1]);
    %%%%%%%%%%
    Hu = Hu + GP_3(i,2)*Density*(Zu'*Zu)*mu*h;
    Hc = Hc + GP_3(i,2)*H1'*Ken'*Mate_c*Ken*H1*mu*h;
    HeM = HeM - GP_3(i,2)*Mate_eM*Ken*H1*mu*h;
    HgM = HgM - GP_3(i,2)*Mate_gM*mu*h;
    Hq = Hq - GP_3(i,2)*Mate_q*Ken*H1*mu*h;
    Hk = Hk - GP_3(i,2)*Mate_k*mu*h;
    Hr = Hr - GP_3(i,2)*Mate_r*mu*h; 
    Hld = Hld - GP_3(i,2)*H1'*Mate_Lamdat*mu*h;
    HpE = HpE - GP_3(i,2)*PE*mu*h;  
    HpM = HpM - GP_3(i,2)*PM*mu*h;     
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
                a1 = 1;         a2 = 1/(R^2*(sin(xC/R))^2);
                b1 = -1/R;      b2 = -R*(sin(xC/R))^2;
                t1 = -cot(xC/R)/R;  t2 = R*sin(xC/R)*cos(xC/R);
                k1 = R*sin(xC/R); k2 = cos(xC/R);
                s1 = 1;         s2 = 1/(sin(xC/R));
        end
        %%%%%%%%%%%%%%%%%%%
        c1 = a1*b1;     c2 = a2*b2; %%
        Sqrt_a = sqrt(1/(a1*a2));
        CurvPara = struct('a1',a1,'a2',a2,'b1',b1,'b2',b2, ...
                          'c1',c1,'c2',c2,'t1',t1,'t2',t2);
        
        %% Define Noem and Kth matrices
        Norm = diag([s1*s1,s2*s2,s1*s2,s1*s1,s2*s2,s1*s2,s1*s1,s2*s2,s1*s2, ...
                     s2,s1,s2,s1]);
        Kth = diag([1,1,k1,k1,1,1,1,1,k1,k1,1,k1,1,1,k1]);
        Kth(3,12) = k2;
        Kth(9,15) = k2; 
         
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
        DN = zeros(8,2);    
         detJ=det(Jacobian);
        for k = 1:NodePerElem
            DN(k,:) = (Jacobian\[Jacobian_DN(k,1);Jacobian_DN(k,2)])';
        end

        %% Nu matrix
        IM = eye(DOFPerNodeM,DOFPerNodeM);              %IM(5,5)
        Nu = [N(1)*IM, N(2)*IM, N(3)*IM, N(4)*IM, ...
              N(5)*IM, N(6)*IM, N(7)*IM, N(8)*IM];

        %% Nt matrix
        IM = [1 0 0 0 0;
              0 1 0 0 0;
              0 0 1 0 0;
              0 0 0 1 0;
              0 0 0 0 1 ];
        %%%
        LNuTemp = [DN(1,1)*IM,DN(2,1)*IM,DN(3,1)*IM,DN(4,1)*IM, ...
                   DN(5,1)*IM,DN(6,1)*IM,DN(7,1)*IM,DN(8,1)*IM ];
        %%%
        Nt(1,:) = LNuTemp(1,:);
        Nt(3,:) = LNuTemp(2,:);
        Nt(5,:) = LNuTemp(3,:);
        Nt(7,:) = LNuTemp(4,:);
        Nt(9,:) = LNuTemp(5,:);
        %%%
        LNuTemp = [DN(1,2)*IM,DN(2,2)*IM,DN(3,2)*IM,DN(4,2)*IM, ...
                   DN(5,2)*IM,DN(6,2)*IM,DN(7,2)*IM,DN(8,2)*IM ];
        %%%
        Nt(2,:) = LNuTemp(1,:);
        Nt(4,:) = LNuTemp(2,:);
        Nt(6,:) = LNuTemp(3,:);
        Nt(8,:) = LNuTemp(4,:);
        Nt(10,:) = LNuTemp(5,:);
        Nt(11,:) = Nu(1,:);
        Nt(12,:) = Nu(2,:);
        Nt(13,:) = Nu(3,:);
        Nt(14,:) = Nu(4,:);
        Nt(15,:) = Nu(5,:);
        
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
        
        %% Theta_u1 in configuration 1
        Theta_u1 = Nt*Qde;      %%% Physical value
        
        %% Acv1, acceleration of vector {v}, in configuration1
%         Acv1 = Nu*Qae;
        
        %% Gt matrix
        Gt = Kth;
        
        %% Gv matrix
        % Gv = Kv;
        
        %% Theta1, in configuration 1 (Theta_hat1=Theta_u1)
        Theta1 = Kth*Theta_u1;
        
        %% An matrix
        switch TheoryInt
            case 1      %%% RVK5
                [An] = SF_GetAnMatr_RVK5(Theta1,CurvPara);
            case 2      %%% MRT5
                [An] = SF_GetAnMatr_MRT5(Theta1,CurvPara);
            case 3      %%% LRT5
                [An] = SF_GetAnMatr_LRT5(Theta1,CurvPara);
            case 4      %%% LRT56
                
        end
        
        
        %% An_C
        %An_C = Norm*An*Kth;
        
        %% Bl matrix
        Bl = Norm*(A0 + An)*Gt*Nt;
        
       %% Sug = Sug + Suf + Suz  matrix
        RS1 = Norm*(A0 + 1/2*An)*Theta1;
        RL1 = Hc*RS1;                   % Hc*S
        REaM1 = BfM*PhiaeM;                % for actuator
        REsM1 = BfM*PhiseM;                % for sensor
        REaMZ1 = Bz*Mgae;                % for actuator
        REsMZ1 = Bz*Mgse;                % for sensor  
        RET=Bt*DeltaT ;
         RDM1 = HeM'*REaM1;    % HeM*E
        RDMZ1=Hq'*REaMZ1; 
        RET1=Hld*RET;
        RLD1 = RL1+ RDM1+RDMZ1+RET1;
        RNLD1 = Norm'*RLD1;   
         switch TheoryInt
            case 1      %%% RVK5
                [Sug] = SF_GetSugMatr_RVK5(RNLD1,CurvPara);
            case 2      %%% MRT5
                [Sug] = SF_GetSugMatr_MRT5(RNLD1,CurvPara);
            case 3      %%% LRT5
                [Sug] = SF_GetSugMatr_LRT5(RNLD1,CurvPara);
            case 4      %%% LRT56   
             
        end
        
        %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        Muu1 = Muu1 + GP_3(i,2)*GP_3(j,2)*Nu'*Hu*Nu*Sqrt_a*detJ;
        %%% Fut1,in-lalance initial force
        %Fut1 = Fut1 + GP_3(i,2)*GP_3(j,2)*Nu'*Hu*Acv1*Sqrt_a*detJ;
        %%% Kuu
        Kuu1 = Kuu1 + GP_3(i,2)*GP_3(j,2)*Bl'*Hc*Bl*Sqrt_a*detJ;
        Kg1 = Kg1 + GP_3(i,2)*GP_3(j,2)*Nt'*Gt'*Sug*Gt*Nt*Sqrt_a*detJ;
        %%% Kuf,Kff
        KufM1 = KufM1 + GP_3(i,2)*GP_3(j,2)*Bl'*HeM'*BfM*Sqrt_a*detJ;
        KffM1 = KffM1 + GP_3(i,2)*GP_3(j,2)*BfM'*HgM*BfM*Sqrt_a*detJ;
        Kuz1 = Kuz1 + GP_3(i,2)*GP_3(j,2)*Bl'*Hq'*Bz*Sqrt_a*detJ;
        Kfz1 = Kfz1 + GP_3(i,2)*GP_3(j,2)*BfM'*Hk*Bz*Sqrt_a*detJ;
        Kzz1 = Kzz1 + GP_3(i,2)*GP_3(j,2)*Bz'*Hr*Bz*Sqrt_a*detJ;
        
        Kut1 = Kut1 + GP_3(i,2)*GP_3(j,2)*Bl'*Hld*Bt*Sqrt_a*detJ;
        Kft1 = Kft1 + GP_3(i,2)*GP_3(j,2)*BfM'*HpE*Bt*Sqrt_a*detJ;
        Kzt1 = Kzt1 + GP_3(i,2)*GP_3(j,2)*Bz'*HpM*Bt*Sqrt_a*detJ;
        
        %%% In-balance force
        Fuu1 = Fuu1 + GP_3(i,2)*GP_3(j,2)*Bl'*Hc*RS1*Sqrt_a*detJ;
        FufM1 = FufM1 + GP_3(i,2)*GP_3(j,2)*Bl'*HeM'*REaM1*Sqrt_a*detJ;
        FfuM1 = FfuM1 + GP_3(i,2)*GP_3(j,2)*BfM'*HeM*RS1*Sqrt_a*detJ;
        Fuz1 = Fuz1 + GP_3(i,2)*GP_3(j,2)*Bl'*Hq'*REaMZ1*Sqrt_a*detJ;
        Fzu1 = Fzu1 + GP_3(i,2)*GP_3(j,2)*Bz'*Hq*RS1*Sqrt_a*detJ;
         
        FffM1 = FffM1 + GP_3(i,2)*GP_3(j,2)*BfM'*HgM*REsM1*Sqrt_a*detJ;
        Ffz1 = Ffz1+ GP_3(i,2)*GP_3(j,2)*BfM'*Hk*REsMZ1*Sqrt_a*detJ;
        Fzf1 = Fzf1+ GP_3(i,2)*GP_3(j,2)*Bz'*Hk*REsM1*Sqrt_a*detJ;
        Fzz1 = Fzz1 + GP_3(i,2)*GP_3(j,2)*Bz'*Hr*REsMZ1*Sqrt_a*detJ;
       
        Fut1= Fut1+GP_3(i,2)*GP_3(j,2)*Bl'*Hld*RET*Sqrt_a*detJ;
        Fft1=Fft1+GP_3(i,2)*GP_3(j,2)*BfM'*HpE*RET*Sqrt_a*detJ;
        Fzt1=Fzt1+GP_3(i,2)*GP_3(j,2)*Bz'*HpM*RET*Sqrt_a*detJ;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    end
end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
Muu = Muu1;
Kuu = Kuu1+Kg1;
KufM = KufM1;
KfuM = KufM1';
Kuz=Kuz1;
Kzu=Kuz1';
Kut=Kut1;
Ktu=Kut1';
KffM = KffM1;
Kzz=Kzz1;
Kfz=Kfz1;
Kzf=Kzf1;
Kft=Kft1;
Ktf=Ktf1;
Kzt=Kzt1;
Ktz=Ktz1;
Fui = Fuu1+FufM1+Fuz1+Fut1;
GfiM = FfuM1+FffM1+Ffz1+Fft1;
Mzi=Fzu1+Fzz1+Fzf1+Fzt1; 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Calculate one layer----------------------------------------------------End
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Construct ElemMatr, return value
ElemMatr = struct('Muu',Muu,'Kuu',Kuu','KfuM',KfuM,'KufM',KufM, ...
 'Kzz',Kzz,'Kzu',Kzu,'Kuz',Kuz,...
 'Kzf',Kzf,'Kfz',Kfz,'KffM',KffM,'Fus',Fus,'Fuc',Fuc,'Fui',Fui,...
 'Ktu',Ktu,'Kut',Kut,'Kzt',Kzt,'Ktz',Ktz,'Kft',Kft,'Ktf',Ktf,...
'GfiM',GfiM,'GfM',GfM,'Mzi',Mzi,'Mz',Mz);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% disply processes

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% fprintf('::SF_ElemComptNL851T5MFC_V4-%s-%s------EleIndex=%d\n', ...
%         ShellStr,TheoryStr,EleIndex);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end


