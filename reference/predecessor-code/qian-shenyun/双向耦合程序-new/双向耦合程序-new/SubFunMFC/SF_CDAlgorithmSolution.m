%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Subfuntion SF_CDAlgorithmSolution
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
function [XY_Value]=SF_CDAlgorithmSolution(GlobMatr,K_nmk,F_nmk, ...
                                 TimePara,PositionM,PositionE,QFdva,IsDamp)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Qd1 = QFdva.Qd;
Qv1 = QFdva.Qv;
Qa1 = QFdva.Qa;
Phi1 = QFdva.Phi;

%% Motion equation
%%% M_nmk*Qa + C_nmk*Qv + K_nmk*Qd = F_nmk;

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

%% Iniatil value of Qa
Fresidual = F_nmk - C_nmk*Qv1 - K_nmk*Qd1;
Qa1 = M_nmk\Fresidual;
Qd0 = Qd1 - TStep*Qv1 + TStep^2/2*Qa1;

for i=2:Steps
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    Fresidual = F_nmk - (K_nmk-2/(TStep^2)*M_nmk)*Qd1 - (1/(TStep^2)*M_nmk - ...
                1/(2*TStep)*C_nmk)*Qd0;

    Qd2 = (M_nmk/(TStep^2) + C_nmk/(2*TStep))\Fresidual;

    Qd0 = Qd1;
    Qd1 = Qd2;

    Time = Time+TStep; 
    
    X_Time(i) = Time;
    Y_Disp(i,1:DOF_NumM) = (Qd1(PositionM))';
    
    fsensor = -KffT\KfuT*Qd1;
    Y_Sens(i,1:DOF_NumE) = fsensor(PositionE);   

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    fprintf('::SF_CDAlgorithmSolution-----Loops=%d/%d\n',i,Steps);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

%% Construct return variable
XY_Value = struct('X_Time',X_Time,'Y_Disp',Y_Disp,'Y_Sens',Y_Sens);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end