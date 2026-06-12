%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Main_DynmNL851T5T56MEEP_Nmk_V4(), only the newmark method is different
% Main function for computing Nonlinear dynamic response

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Call this Main Function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [XY_Value] = Main_DynmNL851T5T56MEEP_Nmk_V4(InputFile,Dynm_UsedDataFile, ...
      TimePara,PositionM,PositionMEE,FueT,QFdva,IsDamp,IsANS,Theory,DampRatio, ...
      DeltaT,IntegSchem,ThermalNL)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% ElemType = [Node/Elem DOF/Node NumSmtLay DOF/SmtLay NumLay]

%% check theory, string to integer
[TheoryInt,TheoryStr] = SF_TheoryNotation(Theory);

%% Get data from input file
%%% FinitElemInfo: ElemType,Element,Node
%%% Material: Material parameters for every layer
[FinitElemInfo,Material] = SF_GetInputDataMEEP(InputFile);
[MateProp] = SF_GetMatePropMEEP(Material,FinitElemInfo);
SF_GetUsedData(Dynm_UsedDataFile,FinitElemInfo,Material,MateProp);
[Totalthickness] = SF_Totalthickness(FinitElemInfo,Material,MateProp);
[FinitElemInfo,Material] = SF_GetInputDataMEEP(InputFile);
[ERROR] = SF_InputFileCheckMEEP(FinitElemInfo,Material);
%%% ERROR: 0, input correct; 1-10, input has mistaks;
if ERROR ~=0
    return
end

%%% Theory
FinitElemInfo.ShellTheory(2,1) = TheoryInt;

%% Get material parameters from Material matrix
%%% MateProp{LayIndex,1}.c, MateProp{LayIndex,1}.e, MateProp{LayIndex,1}.g
%%% MateProp{LayIndex,1}.Density, MateProp{LayIndex,1}.Lay_zC
%%% MateProp{LayIndex,1}.IsSmtLay
[MateProp] = SF_GetMatePropMEEP(Material,FinitElemInfo);

%% Get Basic values
ElemType = FinitElemInfo.ElemType;
Element = FinitElemInfo.Element;
% Node = FinitElemInfo.Node;

NumElem = length(Element(:,1));

NodePerElem = ElemType(1);
% DOFPerNodeM = ElemType(2);
% NumSmtLay = ElemType(3);
% DOFPerSmtLayE = ElemType(4);
NumLay = ElemType(3);

% DOFPerElemM = NodePerElem*DOFPerNodeM;
% DOFPerElemE = NumSmtLay*DOFPerSmtLayE;

% DOFTotalM = NumNode*DOFPerNodeM;
% DOFTotalE = NumElem*DOFPerElemE;
   

%% Output the data that was use during calculation
SF_GetUsedData(Dynm_UsedDataFile,FinitElemInfo,Material,MateProp);
%% Newmark method
if isempty(TimePara)
   TimePara=[0 0.0001 0.1]; 
end
%%%%%%%%%%%%%%%%%%%%%%%%
Qd1 = QFdva.Qd;
Qv1 = QFdva.Qv;
Qa1 = QFdva.Qa;
PhiaM1 = QFdva.PhiaM;
PhisM1 = QFdva.PhisM;
Mga1 = QFdva.Mga;
Mgs1= QFdva.Mgs;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
TimeStart = TimePara(1);
TStep = TimePara(2);       %The Steps no more than 1000 is better
TimeTotal = TimePara(3);
Time = TimeStart;          %Temporary varialbe for memory time

Steps=round(TimeTotal/TStep)+1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Gama=1/2;
Bata=1/4;

a0 = 1/(Bata*TStep^2);
a2 = 1/(Bata*TStep);
a4 = 1/(2*Bata);

a1 = Gama/(Bata*TStep);
a3 = Gama/Bata;
a5 = (1-Gama/(2*Bata))*TStep;

a6 = 1-1/(2*Bata);
a7 = 1-Gama/Bata;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initiate time vector X_value and displacement vector Y_value
DOF_NumM = length(PositionM);
DOF_NumMEE = length(PositionMEE);

