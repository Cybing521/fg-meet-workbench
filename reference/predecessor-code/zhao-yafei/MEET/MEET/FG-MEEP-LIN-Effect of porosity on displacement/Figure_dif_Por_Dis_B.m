clc;
clear;
format long 
% CaseName = HCcat('./CurrentComp');
% FileNameRes = HCcat(CaseName, '.mat');
% UsedDataFile_NL = HCcat(CaseName, '.txt');
% %FigureName = HCcat(CaseName, '.fig');
load('./CurrentComp/SSSS_U_index_02_P_0_HCLRT56_G2.mat')
load('./CurrentComp/SSSS_U_index_02_P_01_HCLRT56_G2.mat')
load('./CurrentComp/SSSS_U_index_02_P_02_HCLRT56_G2.mat')
load('./CurrentComp/SSSS_U_index_02_P_03_HCLRT56_G2.mat')
load('./CurrentComp/SSSS_U_index_02_P_04_HCLRT56_G2.mat')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
load('./CurrentComp/SSSS_V_index_02_P_0_HCLRT56_G2.mat')
load('./CurrentComp/SSSS_V_index_02_P_01_HCLRT56_G2.mat')
load('./CurrentComp/SSSS_V_index_02_P_02_HCLRT56_G2.mat')
load('./CurrentComp/SSSS_V_index_02_P_03_HCLRT56_G2.mat')
load('./CurrentComp/SSSS_V_index_02_P_04_HCLRT56_G2.mat')
%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%
load('./CurrentComp/SSSS_O_index_02_P_0_HCLRT56_G2.mat')
load('./CurrentComp/SSSS_O_index_02_P_01_HCLRT56_G2.mat')
load('./CurrentComp/SSSS_O_index_02_P_02_HCLRT56_G2.mat')
load('./CurrentComp/SSSS_O_index_02_P_03_HCLRT56_G2.mat')
load('./CurrentComp/SSSS_O_index_02_P_04_HCLRT56_G2.mat')
%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%
load('./CurrentComp/SSSS_X_index_02_P_0_HCLRT56_G2.mat')
load('./CurrentComp/SSSS_X_index_02_P_01_HCLRT56_G2.mat')
load('./CurrentComp/SSSS_X_index_02_P_02_HCLRT56_G2.mat')
load('./CurrentComp/SSSS_X_index_02_P_03_HCLRT56_G2.mat')
load('./CurrentComp/SSSS_X_index_02_P_04_HCLRT56_G2.mat')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%
%% 
X_Disp = 0:0.1:0.4;
Y_Disp_V1_DF1_NL = [SSSS_U_index_02_P_0_HC,SSSS_U_index_02_P_01_HC,...
                SSSS_U_index_02_P_02_HC,SSSS_U_index_02_P_03_HC,...
                SSSS_U_index_02_P_04_HC];
Y_Disp_V1_DF2_NL = [SSSS_V_index_02_P_0_HC,SSSS_V_index_02_P_01_HC,...
                SSSS_V_index_02_P_02_HC,SSSS_V_index_02_P_03_HC,...
                SSSS_V_index_02_P_04_HC];
Y_Disp_V1_DF3_NL = [SSSS_O_index_02_P_0_HC,SSSS_O_index_02_P_01_HC,...
                SSSS_O_index_02_P_02_HC,SSSS_O_index_02_P_03_HC,...
                SSSS_O_index_02_P_04_HC];
Y_Disp_V1_DF4_NL = [SSSS_X_index_02_P_0_HC,SSSS_X_index_02_P_01_HC,...
                SSSS_X_index_02_P_02_HC,SSSS_X_index_02_P_03_HC,...
                SSSS_X_index_02_P_04_HC];                   
%% plot
hfig = figure;
plot(X_Disp,Y_Disp_V1_DF1_NL,'-sm',X_Disp,Y_Disp_V1_DF2_NL,'-*b',...
    X_Disp,Y_Disp_V1_DF3_NL,'-g',X_Disp,Y_Disp_V1_DF4_NL,'-dk','LineWidth',0.5);
xlabel('Porosity');
ylabel('Displacements (m)');
legend('B-bottem, FG-U','B-bottem, FG-V','B-bottem, FG-O','B-bottem, FG-X');
grid on;
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%saveas(hfig,FigureName);
% % save(FileNameRes,'RunPara','XY_Value','LoadNL','frequency','Qd','frequency_02_2_02_SSSS_1layer_V1_DF4_0');
