%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Subfuntion SF_InitGlobMatr()
%Initial global matrices
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function [GlobMatr] = SF_InitGlobMatr(FinitElemInfo)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Get Finite Element Information
%%% ElemType = [Node/Elem DOF/Node NumSmtLay DOF/SmtLay NumLay]
ElemType = FinitElemInfo.ElemType;
Element = FinitElemInfo.Element;
Node = FinitElemInfo.Node;
%% Calculate ElementNum, Nodenum
NumElem = length(Element(:,1));         % NumElem: Number of elements
NumNode = length(Node(:,1));            % NumNode: Number of nodes
                 % Number of layers
%%% Calculate dofs and matrices size
NodePerElem = ElemType(1);
DOFPerNodeM = ElemType(2);

 DOFPerMEELay = ElemType(4);  
 NumMEELay = ElemType(5);                 % Number of MEE layer

DOFPerElemM=NodePerElem*DOFPerNodeM;    % Mechanical DOF per element
    % Electrical DOF per element
DOFPerElemMEE = NumMEELay*DOFPerMEELay;
DOFTotalM=NumNode*DOFPerNodeM;          % Total Mechanical DOF
        % Total Electrical DOF
DOFTotalMEE=NumElem*DOFPerElemMEE; 
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Initiate global matrices for mass, stiffness......
MuuT = zeros(DOFTotalM,DOFTotalM);      % Global mass matrix
KuuT = zeros(DOFTotalM,DOFTotalM);      % Global stiffness matrix
CuuT = zeros(DOFTotalM,DOFTotalM);      % Global damping matrix


KufMT = zeros(DOFTotalM,DOFTotalMEE);      % Global coupling matrix
KfuMT = zeros(DOFTotalMEE,DOFTotalM); 

KffMT = zeros(DOFTotalMEE,DOFTotalMEE);

KuzT=zeros(DOFTotalM,DOFTotalMEE); 
KzuT=zeros(DOFTotalMEE,DOFTotalM); 
KfzT=zeros(DOFTotalMEE,DOFTotalMEE);
KzfT=zeros(DOFTotalMEE,DOFTotalMEE);
KzzT=zeros(DOFTotalMEE,DOFTotalMEE);
KutT = zeros(DOFTotalM,2);%hzt+
KtuT = zeros(2,DOFTotalM);
KftT = zeros(DOFTotalMEE,2);
KtfT = zeros(2,DOFTotalMEE);
KztT = zeros(DOFTotalMEE,2);
KtzT = zeros(2,DOFTotalMEE);

FuiT = zeros(DOFTotalM,1);        % Global in-balance force, mechanical
FusT = zeros(DOFTotalM,1);        % Global external surface force vector
FucT = zeros(DOFTotalM,1);        % Global external  concentrated force v
GfiMT = zeros(DOFTotalMEE,1);        % Global in-balance force, electrical
GfMT = zeros(DOFTotalMEE,1);         % Global equvilent force vector
MziT = zeros(DOFTotalMEE,1);
MzT = zeros(DOFTotalMEE,1);
%%% GlobMatrix include all the global matrices of smart structure
GlobMatr = struct('MuuT',MuuT,'KuuT',KuuT,'CuuT',CuuT, ...
    'KufMT',KufMT,'KfuMT',KfuMT,'KffMT',KffMT,'FuiT',FuiT,'FusT',FusT, ...
    'FucT',FucT,'KuzT',KuzT,'KzuT',KzuT,'KfzT',KfzT,'KzfT',KzfT,'KzzT',KzzT,...
'KutT',KutT,'KftT',KftT, 'KtuT',KtuT,'KtfT',KtfT,'KtzT',KtzT,'KztT',KztT,...
'GfiMT',GfiMT,'GfMT',GfMT,'MziT',MziT,'MzT',MzT);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end













