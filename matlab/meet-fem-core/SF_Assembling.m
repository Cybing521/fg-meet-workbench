%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Subfuntion SF_Assemling
%Assemling the matrices in local coordinate system into global coordinate
%system
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [GlobMatr]=SF_Assembling(EleIndex,ElemMatr,GlobMatr, ...
                                      FinitElemInfo)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%ElemType=[NodePerElem DOFPerNodeM NumSmtLay DOFPerSmtLayE]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Define global variables
% global MuuT KuuT KufT KffT FusT GfT ElemType Element;
%% Globla matrices
MuuT = GlobMatr.MuuT;
CuuT = GlobMatr.CuuT;
%%%%%%%%%%双向耦合可能用到的矩阵
% MutT = GlobMatr.MuuT;
% MtuT = GlobMatr.MuuT;
% MttT = GlobMatr.MuuT;
% CutT = GlobMatr.CuuT;
% CtuT = GlobMatr.CuuT;
% CttT = GlobMatr.CuuT;
%%%%%%%%%%%
KuuT = GlobMatr.KuuT;
KufMT = GlobMatr.KufMT;
KfuMT = GlobMatr.KfuMT;
KffMT = GlobMatr.KffMT;
KuzT= GlobMatr.KuzT;
KzuT= GlobMatr.KzuT;
KfzT= GlobMatr.KfzT;
KzfT= GlobMatr.KzfT;
KzzT= GlobMatr.KzzT;

KutT = GlobMatr.KutT;
KftT = GlobMatr.KftT;
KztT = GlobMatr.KztT;
KtuT = GlobMatr.KtuT;
KtfT = GlobMatr.KtfT;
KtzT = GlobMatr.KtzT;
KttT = GlobMatr.KttT;

FuiT = GlobMatr.FuiT;
FusT = GlobMatr.FusT;
FucT = GlobMatr.FucT;
GfiMT =  GlobMatr.GfiMT;
GfMT = GlobMatr.GfMT;
MziT = GlobMatr.MziT;
MzT = GlobMatr.MzT;
FtT = GlobMatr.FtT;
%% Element matrices
Muu = ElemMatr.Muu;
Kuu = ElemMatr.Kuu;
KufM = ElemMatr.KufM;
KfuM = ElemMatr.KfuM;
KffM = ElemMatr.KffM;

Kuz= ElemMatr.Kuz;
Kzu= ElemMatr.Kzu;
Kfz= ElemMatr.Kfz;
Kzf= ElemMatr.Kzf;
Kzz= ElemMatr.Kzz;

Kut = ElemMatr.Kut;
Kft = ElemMatr.Kft;
Kzt = ElemMatr.Kzt;
Ktu = ElemMatr.Ktu;
Ktf = ElemMatr.Ktf;
Ktz = ElemMatr.Ktz;
Ktt = ElemMatr.Ktt;

Fui = ElemMatr.Fui;
Fus = ElemMatr.Fus;
GfiM = ElemMatr.GfiM;
GfM = ElemMatr.GfM;
Mzi=ElemMatr.Mzi;
Mz=ElemMatr.Mz;
Ft = ElemMatr.Ft;
%% Finite Element informatin
ElemType = FinitElemInfo.ElemType;
Element = FinitElemInfo.Element;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Assemling------------------------------------------------------------Start
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
NodePerElem = ElemType(1);
DOFPerNodeM = ElemType(2);
DOFPerMEELay = ElemType(4);
NumMEELay = ElemType(5);
% NumLayT = NumLay;
% DOFPerTLay = 1;
DOFPerElemMEE = NumMEELay*DOFPerMEELay;
% DOFPerElemT = NumLayT*DOFPerTLay;   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%Assembling Muu,Kuu into MuuT and KuuT
for m = 1:NodePerElem
    for n = 1:NodePerElem
        IndexR = (Element(EleIndex,m)-1)*DOFPerNodeM+1: ...,
                  Element(EleIndex,m)*DOFPerNodeM;
        IndexC = (Element(EleIndex,n)-1)*DOFPerNodeM+1: ...,
                  Element(EleIndex,n)*DOFPerNodeM;
              
        MuuT(IndexR,IndexC) = MuuT(IndexR,IndexC)+ ...,
                              Muu((m-1)*DOFPerNodeM+1:m*DOFPerNodeM, ...,
                                  (n-1)*DOFPerNodeM+1:n*DOFPerNodeM);
        KuuT(IndexR,IndexC) = KuuT(IndexR,IndexC)+ ...,
                              Kuu((m-1)*DOFPerNodeM+1:m*DOFPerNodeM, ...,
                                  (n-1)*DOFPerNodeM+1:n*DOFPerNodeM);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%Assembling Kuf into KufT, Kfu into KfuT, Kuz into KuzT, Kzu into KzuT
