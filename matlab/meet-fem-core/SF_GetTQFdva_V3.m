%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Subfuntion SF_GetTQFdva_V3()  %% seperate voltage of actuator and sensor
%Calculate Muu,Kuu,Kuf,Kff for one element
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [TQFdva] = SF_GetTQFdva_V3(FinitElemInfo,MateProp,Qd,Qv,Qa,PhiaM,PhisM,Mga,Mgs)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Qd,Qv,Qa, after add boundary condition
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
NumLay = ElemType(3);                             % Number of MEE layer
DOFPerMEELay = ElemType(4);             % MEE dof per layer 
NumMEELay = ElemType(5);  
DOFPerElemMEE = NumMEELay*DOFPerMEELay;  % Number of MEE dof per element
DOFTotalM = NumNode*DOFPerNodeM;
DOFTotalMEE = NumElem*DOFPerElemMEE;
%% If Qd,Qv,Qa,Phis,Phia is empty, set them to zero as default
if isempty(Qd)
    Qd = zeros(DOFTotalM);
end

if isempty(Qv)
    Qv = zeros(DOFTotalM);
end

if isempty(Qa)
    Qa = zeros(DOFTotalM);
end

if isempty(PhisM)
    PhisM = zeros(DOFTotalMEE);
end

if isempty(PhiaM)
    PhiaM = zeros(DOFTotalMEE);
end

if isempty(Mga)
    Mga = zeros(DOFTotalMEE);
end
if isempty(Mgs)
    Mgs = zeros(DOFTotalMEE);
end
%% Initial TQd,TQv,TQa, before adding boundary condition
TQd = zeros(DOFTotalM,1);
TQv = zeros(DOFTotalM,1);
TQa = zeros(DOFTotalM,1);
TPhisM = zeros(DOFTotalMEE,1);
TPhiaM = zeros(DOFTotalMEE,1);
TMgs = zeros(DOFTotalMEE,1);
TMga = zeros(DOFTotalMEE,1);
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
%% Construct TPhiM
LayStart = NodePerElem+1;       % LayStart = 9 
PhiMIndex = 1;                    % PhiIndex: for Phis(a), after boundary condition
for ElemIndex = 1:NumElem
    SmtLayIndex = 1;
    for LayIndex = 1:NumLay  
        if MateProp{LayIndex,1}.IsSmtLay == 2
            %%% TPhiIndex: for TPhi, before boundary condition
            TPhiMIndex = (ElemIndex-1)*DOFPerMEELay + SmtLayIndex;
            if Element(ElemIndex,LayStart+LayIndex-1) == 1
                TPhisM(TPhiMIndex) = PhisM(PhiMIndex);
                TPhiaM(TPhiMIndex) = PhiaM(PhiMIndex);
                PhiMIndex = PhiMIndex+1;
            else
                TPhisM(TPhiMIndex) = 0;
                TPhiaM(TPhiMIndex) = 0;
            end
            SmtLayIndex = SmtLayIndex+1;
        end  
    end
end
%% Construct Mg
LayStart = NodePerElem+1;       % LayStart = 9 
MgIndex = 1;                    % PhiIndex: for Phis(a), after boundary condition
for ElemIndex = 1:NumElem
    SmtLayIndex = 1;
    for LayIndex = 1:NumLay  
        if MateProp{LayIndex,1}.IsSmtLay == 2
            %%% TPhiIndex: for TPhi, before boundary condition
            TMgIndex = (ElemIndex-1)*DOFPerMEELay + SmtLayIndex;
            if Element(ElemIndex,LayStart+LayIndex-1) == 1
                TMgs(TMgIndex) = Mgs(MgIndex);
                TMga(TMgIndex) = Mga(MgIndex);
                MgIndex = MgIndex+1;
            else
                TMgs(TMgIndex) = 0;
                TMga(TMgIndex) = 0;
            end
            SmtLayIndex = SmtLayIndex+1;
        end  
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Contruct TQdva, displacement, velocity and acceleration
TQFdva = struct('TQd',TQd,'TQv',TQv,'TQa',TQa,'TPhiaM',TPhiaM,'TPhisM',TPhisM,'TMga',TMga,'TMgs',TMgs);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end











