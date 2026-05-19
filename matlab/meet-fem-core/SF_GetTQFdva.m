%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Subfuntion SF_GetTQFdva()
%Calculate Muu,Kuu,Kuf,Kff for one element
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [TQFdva] = SF_GetTQFdva(FinitElemInfo,MateProp,Qd,Qv,Qa,Phi)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Qd,Qv,Qa, after add boundary condition
%%% TQd,TQv,TQa,TPhi: include all nodes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Get ElemType,Element,Node
ElemType = FinitElemInfo.ElemType;
Element = FinitElemInfo.Element;
Node = FinitElemInfo.Node;

NumNode = length(Node(:,1));
NumElem = length(Element(:,1));
%% Get DOFs
NodePerElem = ElemType(1);
DOFPerNodeM = ElemType(2);
NumLay = ElemType(3);
DOFPerSmtLayE = ElemType(4);
NumSmtLay = ElemType(5);



DOFPerElemM = NodePerElem*DOFPerNodeM;
DOFPerElemE = NumSmtLay*DOFPerSmtLayE;
DOFTotalM = NumNode*DOFPerNodeM;
DOFTotalE = NumElem*DOFPerElemE;

%% If Qd,Qv,Qa,Phi is empty, set them to zero as default
if isempty(Qd)
    Qd = zeros(DOFTotalM);
end

if isempty(Qv)
    Qv = zeros(DOFTotalM);
end

if isempty(Qa)
    Qa = zeros(DOFTotalM);
end

if isempty(Phi)
    Phi = zeros(DOFTotalE);
end

%% Initial TQd,TQv,TQa, before adding boundary condition
TQd = zeros(DOFTotalM,1);
TQv = zeros(DOFTotalM,1);
TQa = zeros(DOFTotalM,1);
TPhi = zeros(DOFTotalE,1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Construct TQd,TQv,TQa
DOFMStart = 5;              % The start position of mechanical dof 
QIndex = 1;                 % QIndex: for Qd,Qv,Qa, after boundary condition
for NodeIndex = 1:NumNode
    for DOFIndex = 1:DOFPerNodeM
        %%% TQIndex: for TQd,TQv.TQa, before boundary condition
        TQIndex = (NodeIndex-1)*DOFPerNodeM + DOFIndex;
        if Node(NodeIndex,DOFMStart+DOFIndex-1) == 0
            TQd(TQIndex) = Qd(QIndex);
            TQv(TQIndex) = Qv(QIndex);
            TQa(TQIndex) = Qa(QIndex);
            QIndex = QIndex+1;
        else
            TQd(TQIndex) = 0;
            TQv(TQIndex) = 0;
            TQa(TQIndex) = 0;
        end  
    end
end

%% Construct TPhi
LayStart = NodePerElem+1;       % LayStart = 9 
PhiIndex = 1;                    % PhiIndex: for Phi, after boundary condition
for ElemIndex = 1:NumElem
    SmtLayIndex = 1;
    for LayIndex = 1:NumLay  
        if MateProp{LayIndex,1}.IsSmtLay == 1
            %%% TPhiIndex: for TPhi, before boundary condition
            TPhiIndex = (ElemIndex-1)*DOFPerSmtLayE + SmtLayIndex;
            if Element(ElemIndex,LayStart+LayIndex-1) == 1
                TPhi(TPhiIndex) = Phi(PhiIndex);
                PhiIndex = PhiIndex+1;
            else
                TPhi(TPhiIndex) = 0;
            end
            SmtLayIndex = SmtLayIndex+1;
        end  
    end
end

%% Contruct TQdva, displacement, velocity and acceleration
TQFdva = struct('TQd',TQd,'TQv',TQv,'TQa',TQa,'TPhi',TPhi);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end











