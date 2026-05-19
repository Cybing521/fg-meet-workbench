%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Main_StaticNL851T5T56MFC_RWR_V4()  %% Newton Raphson
% Main function for computing Nonlinear dynamic response

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Call this Main Function



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [XY_Value,QFdva] = Main_StaticNL851T5T56MEEP_RWR_NLFreq_V4(InputFile, ...
    UsedDataFile_NL,PositionM,PositionMEE,FueT,PhiaMT,MgaT,QFdva, ...
    IsANS,Theory,ErrorMax,DLamda0,IsConstantArc,IntegSchem)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% ElemType = [Node/Elem DOF/Node NumSmtLay DOF/SmtLay NumLay]
%%% DLamda0 should avloid to be 0
%%% FueT: total external force
%%% PhiaT: total voltage applied on actuator

%% check theory, string to integer
[TheoryInt,TheoryStr] = SF_TheoryNotation(Theory);

%% Get data from input file
%%% FinitElemInfo: ElemType,Element,Node
%%% Material: Material parameters for every layer

[FinitElemInfo,Material] = SF_GetInputDataMEEP(InputFile);
[ERROR] = SF_InputFileCheckMEEP(FinitElemInfo,Material);
%%% ERROR: 0, input correct; 1-10, input has mistaks;
if ERROR ~=0
    return
end

%%% TheoryInt
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
NumLay = ElemType(3);


%% Output the data that was use during calculation
SF_GetUsedData(UsedDataFile_NL,FinitElemInfo,Material,MateProp);

%% Get displacement in configuration 1
%%%%%%%%%%%%%%%%%%%%%%%%
Qd1 = QFdva.Qd;
Qv1 = QFdva.Qv;
Qa1 = QFdva.Qa;
PhiaM1 = QFdva.PhiaM;
PhisM1 = QFdva.PhisM;
Mga1 = QFdva.Mga;
Mgs1= QFdva.Mgs;
Qd0 = QFdva.Qd;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initiate time vector X_value and displacement vector Y_value
DOF_NumM = length(PositionM);

DOF_NumMEE = length(PositionMEE);

X_Lamda = zeros(1,1);
Y_Disp = zeros(DOF_NumM,1);
Y_SensM_E = zeros(DOF_NumMEE,1);
Y_SensM_M = zeros(DOF_NumMEE,1);

X_Lamda(1,1) = 0;
Y_Disp(:,1) = Qd1(PositionM,1);
Y_SensM_E(:,1) = PhisM1(PositionMEE,1);
Y_SensM_M(:,1) = Mgs1(PositionMEE,1);    

Y_ErrorRatio(1,1) = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
IterationMax = 1000;       %% maximum steps
Lamda0 = 0;

%%%%%%%%%%%%%%%%%%%%%%%%
%%% total loops
if DLamda0'*DLamda0 == 0
	TotalLoops = 0;
else
    TotalLoops = round(1/DLamda0');
end
%%% maximun load steps
if TotalLoops > 200
    LoadSptepMax = TotalLoops;
else
    LoadSptepMax = 200;
end

%%% LoadIndex
LoadIndex = 1;
StopFlag = 1;

while Lamda0 < 1 && Lamda0 >= -1 && StopFlag && LoadIndex < LoadSptepMax*3
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ErrorRatio = 1;
IterationIndex = 1;   

% Lamda0 = 
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
while IterationIndex < IterationMax && ErrorRatio > ErrorMax
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Qd = Qd1;
    Qv = Qv1;
    Qa = Qa1;
    PhiaM = PhiaM1; 
    PhisM = PhisM1;
    Mga= Mga1;
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
                    [ElemMatr]=SF_ElemComptNL851T5MEEP_V4(EleIndex, ...
                           MatePropCurrLay,FinitElemInfo,TQFdva,IntegSchem);
                elseif IsANS == 1

                end 
            case 4 %%% LRT56
                if IsANS == 0
                    [ElemMatr]=SF_ElemComptNL851T56MEEP_V4(EleIndex, ...
                           MatePropCurrLay,FinitElemInfo,TQFdva,IntegSchem);
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
   
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% %%%%%%%%%%%%%
KuuT1 = GlobMatr.KuuT;  
KufMT1 = GlobMatr.KufMT;
KfuMT1 = GlobMatr.KfuMT;
KffMT1 = GlobMatr.KffMT;
KffMT = GlobMatr.KffMT;
KuzT1= GlobMatr.KuzT;
KzuT1= GlobMatr.KzuT;
KfzT1= GlobMatr.KfzT;
KzfT1= GlobMatr.KzfT;
KzzT1= GlobMatr.KzzT;
FuiT1 = GlobMatr.FuiT;
GfiMT1 =GlobMatr.GfiMT;
MziT1=GlobMatr.MziT;
Tot_DOF_MEE = length(KffMT(:,1));
    

    %%% first calculation
    if IterationIndex == 1
        KuuT0 = KuuT1;
        KufMT0 = KufMT1;  %%´Åµç
        KuzT0=KuzT1;       %%´Å
        FuiT0 = FuiT1;
        
        DQd0 = KuuT0\(DLamda0*FueT-DLamda0*KufMT0*PhiaMT-DLamda0*KuzT0*MgaT);
        Lamda1 = Lamda0 + DLamda0;
        Qd1 = Qd0 + DQd0;
        %%% for sensor calculation
        DQd1 = DQd0;
        S0 = sqrt(DLamda0^2+DQd0'*DQd0);
        
        if DLamda0'*DLamda0 == 0
            ErrorRatio = 0;
        end
    else
        FR1 = KuuT0*DQd0 + FuiT0 - FuiT1;

        DQd1_1 = KuuT1\(FueT - KufMT1*PhiaMT - KuzT1*Mga);
        DQd1_2 = KuuT1\FR1;
        
        if IterationIndex == 2
            DLamda1 = DQd0'*DQd1_2/(DQd0'*DQd1_1+DLamda0);
        elseif IterationIndex > 2
            DLamda1 = DQd0_1'*DQd1_2/(DQd0_1'*DQd1_1+1);
        end
        
        DQd1 = DQd1_2 - DLamda1*DQd1_1;
        Qd2 = Qd1 + DQd1;
        Lamda2 = Lamda1 - DLamda1;
        
        ErrorRatio = sqrt((DQd1'*DQd1)/(Qd2'*Qd2));

        %%% update Qd1, Lamda1, system matrices
        KuuT0 = KuuT1;
        FuiT0 = FuiT1;
        
        DQd0 = DQd1;
        DQd0_1 = DQd1_1;
        Qd1 = Qd2;
        Lamda1 = Lamda2;
    end 
    
    %% Calculate sensor voltages
    %%% check whether KffT is a 0 matrix
    if sum(sum(KffMT1.*KffMT1)) == 0
        PhisM2 = PhisM1;
    elseif sum(sum(KzzT1.*KzzT1)) == 0   
        Mgs2=Mgs1;    
    else
    AA=[KffMT1,KfzT1; KzfT1,KzzT1];
    BB=[-KfuMT1*DQd1-GfiMT1; -KzuT1*DQd1-MziT1];
    CC=AA\BB;
    PhisM2 = CC(1:Tot_DOF_MEE);
    Mgs2 = CC(Tot_DOF_MEE+1:end);    
    end
    %%%
    PhisM1 = PhisM2;
    Mgs1=Mgs2;  
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    fprintf('::ErrorRatio = %E\n',ErrorRatio);
    fprintf('::Main_StaticNL851T5T56MEEP_RWR_V4-----Loops=%d/%d\n', ...
            IterationIndex,IterationMax);
    IterationIndex = IterationIndex+1;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
