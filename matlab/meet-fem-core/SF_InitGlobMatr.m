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
NumElem = length(Element(:,1));          % NumElem: Number of elements
NumNode = length(Node(:,1));             % NumNode: Number of nodes
                 % Number of layers
%%% Calculate dofs and matrices size
NodePerElem = ElemType(1);
DOFPerNodeM = ElemType(2);
NumLay = ElemType(3);
DOFPerMEELay = ElemType(4);
NumMEELay = ElemType(5);                  % Number of MEE layer
% DOFPerTLay = 1;
% NumLayT = NumLay;

DOFPerElemM=NodePerElem*DOFPerNodeM;      % Mechanical DOF per element
DOFPerElemMEE = NumMEELay*DOFPerMEELay;   % Electrical DOF per element
DOFTotalM=NumNode*DOFPerNodeM;            % Total Mechanical DOF
DOFTotalMEE=NumElem*DOFPerElemMEE;        % Total Electrical DOF
%% Initiate global matrices for mass, stiffness......
MuuT = sparse(DOFTotalM,DOFTotalM);         % Global mass matrix
KuuT = sparse(DOFTotalM,DOFTotalM);         % Global stiffness matrix
CuuT = sparse(DOFTotalM,DOFTotalM);         % Global damping matrix
%%%%%%%双向耦合动力学可能用到的矩阵
% MutT = zeros(DOFTotalM,DOFTotalMEE);
% MtuT = zeros(DOFTotalMEE,DOFTotalM);
% MttT = zeros(DOFTotalMEE,DOFTotalMEE);
%
% CutT = zeros(DOFTotalM,DOFTotalMEE);
% CtuT = zeros(DOFTotalMEE,DOFTotalM);
% CttT = zeros(DOFTotalMEE,DOFTotalMEE);
%%%%%%%%%%%%%%%%%%%%%
KufMT = sparse(DOFTotalM,DOFTotalMEE);      % Global coupling matrix u弹 f电 z磁 t热
KfuMT = sparse(DOFTotalMEE,DOFTotalM);
KffMT = sparse(DOFTotalMEE,DOFTotalMEE);

KuzT=sparse(DOFTotalM,DOFTotalMEE);
KzuT=sparse(DOFTotalMEE,DOFTotalM);
KfzT=sparse(DOFTotalMEE,DOFTotalMEE);
KzfT=sparse(DOFTotalMEE,DOFTotalMEE);
KzzT=sparse(DOFTotalMEE,DOFTotalMEE);

KutT = sparse(DOFTotalM,DOFTotalMEE);
KtuT = sparse(DOFTotalMEE,DOFTotalM);
KftT = sparse(DOFTotalMEE,DOFTotalMEE);
KtfT = sparse(DOFTotalMEE,DOFTotalMEE);
KztT = sparse(DOFTotalMEE,DOFTotalMEE);
KtzT = sparse(DOFTotalMEE,DOFTotalMEE);
KttT=sparse(DOFTotalMEE,DOFTotalMEE);

FuiT = zeros(DOFTotalM,1);           % Global in-balance force, mechanical
FusT = zeros(DOFTotalM,1);           % Global external surface force vector
FucT = zeros(DOFTotalM,1);           % Global external  concentrated force v
GfiMT = zeros(DOFTotalMEE,1);        % Global in-balance force, electrical
GfMT = zeros(DOFTotalMEE,1);         % Global equvilent force vector电力
MziT = zeros(DOFTotalMEE,1);         % Global in-balance force, magnetical
MzT = zeros(DOFTotalMEE,1);          %磁力
FtT = zeros(DOFTotalMEE,1);

%%% GlobMatrix include all the global matrices of smart structure
GlobMatr = struct('MuuT',MuuT,'KuuT',KuuT,'CuuT',CuuT, ...
    'KufMT',KufMT,'KfuMT',KfuMT,'KffMT',KffMT,'FuiT',FuiT,'FusT',FusT, ...
    'FucT',FucT,'KuzT',KuzT,'KzuT',KzuT,'KfzT',KfzT,'KzfT',KzfT,'KzzT',KzzT,...
'KutT',KutT,'KftT',KftT, 'KtuT',KtuT,'KtfT',KtfT,'KtzT',KtzT,'KztT',KztT,'KttT',KttT,...
'GfiMT',GfiMT,'GfMT',GfMT,'MziT',MziT,'MzT',MzT,'FtT',FtT);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end
