%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Main_StaticNL851T5T56MFC_NR_V41()  %% Newton Raphson
% Main function for computing Nonlinear dynamic response

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Call this Main Function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [XY_Value,QFdva] = Main_StaticNL851T5T56MEEP_NR_V41(InputFile, ...
    UsedDataFile_NL,PositionM,PositionMEE,FueT,PhiaMT,MgaT,DeltaT,...
QFdva,IsANS,Theory,ErrorMax,Lamda,IntegSchem,ThermalNL)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% ElemType = [Node/Elem DOF/Node NumSmtLay DOF/SmtLay NumLay]

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
%% Get the whole thickness
[Totalthickness] = SF_Totalthickness(FinitElemInfo,Material,MateProp);
%% Get displacement in configuration 1
%%%%%%%%%%%%%%%%%%%%%%%%
Qd1 = QFdva.Qd;
Qv1 = QFdva.Qv;
Qa1 = QFdva.Qa;
PhiaM1 = QFdva.PhiaM;
PhisM1 = QFdva.PhisM;
Mga1 = QFdva.Mga;
Mgs1= QFdva.Mgs;
%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initiate time vector X_value and displacement vector Y_value
DOF_NumM = length(PositionM);
DOF_NumMEE = length(PositionMEE);
Y_SensM_E = zeros(DOF_NumMEE,1);
Y_SensM_M = zeros(DOF_NumMEE,1);
Y_Disp = zeros(DOF_NumM,1);

Y_Disp(:,1) = Qd1(PositionM);
Y_SensM_E(:,1) = PhisM1(PositionMEE);
Y_SensM_M(:,1) = Mgs1(PositionMEE);  

Y_ErrorRatio(1,1) = 0;
%%% maximum steps
IterationMax = 50;  
%%% LoadIndex
LoadIndex = 1;
StopFlag = 1;
TotalLoops = length(Lamda);

while LoadIndex <= TotalLoops && StopFlag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ErrorRatio = 1;
IterationIndex = 1;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% %%%%%%%%%%%%%
MuuT = GlobMatr.MuuT;
CuuT = GlobMatr.CuuT;
KuuT = GlobMatr.KuuT;
KufMT = GlobMatr.KufMT;
KfuMT = GlobMatr.KfuMT;
KffMT = GlobMatr.KffMT;

    KutT = GlobMatr.KutT;%hzt+
    KftT = GlobMatr.KftT;
    KztT = GlobMatr.KztT;
    KtuT = GlobMatr.KtuT;
    KtfT = GlobMatr.KtfT;
    KtzT = GlobMatr.KtzT;


KuzT= GlobMatr.KuzT;
KzuT= GlobMatr.KzuT;
KfzT= GlobMatr.KfzT;
KzfT= GlobMatr.KzfT;
KzzT= GlobMatr.KzzT;
FuiT = GlobMatr.FuiT;
GfiMT =GlobMatr.GfiMT;
MziT=GlobMatr.MziT;
Tot_DOF_MEE = length(KffMT(:,1));
    %% 
DQd = KuuT\(Lamda(LoadIndex)*(FueT-KufMT*PhiaMT-KuzT*MgaT-KutT*DeltaT)-FuiT);
Qd2 = Qd1 + DQd; 
%%%%%%%%%%%%%%%%%   
Element = FinitElemInfo.Element;
NumElem = length(Element(:,1)); 
AA=[KffMT,KfzT; KzfT,KzzT];
BB=[-KfuMT*Qd2-KftT*DeltaT-GfiMT; -KzuT*Qd2-KztT*DeltaT-MziT];
CC=AA\BB;
    SensM_E = CC(1:Tot_DOF_MEE);
    SensM_M = CC(Tot_DOF_MEE+1:end);    
%%% check whether KffMT is a 0 matrix
%     if sum(sum(KffMT.*KffMT)) == 0
%         PhisM2 = PhisM1;
%     else
%         PhisM2 = PhisM1 +SensM_E;
%     end
%     %%%
%      %%% check whether KzzT is a 0 matrix
%     if sum(sum(KzzT.*KzzT)) == 0
%         Mgs2 = Mgs1;
%     else
%         Mgs2 = Mgs1 +SensM_M;
%     end
 %%%%%%%%%%%%%
    if DQd'*DQd == 0
        ErrorRatio = 0;
    else
        ErrorRatio = (DQd'*DQd)/(Qd2'*Qd2);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %PhisM1 = PhisM2;
    %Mgs1= Mgs2;
    Qd1 = Qd2; 
    
    fprintf('ErrorRatio = %E\n',ErrorRatio);
    fprintf('::Main_StaticNL851T5T56MEEP_NR_V41-----Loops=%d/%d\n', ...
              IterationIndex,IterationMax);
    IterationIndex = IterationIndex+1;
end

%% exact solution
Y_Disp(:,LoadIndex) = Qd1(PositionM); 
Y_SensM_E(:,LoadIndex) = SensM_E(PositionMEE);
Y_SensM_M(:,LoadIndex) = SensM_M(PositionMEE);             
X_Lamda = Lamda;
Y_ErrorRatio(1,LoadIndex+1) = ErrorRatio;

%% check Iteration access to maximun value
if IterationIndex >= IterationMax
    StopFlag = 1;
    fprintf('Iteration acceed!!!!!\n');
end

%% print loops
fprintf('LoadIndex = %d/%d\n',LoadIndex,TotalLoops);
fprintf('Lamda = %f, ErrorRatio = %E\n',Lamda(LoadIndex),ErrorRatio);

%% save to monitoring file
fid = fopen(UsedDataFile_NL,'at');
if LoadIndex ==1
    fprintf(fid,'=======================================================\n\n');   
    fprintf(fid,'Monitoring load steps and iterations\n\n');   
    fprintf(fid,'Function: Main_StaticNL851T5T56MEEP_NR_V41\n\n'); 
    fprintf(fid,'TheoryStr: %s, IsANS: %d, IntegSchem: %s\n\n', ...
            TheoryStr,IsANS,IntegSchem); 
    fprintf(fid,'-------------------------------------------------------\n\n'); 
end
fprintf(fid,'LoadIndex = %d/%d,Iterations = %d, ',LoadIndex,TotalLoops, ...
        IterationIndex);
fprintf(fid,'Lamda = %f, ErrorRatio = %E\n\n',Lamda(LoadIndex),ErrorRatio);

fclose(fid);


%% for next interation
LoadIndex = LoadIndex + 1;

end
QFdva = struct('Qd',Qd1,'Qv',Qv,'Qa',Qa,'PhiaM',PhiaM,'Mga',Mga, ...
'PhisM',PhisM1,'Mgs',Mgs1);
%% Save data
XY_Value = struct('Y_Disp',Y_Disp,'Y_SensM_E',Y_SensM_E,'Y_SensM_M',Y_SensM_M,'X_Lamda',X_Lamda, ...
                  'Y_ErrorRatio',Y_ErrorRatio);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end











