%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Subfuntion SF_GetFusVect
%Calculate Fus, unit surface force
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ElemMatr] = SF_GetFusVect(EleIndex,FinitElemInfo,fs)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%fs=[0;0;1],external uniform load,[u,v,w]

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Coordinates specification
%%% xG,yG,zG: Global coordinates
%%% xC,yC,zC: Curvalinear coordinates
%%% xL,yL,zL: Local coordinates

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(fs)
    fs = [0;0;0]; %external uniform load,[u,v,w]
end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Finite Element information
ElemType = FinitElemInfo.ElemType;
Element = FinitElemInfo.Element;
Node = FinitElemInfo.Node;
ShellTheory = FinitElemInfo.ShellTheory;

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Calculate ElementNum, Nodenum
% NumElem: Total number of element
% NumNode: Total number of node

%% Calculate dofs and matrices size
%%% ElemType = [Node/Elem DOF/Node NumSmtLay DOF/SmtLay NumLay]
NodePerElem = ElemType(1);
DOFPerNodeM = ElemType(2);
DOFPerMEELay = ElemType(4);
 NumMEELay = ElemType(5);
DOFPerElemM = NodePerElem*DOFPerNodeM;
DOFPerElemMEE = NumMEELay*DOFPerMEELay;
% NumLayT = NumLay;
% DOFPerTLay = 1;
% DOFPerElemT = NumLayT*DOFPerTLay;
% DOFTotalM = NumNode*DOFPerNodeM;
% DOFTotalE = NumElem*DOFPerElemE;

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Definition of Gauss Point and its weight
GP_3=[-0.774596669241483 0.555555555555556;
       0.774596669241483 0.555555555555556;
       0                 0.888888888888889]; 
   
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
% Ft = zeros(2,1);
Ft = zeros(DOFPerElemMEE,1);
%% relation between local coordinate and globle coordinate xG,yG
XNode = zeros(NodePerElem,3);
for j = 1:NodePerElem
    [Row,Column]=find(Node(:,1) == Element(EleIndex,j));
    XNode(j,1:3)=Node(Row,2:4);    %XNode,globle coordinate of node 
end

%relation between local coordinate and globle coordinate xG,yG
EleLen = abs(XNode(2,1)-XNode(1,1));
EleWid = abs(XNode(4,2)-XNode(1,2));

%%%%%%%%%%%%%%%%
if ShellTheory(1,1) == 2 || ShellTheory(1,1) == 3
    R = XNode(1,3);
end
%%%%%%
a = EleLen/2;
b = EleWid/2;
h = 0;
xC_m = (XNode(1,1)+XNode(2,1))/2;       % xC_m: middle position of xC
% yC_m = (XNode(1,2)+XNode(4,2))/2;       % xC_m: middle position of yC
% zC_m = (Lay_zC(1)+Lay_zC(2))/2;         % zC_m: middle line of layer

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%Intergrating for external surface uniform load;
for i=1:3
    for j=1:3
        xL = GP_3(i,1);
        yL =GP_3(j,1);
        %%% The surface force is applied on the mid-surface
        zL = 0;
        zC_m = 0;
        zC = zC_m + h*zL;
        
        %% Coordinates adaption
        xC = xC_m + a*xL;
        %%% ShellTheory(1,1): 1,PLATE; 2, CYLINDER; 3, SPHERE
        switch ShellTheory(1,1)
            case 1      % PLATE
                Sqrt_a = 1;
                k = 1;          %% coeffient for v2
            case 2      % CYLINDER
                Sqrt_a = R;
                k = R;
            case 3      % SPHERE
                Sqrt_a = R*sin(xC/R);
                k = R*sin(xC/R);
        end
        
        %% Shape function
        N(1) = 1/4*(1-xL)*(1-yL)*(-xL-yL-1);
        N(2) = 1/4*(1+xL)*(1-yL)*(xL-yL-1);
        N(3) = 1/4*(1+xL)*(1+yL)*(xL+yL-1);
        N(4) = 1/4*(1-xL)*(1+yL)*(-xL+yL-1);
        N(5) = 1/2*(1-xL^2)*(1-yL);
        N(6) = 1/2*(1-yL^2)*(1+xL);
        N(7) = 1/2*(1-xL^2)*(1+yL);
        N(8) = 1/2*(1-yL^2)*(1-xL);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %% Zu matrix
        Zu = [1 0 0 zC 0;
              0 1 0 0  zC;
              0 0 1 0  0  ];
            
        %% Kq matrix
        Kv = diag([1,k,1,1,k]);
        
        %% Nu matrix
        IM = eye(DOFPerNodeM,DOFPerNodeM);              %IM(5,5)
        Nu = [N(1)*IM, N(2)*IM, N(3)*IM, N(4)*IM, ...
              N(5)*IM, N(6)*IM, N(7)*IM, N(8)*IM ];
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        Fus=Fus+GP_3(i,2)*GP_3(j,2)*Nu'*Zu'*fs*Sqrt_a*a*b;
%         Fus=Fus+GP_3(i,2)*GP_3(j,2)*Nu'*Zu'*fs*1*a*b;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    end
end

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
ElemMatr = struct('Muu',Muu,'Kuu',Kuu','KufM',KufM,'KfuM',KfuM,'KffM',KffM,'Kfz',Kfz,'Kzf',Kzf,'Kzz',Kzz,'Kuz',Kuz,'Kzu',Kzu, ...
                   'Fui',Fui,'Fus',Fus,'Fuc',Fuc,'Kut',Kut,'Kft',Kft,'Ktu',Ktu,'Ktf',Ktf,...,
                   'Ktz',Ktz,'Kzt',Kzt,'Ktt',Ktt,'GfiM',GfiM,'GfM',GfM,'Mzi',Mzi,'Mz',Mz,'Ft',Ft); 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('::SF_GetFusVect-------------------EleIndex = %d\n',EleIndex);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end


