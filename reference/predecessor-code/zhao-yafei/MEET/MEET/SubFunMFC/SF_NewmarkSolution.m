%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Subfuntion SF_NewmarkSolution
%Geting time behavior
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % %%%%%%%%%%Format for calling this function
% % load('Sungyi_5Element_8323.mat');
% % 
% % M_nmk=MuuT;
% % C_nmk=CuuT;
% % K_nmk=KuuT-KufT*inv(KffT)*KfuT;
% % TimePara=[0 0.002 2];
% % PositionM=70;
% % PositionE=[18 24];
% % %%%%%%%%%%%%%%%%%%%%%%%%
% % %%%Initial value
% % F_nmk=FuT;
% % Qd1=inv(K_nmk)*F_nmk;
% % F_nmk=[];
% % Qv1=[];
% % Qa1=[];
% % %%%%%%%%%%%%%%%%%%%%%%%%
% % 
% % [X_value,Y_value]=SF_NewmarkSolution(M_nmk,C_nmk,K_nmk,F_nmk,TimePara, ...
% %                                      PositionM,PositionE, ...
% %                                      Qd1,Qv1,Qa1);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%Specification
%TimePara=[TimeStart TStep TimeTotal]
%PositionM=[a;b;c...],get the mechanical value at a,b,c ... positions
%PositionE=[a;b;c...],get the electrical value at a,b,c ... positions


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [XY_Value]=SF_NewmarkSolution(GlobMatr,K_nmk,F_nmk, ...
                                 TimePara,PositionM,PositionE,QFdva,IsDamp)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Qd1 = QFdva.Qd;
Qv1 = QFdva.Qv;
Qa1 = QFdva.Qa;
Phi1 = QFdva.Phi;
%% Get system matrices
M_nmk = GlobMatr.MuuT;

%%% 
if IsDamp == 1
    C_nmk = GlobMatr.CuuT; 
else
    C_nmk = GlobMatr.CuuT*0; 
end

KufT = GlobMatr.KufT;
KfuT = GlobMatr.KfuT;
KffT = GlobMatr.KffT;
% M_F2S = M_nmk;
% C_F2S = C_nmk;
% K_F2S = K_nmk;
% F_F2S = F_nmk;
% [M,C,K,F,S]=SF_FEMtoSSM_3(M_F2S,C_F2S,K_F2S,F_F2S);
FinalDofM=length(M_nmk(1,:));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(M_nmk)||isempty(C_nmk)||isempty(K_nmk)||isempty(F_nmk)
   fprintf('::ERROR: M,C,K,F are empty!!!');
end

if isempty(TimePara)
    TimePara=[0 0.002 1];
end

%initial value Q,Qv,Qa
if isempty(Qd1)
    Qd1=zeros(FinalDofM,1);
end

if isempty(Qv1)
    Qv1=zeros(FinalDofM,1);
end

if isempty(Qa1)
    Qa1=zeros(FinalDofM,1);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Parameters for newmark method
Gama=0.5;
Bata=0.25;

TimeStart=TimePara(1);
TStep=TimePara(2);       %The Steps no more than 1000 is better
TimeTotal=TimePara(3);
Time=TimeStart;          %Temporary varialbe for memory time

Steps=round(TimeTotal/TStep)+1;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Initiate time vector X_value and displacement vector Y_value
DOF_NumM=length(PositionM);
DOF_NumE=length(PositionE);

X_Time = zeros(Steps,1);
Y_Disp = zeros(Steps,DOF_NumM);
Y_Sens = zeros(Steps,DOF_NumE);
X_Time(1,1) = TimeStart;
Y_Disp(1,:) = Qd1(PositionM);

% Qd1=inv(K_nmk)*F_nmk;
for i=2:Steps
    Kcm=K_nmk*Bata*TStep^2+C_nmk*Gama*TStep+M_nmk;
    
    %F2=F_nmk-KufT*60*sin(2*pi/1*TimeStart)*fa;
    F2=F_nmk;
    Fresidual=F2-K_nmk*(Qd1+TStep*Qv1+TStep^2*(1/2-Bata)*Qa1)-C_nmk*(Qv1+TStep*(1-Gama)*Qa1);
    Qa2=Kcm\Fresidual;
    Qd2=Qd1+TStep*Qv1+TStep^2*((1/2-Bata)*Qa1+Bata*Qa2);
    Qv2=Qv1+TStep*((1-Gama)*Qa1+Gama*Qa2); 
    
    Qd1=Qd2;
    Qv1=Qv2;
    Qa1=Qa2;
    Time=Time+TStep; 
    
    X_Time(i)=Time;
    Y_Disp(i,1:DOF_NumM)=(Qd1(PositionM))';
    
    fsensor=-KffT\KfuT*Qd1;
    Y_Sens(i,1:DOF_NumE)=fsensor(PositionE);   
    
    fprintf('::SF_NewmarkSolution-----Loops=%d/%d\n',i,Steps);
end

%% Construct return variable
XY_Value = struct('X_Time',X_Time,'Y_Disp',Y_Disp,'Y_Sens',Y_Sens);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end