for m=1:NodePerElem
    IndexR=(Element(EleIndex,m)-1)*DOFPerNodeM+1: ...,
            Element(EleIndex,m)*DOFPerNodeM;
    
    IndexS=(EleIndex-1)*DOFPerElemMEE+1: ...,
            EleIndex*DOFPerElemMEE;      
        
%     IndexT=(EleIndex-1)*DOFPerElemT+1: ...,
%         EleIndex*DOFPerElemT;     
    
    KufMT(IndexR,IndexS)=KufMT(IndexR,IndexS)+ ...,
            KufM((m-1)*DOFPerNodeM+1:m*DOFPerNodeM,1:DOFPerElemMEE);
    KfuMT(IndexS,IndexR)=KfuMT(IndexS,IndexR)+ ...,
            KfuM(1:DOFPerElemMEE,(m-1)*DOFPerNodeM+1:m*DOFPerNodeM);            
    KuzT(IndexR,IndexS)=KuzT(IndexR,IndexS)+ ...,
            Kuz((m-1)*DOFPerNodeM+1:m*DOFPerNodeM,1:DOFPerElemMEE);
    KzuT(IndexS,IndexR)=KzuT(IndexS,IndexR)+ ...,
            Kzu(1:DOFPerElemMEE,(m-1)*DOFPerNodeM+1:m*DOFPerNodeM);
    KutT(IndexR,IndexS)=KutT(IndexR,IndexS)+ ...,
            Kut((m-1)*DOFPerNodeM+1:m*DOFPerNodeM,1:DOFPerElemMEE);
    KtuT(IndexS,IndexR)=KtuT(IndexS,IndexR)+ ...,
            Ktu(1:DOFPerElemMEE,(m-1)*DOFPerNodeM+1:m*DOFPerNodeM);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Assembling Kut into KutT, Ktu into KtuT
% for m=1:NodePerElem
%     IndexR=(Element(EleIndex,m)-1)*DOFPerNodeM+1: ...,
%             Element(EleIndex,m)*DOFPerNodeM;
%     IndexT=(EleIndex-1)*DOFPerElemMEE+1: ...,
%             EleIndex*DOFPerElemMEE;
%          
%     KutT(IndexR,IndexT)=KutT(IndexR,IndexT)+ ...,
%             Kut((m-1)*DOFPerNodeM+1:m*DOFPerNodeM,1:DOFPerElemMEE); 
%     KtuT(IndexT,IndexR)=KtuT(IndexT,IndexR)+ ...,
%             Ktu(1:DOFPerElemMEE,(m-1)*DOFPerNodeM+1:m*DOFPerNodeM); 
% end     
%%%%Assembling Kft into KftT, Ktf into KtfT  hzt+
% IndexR=(EleIndex-1)*DOFPerElemMEE+1: ...,
%         EleIndex*DOFPerElemMEE;
%     
%     KftT(IndexR,1)=KftT(IndexR,1)+Kft(1:DOFPerElemMEE ,1);
%     KftT(IndexR,2)=KftT(IndexR,2)+Kft(1:DOFPerElemMEE ,2);
%     KtfT(1,IndexR)=KtfT(1,IndexR)+Ktf(1,1:DOFPerElemMEE );
%     KtfT(2,IndexR)=KtfT(2,IndexR)+Ktf(2,1:DOFPerElemMEE );
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%%Assembling Kzt into KztT, Ktz into KtzT  hzt+
% IndexR=(EleIndex-1)*DOFPerElemMEE+1: ...,
%         EleIndex*DOFPerElemMEE;
%     
%     KztT(IndexR,1)=KztT(IndexR,1)+Kzt(1:DOFPerElemMEE,1);
%     KztT(IndexR,2)=KztT(IndexR,2)+Kzt(1:DOFPerElemMEE,2);
%     KtzT(1,IndexR)=KtzT(1,IndexR)+Ktz(1,1:DOFPerElemMEE);
%     KtzT(2,IndexR)=KtzT(2,IndexR)+Ktz(2,1:DOFPerElemMEE);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%Assembling Kff into KffT, Kzz into KzzT, Kfz into KfzT, Kzf into KzfT
IndexS=(EleIndex-1)*DOFPerElemMEE+1: ...,
        EleIndex*DOFPerElemMEE;
