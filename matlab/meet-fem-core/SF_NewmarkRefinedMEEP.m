%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [XY_Value]=SF_NewmarkRefinedMEEP(GlobMatr,K_nmk,F_nmk, ...
                                 TimePara,PositionM,PositionMEE,DeltaT,QFdva,IsDamp)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Qd1 = QFdva.Qd;
Qv1 = QFdva.Qv;
Qa1 = QFdva.Qa;
% Phi1 = QFdva.Phi;
%% Get system matrices
M_nmk = GlobMatr.MuuT;

%%% 
if IsDamp == 1
    C_nmk = GlobMatr.CuuT; 
else
    C_nmk = GlobMatr.CuuT*0; 
end
KfuMT = GlobMatr.KfuMT;
KffMT = GlobMatr.KffMT;
KfzT = GlobMatr.KfzT;
KzfT = GlobMatr.KzfT;
KzuT = GlobMatr.KzuT;
KzzT = GlobMatr.KzzT;

KutT = GlobMatr.KutT;%hzt+
KftT = GlobMatr.KftT;
KztT = GlobMatr.KztT;
KtuT = GlobMatr.KtuT;
KtfT = GlobMatr.KtfT;
KtzT = GlobMatr.KtzT;

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
Tot_DOF_MEE = length(KffMT(:,1));
DOF_NumMEE = length(PositionMEE);
DOF_NumM = length(PositionM);

Y_Disp = zeros(Steps,DOF_NumM);
Y_Disp(1,:) = Qd1(PositionM);

Y_SensM_E = zeros(Steps,DOF_NumMEE);
Y_SensM_M = zeros(Steps,DOF_NumMEE);


X_Time = zeros(Steps,1);
X_Time(1,1) = TimeStart;
% Qd1=inv(K_nmk)*F_nmk;
F2 = F_nmk;
%   sig=zeros(Steps,1);
%   sig(2)=1;
for i = 2:Steps
    K_cm = K_nmk + a0*M_nmk + a1*C_nmk;
    M_cm = a6*M_nmk + a5*C_nmk;
    C_cm = a7*C_nmk - a2*M_nmk;
    
    %F2=F_nmk-KufT*60*sin(2*pi/1*TimeStart)*fa;
    
    %DQd = K_cm\(F2*sig(i) - M_cm*Qa1 - C_cm*Qv1 - K_nmk*Qd1);
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

    fprintf('::SF_NewmarkRefined-----Loops=%d/%d\n',i,Steps);
end
%% Construct return variable
XY_Value = struct('X_Time',X_Time,'Y_Disp',Y_Disp, ...
    'Y_SensM_E',Y_SensM_E,'Y_SensM_M',Y_SensM_M);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end