X_Time = zeros(Steps,1);
Y_Disp = zeros(Steps,DOF_NumM);
Y_SensM_E = zeros(Steps,DOF_NumMEE);
Y_SensM_M = zeros(Steps,DOF_NumMEE);
X_Time(1,1) = TimeStart;
Y_Disp(1,:) = Qd1(PositionM);
Y_SensM_E(1,:) =PhisM1(PositionMEE);
Y_SensM_M(1,:) =Mgs1(PositionMEE);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for TimeIndex = 2:Steps
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Qd = Qd1;
    Qv = Qv1;
    Qa = Qa1;
    PhiaM = PhiaM1;
    PhisM = PhisM1;
    Mga = Mga1;
    Mgs= Mgs1;
    %%% Get displacement of all nodes ordered by its node index sequency
    [TQFdva] = SF_GetTQFdva_V3(FinitElemInfo,MateProp,Qd,Qv,Qa,PhiaM,PhisM,Mga,Mgs);
    %%% Initial Global matrices, MuuT,CuuT,KuuT.....
    [GlobMatr] = SF_InitGlobMatr(FinitElemInfo);
    for EleIndex=1:NumElem
        for LayIndex = 1:NumLay
            if Element(EleIndex,NodePerElem+LayIndex) == 1
                %%% Calculate ith layer of structure
                MatePropCurrLay = MateProp{LayIndex,1};
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%% Element computation
                %%% Element computation
                %%% IsANS: 1, using ANS formulation; 
                %%%        0, without using ANS formulation
                
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
        switch TheoryInt
            case {1,2,3} %%% LRT5/MRT5/RVK5
                if IsANS == 0
                 [ElemMatr]=SF_ElemComptNL851T5MEEP_V4(EleIndex,MatePropCurrLay, ...
                                           MateProp,LayIndex,FinitElemInfo,TQFdva,IntegSchem,Totalthickness,ThermalNL);
                elseif IsANS == 1

                end 
            case 4 %%% LRT56
                if IsANS == 0
                  [ElemMatr]=SF_ElemComptNL851T56MEEP_V4(EleIndex,MatePropCurrLay, ...
                                           MateProp,LayIndex,FinitElemInfo,TQFdva,IntegSchem,Totalthickness,ThermalNL);
                elseif IsANS == 1

                end 
            otherwise
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %Assembling
                [GlobMatr]=SF_Assembling(EleIndex,ElemMatr,GlobMatr, ...
                                         FinitElemInfo);
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            end
        end
    end
    [GlobMatr]=SF_Condensation(GlobMatr,FinitElemInfo,MateProp);
   
    %% Calculate damping matrix
    %%% IsDamp: 0, Damping matrix C is a zero matrix; 
    %%%         1, Damping matrix C is obtained by the assumption of the 
    %%%            first 6 modes damped at the ratio of 0.8, 7-15 modes ...
    if IsDamp == 1 
        if DampRatio < 0
            DampRatio = 0.8/100;
        end
        Mode_m = 6;
        Mode_max = 2.5*Mode_m;
        
        DampRatio_1 = DampRatio;
        DampRatio_m = DampRatio*Mode_m;
        
        [GlobMatr] = SF_GetDampingMatrix(DampRatio_1,DampRatio_m,Mode_m, ...
                                        Mode_max,GlobMatr);   
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% %%%%%%%%%%%%%
    M_nmk = GlobMatr.MuuT;
    K_nmk = GlobMatr.KuuT;
    C_nmk = GlobMatr.CuuT;
    KfuMT = GlobMatr.KfuMT;
    KffMT = GlobMatr.KffMT;
    KzuT= GlobMatr.KzuT;
    KfzT= GlobMatr.KfzT;
    KzfT= GlobMatr.KzfT;
    KzzT= GlobMatr.KzzT;
    KutT = GlobMatr.KutT;%hzt+
    KftT = GlobMatr.KftT;
    KztT = GlobMatr.KztT;
    KtuT = GlobMatr.KtuT;
    KtfT = GlobMatr.KtfT;
    KtzT = GlobMatr.KtzT;
    FuiT = GlobMatr.FuiT;
    GfiMT =GlobMatr.GfiMT;
    MziT=GlobMatr.MziT;
    Tot_DOF_MEE = length(KffMT(:,1));

%   F_nmk = FueT + M_nmk*Qa1 - FuiT;
    F_nmk = FueT - FuiT;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    K_cm = K_nmk + a0*M_nmk + a1*C_nmk;
    M_cm = a6*M_nmk + a5*C_nmk;
    C_cm = a7*C_nmk - a2*M_nmk;
        
    F2 = F_nmk;
    DQd = K_cm\(F2 - M_cm*Qa1 - C_cm*Qv1);
    DQv = a1*DQd - a3*Qv1 + a5*Qa1;
    DQa = a0*DQd - a2*Qv1 - a4*Qa1;
    Qd1 = Qd1 + DQd;
    Qv1 = Qv1 + DQv;
    Qa1 = Qa1 + DQa;
    Time = Time+TStep; 
    IncremRatio = sqrt(DQd'*DQd/(Qd1'*Qd1));
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    AA=[KffMT,KfzT; KzfT,KzzT];
    BB=[-KfuMT*Qd1-KftT*DeltaT-GfiMT; -KzuT*Qd1-KztT*DeltaT-MziT];
    CC=AA\BB;
    SensM_E = CC(1:Tot_DOF_MEE);
    SensM_M = CC(Tot_DOF_MEE+1:end); 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    X_Time(TimeIndex) = Time;
    Y_Disp(TimeIndex,:) = (Qd1(PositionM))';
    Y_SensM_E(TimeIndex,:) = (SensM_E(PositionMEE))'; 
    Y_SensM_M(TimeIndex,:) = (SensM_M(PositionMEE))';  
    
    fprintf('::Main_DynmNL851T5T56MEEP_Nmk_V4--------------Loops=%d/%d\n', ...
            TimeIndex,Steps);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% output running information to the file
    fid = fopen(Dynm_UsedDataFile,'at');
    if TimeIndex == 2
        fprintf(fid,'=======================================================\n\n');
        fprintf(fid,'Monitoring time steps \n\n');   
        fprintf(fid,'Function: Main_DynmNL851T5T56MEEP_Nmk_V4\n\n'); 
        fprintf(fid,'TheoryStr: %s, IsANS: %d, IntegSchem: %s\n\n', ...
            TheoryStr,IsANS,IntegSchem); 
        fprintf(fid,'TimeParameter: %E, %E, %E\n\n', ...
            TimePara(1),TimePara(2),TimePara(3)); 
        fprintf(fid,'-------------------------------------------------------\n\n');  
    end
    fprintf(fid,'TimeIndex = %d/%d, IncremRatio = %E\n',TimeIndex,Steps,IncremRatio);
    fclose(fid);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end
XY_Value = struct('X_Time',X_Time,'Y_Disp',Y_Disp, ...
    'Y_SensM_E',Y_SensM_E,'Y_SensM_M',Y_SensM_M);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end











