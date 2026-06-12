%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [XY_Value]=SF_NewmarkRefined_MEEP_Ctl(GlobMatr,FueT,...
                        PhiaMT,MgaT,DeltaT,Gain,TimePara,PositionM,PositionMEE,PositionV,QFdva,IsDamp)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Qd1 = QFdva.Qd;
Qv1 = QFdva.Qv;
Qa1 = QFdva.Qa;
% Phi1 = QFdva.Phi;
%% Get system matrices
KufMT = GlobMatr.KufMT;
KfuMT = GlobMatr.KfuMT;
KffMT = GlobMatr.KffMT;
KfzT = GlobMatr.KfzT;
KzfT = GlobMatr.KzfT;
KuzT = GlobMatr.KuzT;
KzuT = GlobMatr.KzuT;
KutT = GlobMatr.KutT;
KftT = GlobMatr.KftT;
KztT = GlobMatr.KztT;
KzzT = GlobMatr.KzzT;
M_nmk = GlobMatr.MuuT;
F_nmk = FueT;
K_nmk = GlobMatr.KuuT;
%%% 
if IsDamp == 1
    C_nmk = GlobMatr.CuuT; 
else
    C_nmk = GlobMatr.CuuT*0; 
end
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
TimeStart = TimePara(1);
TStep = TimePara(2);       %The Steps no more than 1000 is better
TimeTotal = TimePara(3);
Time = TimeStart;          %Temporary varialbe for memory time
Steps=round(TimeTotal/TStep)+1;
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%  Impulse Correction %%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%%%%%%%%%%%%%%%  Impuls timestep 
% %%% total impulse time
% 
% Time_Impls = 3e-4;
% Steps_Impls = round(Time_Impls/TStep)+1;
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Parameters for newmark method
Gama=0.5;
Bata=0.25;

a0 = 1/(Bata*TStep^2);
a2 = 1/(Bata*TStep);
a4 = 1/(2*Bata);

a1 = Gama/(Bata*TStep);
a3 = Gama/Bata;
a5 = (1-Gama/(2*Bata))*TStep;

a6 = 1-1/(2*Bata);
a7 = 1-Gama/Bata;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Initiate time vector X_value and displacement vector Y_value
DOF_NumM=length(PositionM);
DOF_NumMEE=length(PositionMEE);
X_Time = zeros(Steps,1);
Y_Disp = zeros(Steps,DOF_NumM);
Y_Act = zeros(Steps,1);
X_Time(1,1) = TimeStart;
Y_Disp(1,:) = Qd1(PositionM);
Y_SensM_E = zeros(Steps,DOF_NumMEE);
Y_SensM_M = zeros(Steps,DOF_NumMEE);
Tot_DOF_MEE = length(KffMT(:,1));
% if isempty(MagSeriesF) == 1
%     MagSeriesF = zeros(Steps,1);
% end
% if isempty(MagSeriesE) == 1
%     MagSeriesE = zeros(Steps,1);
% end
% Qd1=inv(K_nmk)*F_nmk;
for i = 2:Steps
    K_cm = K_nmk + a0*M_nmk + a1*C_nmk;
    M_cm = a6*M_nmk + a5*C_nmk;
    C_cm = a7*C_nmk - a2*M_nmk;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%    Impulse force correction   %%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Y_Act(i,1) = - Gain*Qv1(PositionV);
    FuaT = KufMT*PhiaMT*(Y_Act(i,1));
    FumT = KuzT*MgaT*(Y_Act(i,1));
    FutT = KutT*DeltaT*(Y_Act(i,1));
    F_nmk = FueT; 
    F2 = F_nmk-FuaT-FumT-FutT;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    DQd = K_cm\(F2 - M_cm*Qa1 - C_cm*Qv1 - K_nmk*Qd1);
    DQv = a1*DQd - a3*Qv1 + a5*Qa1;
    DQa = a0*DQd - a2*Qv1 - a4*Qa1;
    
    Qd1 = Qd1 + DQd;
    Qv1 = Qv1 + DQv;
    Qa1 = Qa1 + DQa;    
    Time = Time+TStep;   
    
    X_Time(i) = Time;
    Y_Disp(i,1:DOF_NumM) = (Qd1(PositionM))';  
    AA=[KffMT,KfzT; KzfT,KzzT];
    BB=[-KfuMT*Qd1-KftT*DeltaT; -KzuT*Qd1-KztT*DeltaT];
    CC=AA\BB;
    SensM_E = CC(1:Tot_DOF_MEE);
    SensM_M = CC(Tot_DOF_MEE+1:end);   

    Y_SensM_E(i,1:DOF_NumMEE) = SensM_E(PositionMEE);
    Y_SensM_M(i,1:DOF_NumMEE) = SensM_M(PositionMEE);
    
    fprintf('::SF_NewmarkRefined_VFC_Final-----Loops=%d/%d\n',i,Steps);
end

%% Construct return variable
XY_Value = struct('X_Time',X_Time,'Y_Disp',Y_Disp,'Y_SensM_E',Y_SensM_E,'Y_SensM_M',Y_SensM_M,'Y_Act',Y_Act);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end