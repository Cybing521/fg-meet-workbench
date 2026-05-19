%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Subfuntion SF_InputFileCheckMFC()
%Calculate Get Element, Node, ElemType, etc. matrices
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function [ERROR] = SF_InputFileCheckMEEP(FinitElemInfo,Material)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% ERROR: 0, input correct; 1, input has mistaks;
ERROR = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Get input information
ElemType = FinitElemInfo.ElemType;
Element = FinitElemInfo.Element;
Node = FinitElemInfo.Node;
ShellTheory = FinitElemInfo.ShellTheory;

NumElem = length(Element(:,1));
NumNode = length(Node(:,1));

NodePerElem = ElemType(1);
DOFPerNodeM = ElemType(2);
NumLay = ElemType(3);
DOFPerMEELay = ElemType(4);

%% check ElementInfo if it is [8,5,1]
if NodePerElem ~= 8 || DOFPerNodeM ~=5 ||DOFPerMEELay ~= 1
    fprintf('!!ERROR01::ElementInfo = [%d,%d,%d], does not equal to [8 5 1]!\n', ...
            NodePerElem,DOFPerNodeM,DOFPerMEELay);
    ERROR = 1; 
end

% if length(ElementInfo) ~= 3
%     fprintf('!!ERROR02::Too many inputs for ElementInfo!\n')
%     ERROR = 2; 
%     return;
% end

%% Check Element, if there are repeated node index in one element
for ElemIndex = 1:NumElem           % for each element
    for j = 1:NodePerElem           % for eack node in current element
        for k = 1:NodePerElem       % compare with next n nodes
            if j+k <= NodePerElem   % But not ecceed the column
                if Element(ElemIndex,j) == Element(ElemIndex,j+k)
                    fprintf('!!ERROR03::Node repeat in Element %d\n',ElemIndex);
                    ERROR = 3;
                end
            end
        end
    end
end

%% Check repeated nodes
for NodeIndex = 1:NumNode
    for j = 1:NumNode
        if NodeIndex+j <= NumNode
            if Node(NodeIndex,1) == Node(NodeIndex+j,1)
                fprintf('!!ERROR04::Node %d repeat in Node matrix!\n',Node(NodeIndex,1));
                ERROR = 4;
            end
        end
    end
end

%% Check ShellTheory
if length(ShellTheory(:,1)) ~=3
    fprintf('!!ERROR05::ShellTheory too many/few aguments!\n');
    ERROR = 5;
end

if isempty(find(ShellTheory(1,1) == [1,2,3], 1))
    fprintf('!!ERROR06::Shell type must be PLATE,CYLINDER and SPHERE!\n');
    ERROR = 6;
end

if isempty(find(ShellTheory(2,1) == [1,2,3,4], 1))
    fprintf('!!ERROR07::Theory type must be LRT5,MRT5 and RVK!\n');
    ERROR = 7;
end

%%% new added
if isempty(find(ShellTheory(3,1) == 0, 1))
    fprintf('!!ERROR07::Material should be MFC!\n');
    ERROR = 10;
end

%% Check material 
% %%% whether there don't have smart layer; IsSmtLay:column 15
if sum(Material(:,27))<=0
    fprintf('!!ERROR08::There is no smart layer!\n');
    ERROR = 8;
end

%%% Thickness greater than 0,zC1,13,zC2,14
for LayIndex = 1:NumLay
    zC_Lay = Material(LayIndex,25:26);
    if zC_Lay(2) - zC_Lay(1) <=0
        fprintf('!!ERROR09::The thickness of %dth layer is not greater than 0!\n', ...
                LayIndex);
        ERROR = 9;
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end