%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [XY_Value]=SF_NewmarkRefinedMEET_trial(GlobMatr,K_nmk,F_nmk, ...
                                 TimePara,PositionM,PositionMEE,DelT,QFdva,IsDamp)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%将需要求解的位移和温差看作整体
m = length(GlobMatr.KuuT(1,:));
n = length(GlobMatr.KzzT(1,:));
Qd1 = zeros(m+n,1);
Qv1 = zeros(m+n,1);
Qa1 = zeros(m+n,1);
% Qd1 = QFdva.Qd;
% Qv1 = QFdva.Qv;
% Qa1 = QFdva.Qa;
% Phi1 = QFdva.Phi;
%% Get system matrices
MuuT = GlobMatr.MuuT;
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
KttT = GlobMatr.KttT;
%设置双向耦合可能用上的矩阵
m = length(GlobMatr.KuuT(1,:));
n = length(GlobMatr.KzzT(1,:));
MutT = zeros(m,n);
MtuT = zeros(n,m);
MttT = zeros(n,n);
CutT = zeros(m,n);
CtuT = zeros(n,m);
CttT = zeros(n,n);
%%%%%%%%%
M_nmk = [GlobMatr.MuuT,MutT;MtuT,MttT];
% F_nmk = zeros(FinalDofM,1);
%%% 
if IsDamp == 1
    C_nmk = [GlobMatr.CuuT,CutT;CtuT,CttT];
else
    C_nmk = [GlobMatr.CuuT*0,CutT;CtuT,CttT]; 
end
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
Y_SensM_T = zeros(Steps,DOF_NumMEE);


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
    SensM_T = Qd1(m+1:end);
    Time = Time+TStep;   
    X_Time(i) = Time; 
    Y_Disp(i,1:DOF_NumM) = (Qd1(PositionM))';
    Y_SensM_T(i,1:DOF_NumMEE) = SensM_T(PositionMEE);
    
%     AA=KttT;
%     BB=-KtuT*Qd1;
%     CC=AA\BB;
%     SensM_T = CC;  
%     Y_SensM_T(i,1:DOF_NumMEE) = SensM_T(PositionMEE);

    fprintf('::SF_NewmarkRefined-----Loops=%d/%d\n',i,Steps);
end
%% Construct return variable
XY_Value = struct('X_Time',X_Time,'Y_Disp',Y_Disp,'Y_SensM_T',Y_SensM_T);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end