IndexQ=(EleIndex-1)*DOFPerElemMEE+1: ...,
        EleIndex*DOFPerElemMEE;     

    KffMT(IndexS,IndexQ)=KffMT(IndexS,IndexQ)+KffM;
    KzzT(IndexS,IndexQ)=KzzT(IndexS,IndexQ)+Kzz;
    KfzT(IndexS,IndexQ)=KfzT(IndexS,IndexQ)+ Kfz;         
    KzfT(IndexQ,IndexS)=KzfT(IndexQ,IndexS)+Kzf; 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%Assembling Kft into KftT, Ktf into KtfT, Kzt into KztT, Ktz into KtzT
IndexS=(EleIndex-1)*DOFPerElemMEE+1: ...,
        EleIndex*DOFPerElemMEE;
IndexT=(EleIndex-1)*DOFPerElemMEE+1: ...,
        EleIndex*DOFPerElemMEE;     

    KftT(IndexS,IndexT)=KftT(IndexS,IndexT)+Kft;
    KtfT(IndexT,IndexS)=KtfT(IndexT,IndexS)+Ktf;
    KztT(IndexS,IndexT)=KztT(IndexS,IndexT)+Kzt;         
    KtzT(IndexT,IndexS)=KtzT(IndexT,IndexS)+Ktz;
    KttT(IndexS,IndexT)=KttT(IndexS,IndexT)+Ktt;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%Assembling Fu into FuT
for m=1:NodePerElem
    IndexR=(Element(EleIndex,m)-1)*DOFPerNodeM+1: ...,
            Element(EleIndex,m)*DOFPerNodeM;
    FusT(IndexR,1)=FusT(IndexR,1)+Fus((m-1)*DOFPerNodeM+1:m*DOFPerNodeM,1);
    FuiT(IndexR,1)=FuiT(IndexR,1)+Fui((m-1)*DOFPerNodeM+1:m*DOFPerNodeM,1);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%Assembling Gf into GfT
IndexR=(EleIndex-1)*DOFPerElemMEE+1: ...,
        EleIndex*DOFPerElemMEE;
    
    GfMT(IndexR,1)=GfMT(IndexR,1)+GfM;
    GfiMT(IndexR,1)=GfiMT(IndexR,1)+GfiM;
    MzT(IndexR,1)=MzT(IndexR,1)+Mz;
    MziT(IndexR,1)=MziT(IndexR,1)+Mzi;
    FtT(IndexR,1)=FtT(IndexR,1)+Ft;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% undated on 7 march, 2013
MuuT = sparse(MuuT);
KuuT = sparse(KuuT);
CuuT = sparse(CuuT);
%%%%%%%%%%双向耦合可能用到的矩阵
% MutT = sparse(MutT);
% MtuT = sparse(MtuT);
% MttT = sparse(MttT);
% CutT = sparse(CutT);
% CtuT = sparse(CtuT);
% CttT = sparse(CttT);
%%%%%%%%%%%

KufMT = sparse(KufMT);
KfuMT = sparse(KfuMT);
KffMT = sparse(KffMT);

KuzT=sparse(KuzT);
KzuT=sparse(KzuT);
KfzT=sparse(KfzT);
KzfT=sparse(KzfT);
KzzT=sparse(KzzT);

KutT = sparse(KutT);
KtuT = sparse(KtuT);
KftT = sparse(KftT);
KtfT = sparse(KtfT);
KztT = sparse(KztT);
KtzT = sparse(KtzT);
KttT = sparse(KttT);

FuiT = sparse(FuiT);
FusT = sparse(FusT);
FucT = sparse(FucT);
GfiMT = sparse(GfiMT);
GfMT = sparse(GfMT);
MziT= sparse(MziT);
MzT= sparse(MzT);
FtT= sparse(FtT);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Assemling--------------------------------------------------------------End
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Construct Global matrices, return value
GlobMatr = struct('MuuT',MuuT,'KuuT',KuuT,'CuuT',CuuT,...
    'KufMT',KufMT, 'KfuMT',KfuMT,'KffMT',KffMT,'FuiT',FuiT,'FusT',FusT, ...
    'FucT',FucT,'KuzT',KuzT,'KzuT',KzuT,'KfzT',KfzT,'KzfT',KzfT,'KzzT',KzzT,...
    'KutT',KutT,'KtuT',KtuT,'KftT',KftT,'KtfT',KtfT,'KztT',KztT,'KtzT',KtzT,...
   'KttT',KttT, 'GfiMT',GfiMT,'GfMT',GfMT,'MziT',MziT,'MzT',MzT,'FtT',FtT);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%             
% fprintf('::SF_Assembling----------------------EleIndex=%d\n',EleIndex);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end


