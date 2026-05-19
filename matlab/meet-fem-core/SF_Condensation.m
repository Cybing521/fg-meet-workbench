%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Subfuntion SF_Condensation_LIN
%Adding boundary conditions, condensing the dof of whole structure
%Every degree of freedom can be condensed!!!!!!!!!!!!!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [GlobMatr] = SF_Condensation(GlobMatr,FinitElemInfo,MateProp)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Define global variables
% global MuuT CuuT KuuT KufT KffT FusT GfT ElemType Node ;

%% Globla matrices
MuuT = GlobMatr.MuuT;
CuuT = GlobMatr.CuuT;
%%%%%%%%%%双向耦合可能用到的矩阵
% MutT = GlobMatr.MutT;
% MtuT = GlobMatr.MtuT;
% MttT = GlobMatr.MttT;
% CutT = GlobMatr.CutT;
% CtuT = GlobMatr.CtuT;
% CttT = GlobMatr.CttT;
%%%%%%%%%%%
KuuT = GlobMatr.KuuT;
KufMT = GlobMatr.KufMT;
KfuMT = GlobMatr.KfuMT;
KffMT = GlobMatr.KffMT;

KutT = GlobMatr.KutT;%hzt+
KftT = GlobMatr.KftT;
KztT = GlobMatr.KztT;
KtuT = GlobMatr.KtuT;
KtfT = GlobMatr.KtfT;
KtzT = GlobMatr.KtzT;
KttT = GlobMatr.KttT;

KuzT= GlobMatr.KuzT;
KzuT= GlobMatr.KzuT;
KfzT= GlobMatr.KfzT;
KzfT= GlobMatr.KzfT;
KzzT= GlobMatr.KzzT;

FuiT = GlobMatr.FuiT;
FusT = GlobMatr.FusT;
FucT = GlobMatr.FucT;
GfiMT = GlobMatr.GfiMT;
GfMT = GlobMatr.GfMT;
MziT = GlobMatr.MziT;
MzT = GlobMatr.MzT;
FtT = GlobMatr.FtT;
%% Finite Element informatin
ElemType = FinitElemInfo.ElemType;
Element = FinitElemInfo.Element;
Node = FinitElemInfo.Node;

NodePerElem = ElemType(1);
DOFPerNodeM = ElemType(2);
DOFPerMEELay = ElemType(4);
NumMEELay = ElemType(5);

NumLay = ElemType(3);
% NumLayT = NumLay;
% DOFPerTLay = 1;
% DOFPerElemT = NumLayT*DOFPerTLay;
DOFPerElemMEE = NumMEELay*DOFPerMEELay;
NumNode = length(Node(:,1));
NumElem = length(Element(:,1));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Condensing-----------------------------------------------------------Start
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% First postion of mechanical dof (first one) and electrical dof (second)  MEE dof (three)  
PosME = [5 11  12];   %?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for NodeIndex = NumNode:-1:1
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% For mechanical dof consendation
    %%% PosME(1): Start position of electrical dof
    for DOFMIndex = DOFPerNodeM:-1:1
        if Node(NodeIndex,PosME(1)+DOFMIndex-1) == 1
            DeletIndex=(NodeIndex-1)*DOFPerNodeM+DOFMIndex;
            MuuT(DeletIndex,:)=[];
            MuuT(:,DeletIndex)=[];
            CuuT(DeletIndex,:)=[];
            CuuT(:,DeletIndex)=[];
            KuuT(DeletIndex,:)=[];
            KuuT(:,DeletIndex)=[];
            
%             MutT(DeletIndex,:)=[];
%             MtuT(:,DeletIndex)=[];
%             CutT(DeletIndex,:)=[];
%             CtuT(:,DeletIndex)=[];
            
            KufMT(DeletIndex,:)=[];
            KfuMT(:,DeletIndex)=[];
            KuzT(DeletIndex,:)=[];
            KzuT(:,DeletIndex)=[];
            KutT(DeletIndex,:)=[];
            KtuT(:,DeletIndex)=[];
            
            FuiT(DeletIndex,:)=[];
            FusT(DeletIndex,:)=[];
            FucT(DeletIndex,:)=[]; 
        end
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %% For electrical dof consendation, (not used in current model)
    %%% If the electrical DOFs are distributed on nodes
    %%% PosME(2): Start position of electrical dof
%     for DOFIndex = 6:-1:1
%         if Node(NodeIndex,PosME(2)+DOFMIndex-1) == 1
%             DeletIndex=(NodeIndex-1)*DOFPerElemE+DOFIndex;
%             KufPT(:,DeletIndex)=[];
%              KufMT(:,DeletIndex)=[];
%             KfuPT(DeletIndex,:)=[];
%               KfuMT(DeletIndex,:)=[]; 
%             KffPT(DeletIndex,:)=[];
%             KffMT(DeletIndex,:)=[];
%             KffPT(:,DeletIndex)=[];
%             KffMT(:,DeletIndex)=[];
%             GfiT(DeletIndex,:)=[]; 
%             GfT(DeletIndex,:)=[]; 
%         end
%     end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% LayStart: In Element Matrix, the start position of layer
LayStart = NodePerElem+1;   % LayStart = 9          
for ElemIndex = NumElem:-1:1
    MEELayIndex = NumMEELay;     % MEELayIndex: 
    for LayIndex = NumLay:-1:1
         if   MateProp{LayIndex,1}.IsSmtLay ==2
            if Element(ElemIndex,LayStart+LayIndex-1) == 0
                DeletIndex = (ElemIndex-1)*DOFPerElemMEE+MEELayIndex;
                KufMT(:,DeletIndex)=[];
                KfuMT(DeletIndex,:)=[];
                KffMT(DeletIndex,:)=[];
                KffMT(:,DeletIndex)=[];
                
%                 MttT(DeletIndex,:)=[];
%                 MttT(:,DeletIndex)=[];
%                 CttT(DeletIndex,:)=[];
%                 CttT(:,DeletIndex)=[];
                
                KfzT(:,DeletIndex)=[];
                KzfT(DeletIndex,:)=[];
                KzzT(DeletIndex,:)=[];
                KzzT(:,DeletIndex)=[];
                
                KftT(DeletIndex,:)=[];
                KtfT(:,DeletIndex)=[];
                KztT(DeletIndex,:)=[];
                KtzT(:,DeletIndex)=[];
                KttT(DeletIndex,:)=[];
                KttT(:,DeletIndex)=[];
                 
                GfiMT(DeletIndex,:)=[]; 
                GfMT(DeletIndex,:)=[];
                MziT(DeletIndex,:)=[]; 
                MzT(DeletIndex,:)=[];
                FtT(DeletIndex,:)=[];
                
                MEELayIndex = MEELayIndex-1;
            end    
        end
    end
end

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Construc Global matrices, as a return value
GlobMatr = struct('MuuT',MuuT,'KuuT',KuuT,'CuuT',CuuT,...
    'KufMT',KufMT, 'KfuMT',KfuMT,'KffMT',KffMT,'FuiT',FuiT,'FusT',FusT, ...
    'FucT',FucT,'KuzT',KuzT,'KzuT',KzuT,'KfzT',KfzT,'KzfT',KzfT,'KzzT',KzzT, ...
   'KutT',KutT,'KftT',KftT,'KtuT',KtuT,'KtfT',KtfT,'KtzT',KtzT,'KztT',KztT, ...
  'KttT',KttT,'GfiMT',GfiMT,'GfMT',GfMT,'MziT',MziT,'MzT',MzT,'FtT',FtT);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Condensing-------------------------------------------------------------End
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('::SF_Condensation----------------------Successfully\n');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end