if IterationIndex >= IterationMax
    StopFlag = 1;
    fprintf('Iteration acceed!!!!!\n');
end

%% print loops
fprintf('LoadIndex = %d/%d\n',LoadIndex,TotalLoops);
fprintf('Lamda = %f, ErrorRatio = %E\n',Lamda1,ErrorRatio);

%% exact solution
Y_Disp(:,LoadIndex+1) = Qd1(PositionM); 
Y_SensM_E(:,LoadIndex+1) = PhisM1(PositionMEE); 
Y_SensM_M(:,LoadIndex+1) = Mgs1(PositionMEE); 
X_Lamda(1,LoadIndex+1) = Lamda1;
Y_ErrorRatio(1,LoadIndex+1) = ErrorRatio;
%%%%%%%%%%%%%%%%%%%%%%%%%%
for FreqOrder = 1:12
    [Frequency] = SF_ComplexSubspaceIterationMethod(GlobMatr,FreqOrder);
    Frequency = Frequency.Freq;
    Freq_NL(LoadIndex+1,FreqOrder) = Frequency(FreqOrder,2);
end

%% for next interation
KuuT0 = KuuT1;
FuiT0 = FuiT1;

detKuu = det(KuuT0);
%%% Arc length for next interation
if IsConstantArc == 1
   S1 = S0; 
else
   S1 = S0*sqrt(20/IterationIndex); 
end

%%% determine the sign of S1
if detKuu < 0      %% Lamda goes down
    S1 = -1*S1;
end

% DLamdaTemp = S1/sqrt(1+DQd1_1'*DQd1_1);
% if abs(DLamdaTemp) > 10*DLamda0_first
%     DLamda0 = 10*DLamda0_first*sign(DLamdaTemp);
% else
%     DLamda0 = DLamdaTemp;
% end

DLamda0 = S1/sqrt(1+DQd1_1'*DQd1_1);
Lamda0 = Lamda1;
Qd0 = Qd1;


%% save to monitoring file
fid = fopen(UsedDataFile_NL,'at');
if LoadIndex ==1
    fprintf(fid,'=======================================================\n\n');   
    fprintf(fid,'Monitoring load steps and iterations\n\n');  
    fprintf(fid,'Function: Main_StaticNL851T5T56MEEP_RWR_V4\n\n'); 
    fprintf(fid,'TheoryStr: %s, IsANS: %d, IntegSchem: %s\n\n', ...
            TheoryStr,IsANS,IntegSchem); 
    fprintf(fid,'-------------------------------------------------------\n\n'); 
end
fprintf(fid,'LoadIndex = %d/%d, Iterations = %d, ',LoadIndex,TotalLoops, ...
        IterationIndex);
fprintf(fid,'Lamda = %f, ErrorRatio = %E, ',Lamda1,ErrorRatio);
fprintf(fid,'detKuu = %f, S1 = %E, DLamda0 = %E\n\n',detKuu,S1,DLamda0);
fclose(fid);

%%
LoadIndex = LoadIndex+1;

end


QFdva = struct('Qd',Qd1,'Qv',Qv,'Qa',Qa,'PhiaM',PhiaM,'PhisM',PhisM1,'Mgs',Mgs1);


%% Save data
XY_Value = struct('Y_Disp',Y_Disp,'X_Lamda',X_Lamda, ...
                 'Y_SensM_E',Y_SensM_E,'Y_SensM_M',Y_SensM_M, 'Y_ErrorRatio',Y_ErrorRatio,...
                 'Freq_NL',Freq_NL,'Frequency',Frequency);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end










