%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Subfuntion GetCMatrix
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [GlobMatr]=SF_GetDampingMatrix(DampRatio_1,DampRatio_m,Mode_m, ...
                                        Mode_max,GlobMatr)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Globla matrices
  MuuT = GlobMatr.MuuT;
    CuuT = GlobMatr.CuuT;
    KuuT = GlobMatr.KuuT;
    KufPT = GlobMatr.KufPT;
    KufMT = GlobMatr.KufMT;
    
    KfuPT = GlobMatr.KfuPT;
      KfuMT = GlobMatr.KfuMT;
      
    KffPT = GlobMatr.KffPT;
        KffMT = GlobMatr.KffMT;
   KfzT=GlobMatr.KfzT;
   KzfT=GlobMatr.KzfT;
   KuzT=GlobMatr.KuzT;
   KzuT=GlobMatr.KzuT;
   KzzT=GlobMatr.KzzT;
   FuiT = GlobMatr.FuiT;
FusT = GlobMatr.FusT;
FucT = GlobMatr.FucT;
GfiT = GlobMatr.GfiT;
GfT = GlobMatr.GfT;

M=MuuT;
K=KuuT;%-KufT/KffT*KfuT;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Computing the eigenvectors and eigenvalues--------------------End1
L=chol(K,'lower');
H=L\M/(L');
%Solution of eigenvalue and eigenvector
[EigenVector,EigenValue]=eigs(H,50);

EigenVector=(L')\EigenVector;
%Computing the eigenvectors and eigenvalues--------------------End1

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Calculate damping matrix
%DampRatio_1=2/100;
%DampRatio_m=10/100;
%Mode_m=6;
%Mode_max=2.5*6;
%Set the default value-----------------------------------------End2
if DampRatio_1<0
   DampRatio_1=2/100; 
end

if DampRatio_m<0
   DampRatio_m=10/100; 
end

if Mode_m<0
   Mode_m=6; 
end

if Mode_max<0
   Mode_max=2.5*Mode_m; 
end
%Set the default value-----------------------------------------End2

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Omiga_1=1/sqrt(EigenValue(1,1));
Omiga_m=1/sqrt(EigenValue(Mode_m,Mode_m));

FreqDampR=zeros(Mode_max,5);
for i=1:Mode_max   
    if i<=Mode_m
        Omiga_i=1/sqrt(EigenValue(i,i));
        DampRatio_i=(DampRatio_m-DampRatio_1)/(Omiga_m-Omiga_1)*(Omiga_i-Omiga_1)+DampRatio_1;        
    else
        Omiga_mi=1/sqrt(EigenValue(Mode_m+i,Mode_m+i));
        DampRatio_i=(DampRatio_m-DampRatio_1)/(Omiga_m-Omiga_1)*(Omiga_mi-Omiga_m)+DampRatio_1;
    end
    FreqDampR(i,1)=Omiga_i;
    FreqDampR(i,2)=DampRatio_i;
end

Bata=2*(DampRatio_1*Omiga_1-DampRatio_m*Omiga_m)/(Omiga_1^2-Omiga_m^2);
Alfa=2*DampRatio_1*Omiga_1-Bata*Omiga_1^2;
Bata1=Bata;
Alfa1=Alfa;

DampRatio_max=FreqDampR(Mode_max,2);
Omiga_max=FreqDampR(Mode_max,1);
Bata=2*(DampRatio_1*Omiga_1-DampRatio_max*Omiga_max)/(Omiga_1^2-Omiga_max^2);
Alfa=2*DampRatio_1*Omiga_1-Bata*Omiga_1^2;
Bata2=Bata;
Alfa2=Alfa;

Bata=(Bata1+Bata2)/2;
Alfa=(Alfa1+Alfa2)/2;

%Return the C damping matrix
CuuT=Alfa*M+Bata*K;

%% Construc Global matrices, as a return value
GlobMatr = struct('MuuT',MuuT,'KuuT',KuuT','KufPT',KufPT,'KfuPT',KfuPT,'KffPT',KffPT,'KufMT',KufMT,'KfuMT',KfuMT,'KffMT',KffMT,'KfzT',KfzT,'KzfT',KzfT,'KzzT',KzzT,'KuzT',KuzT,'KzuT',KzuT, ...
                   'FuiT',FuiT,'FusT',FusT, 'FucT',FucT,'GfiT',GfiT,'GfT',GfT);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end   %end of the function
