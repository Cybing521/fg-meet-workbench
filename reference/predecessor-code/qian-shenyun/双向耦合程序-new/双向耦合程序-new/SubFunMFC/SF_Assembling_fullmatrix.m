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
KuuT = GlobMatr.KuuT;
KufT = GlobMatr.KufT;
KfuT = GlobMatr.KfuT;
KffT = GlobMatr.KffT;
KuzT= GlobMatr.KuzT
KfzT= GlobMatr.KuzT
KzzT= GlobMatr.KuzT
FuiT = GlobMatr.FuiT;
FusT = GlobMatr.FusT;
FucT = GlobMatr.FucT;
GfiT =  GlobMatr.GfiT;
GfT = GlobMatr.GfT;
MfT= GlobMatr.MfT;

%% Element matrices
Muu = ElemMatr.Muu;
Kuu = ElemMatr.Kuu;
Kuf = ElemMatr.Kuf;
Kfu = ElemMatr.Kfu;
Kff = ElemMatr.Kff;
 KuzT= ElemMatr.KuzT;
  KfzT= ElemMatr.KuzT;
   KzzT= ElemMatr.KuzT;
Fui = ElemMatr.Fui;
Fus = ElemMatr.Fus;
Fuc = ElemMatr.Fuc;
Gfi = ElemMatr.Gfi;
Gf = ElemMatr.Gf;
MfT= ElemMatr.MfT;

%% Finite Element informatin
ElemType = FinitElemInfo.ElemType;
Element = FinitElemInfo.Element;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Assemling------------------------------------------------------------Start
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
NodePerElem = ElemType(1);
DOFPerNodeM = ElemType(2);
NumSmtLay = ElemType(3);
DOFPerSmtLayE = ElemType(4);
NumLay = ElemType(5);
DOFPerMEELay = ElemType(6);
 NumMEELay = ElemType(7);
DOFPerEelmentE = NumSmtLay*DOFPerSmtLayE;
DOFPerElemMEE = NumMEELay*DOFPerMEELay;
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
%%%%Assembling Kuf into KufT, Kfu into KufT
for m=1:NodePerElem
    IndexR=(Element(EleIndex,m)-1)*DOFPerNodeM+1: ...,
            Element(EleIndex,m)*DOFPerNodeM;
    IndexC=(EleIndex-1)*DOFPerEelmentE+1: ...,
            EleIndex*DOFPerEelmentE;
    IndexS=(EleIndex-1)*DOFPerEelmentMEE+1: ...,
            EleIndex*DOFPerEelmentMEE;      
    KufT(IndexR,IndexC)=KufT(IndexR,IndexC)+ ...,
            Kuf((m-1)*DOFPerNodeM+1:m*DOFPerNodeM,1:DOFPerEelmentE);
    KfuT(IndexC,IndexR)=KfuT(IndexC,IndexR)+ ...,
            Kfu(1:DOFPerEelmentE,(m-1)*DOFPerNodeM+1:m*DOFPerNodeM);
      KuzT(IndexR,IndexS)=KuzT(IndexR,IndexS)+ ...,
            Kuz((m-1)*DOFPerNodeM+1:m*DOFPerNodeM,1:DOFPerEelmentMEE);
      KfzT(IndexC,IndexS)=KfzT(IndexC,IndexS)+ ...,
           KfzT(1:DOFPerEelmentE,1:DOFPerEelmentMEE);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%Assembling Kff into KffT
IndexR=(EleIndex-1)*DOFPerEelmentE+1: ...,
        EleIndex*DOFPerEelmentE;
IndexC=(EleIndex-1)*DOFPerEelmentE+1: ...,
        EleIndex*DOFPerEelmentE;
IndexS=(EleIndex-1)*DOFPerEelmentMEE+1: ...,
        EleIndex*DOFPerEelmentMEE;
IndexQ=(EleIndex-1)*DOFPerEelmentMEE+1: ...,
        EleIndex*DOFPerEelmentMEE;     
KffT(IndexR,IndexC)=KffT(IndexR,IndexC)+Kff;
KzzT (IndexS,IndexQ)=KzzT(IndexS,IndexQ)+Kzz;

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
IndexR=(EleIndex-1)*DOFPerEelmentE+1: ...,
        EleIndex*DOFPerEelmentE;
GfT(IndexR,1)=GfT(IndexR,1)+Gf;
GfiT(IndexR,1)=GfiT(IndexR,1)+Gfi;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Assemling--------------------------------------------------------------End
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Construct Global matrices, return value
GlobMatr = struct('MuuT',MuuT,'KuuT',KuuT,'CuuT',CuuT,'KufT',KufT, ...
                  'KfuT',KfuT,'KffT',KffT,'FuiT',FuiT,'FusT',FusT, ...
                  'FucT',FucT,'GfiT',GfiT,'GfT',GfT);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%             
fprintf('::SF_Assembling----------------------EleIndex=%d\n',EleIndex);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end


