%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Subfuntion SF_GetMatePropMFC()
%Get material properties and its matrices
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [MateProp]=SF_GetMatePropMEEP(Material,FinitElemInfo)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Number of electric dof per layer
ElemType = FinitElemInfo.ElemType;
           % Electric dof per layer 
NumMEELay = ElemType(5);                 % Number of MEE layer
DOFPerMEELay = ElemType(4);             % MEE dof per layer 
 % Number of electric dof per layer
DOFPerElemMEE = NumMEELay*DOFPerMEELay;  % Number of MEE dof per element
NumLay = ElemType(3);         % Total number of layer
MateProp = cell(NumLay,1);       % Store material parameters layer by layer
NumPara = 5;                    % Stress Strain number
% NumLayT = NumLay;
% DOFPerTLay = 1;
% DOFPerElemT = NumLayT*DOFPerTLay;   % Temperature DOF per element
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 MEELayIndex = 1;
for i = 1:NumLay
    %% Initial matrices C,e,g,q,k,r
          C = zeros(NumPara,NumPara); % 弹性矩阵
         eM = zeros(DOFPerElemMEE,NumPara); %压电常数
         gM = zeros(DOFPerElemMEE,DOFPerElemMEE); %介电常数
        q=zeros(DOFPerElemMEE,NumPara);    %压磁常数
        k=zeros(DOFPerElemMEE,DOFPerElemMEE);   %磁电耦合系数
        r=zeros(DOFPerElemMEE,DOFPerElemMEE);  %磁导率
        Alphat = zeros(NumPara,1);%5x1 %热膨胀系数
        Lamdat = zeros(DOFPerElemMEE,NumPara);   %热应力
        p = zeros(DOFPerElemMEE,DOFPerElemMEE);  %热释电
        t = zeros(DOFPerElemMEE,DOFPerElemMEE);  %热磁
        c = zeros(DOFPerElemMEE,DOFPerElemMEE);  %热容
    %%% Get material information of the current layer
    MatCurrLayer = Material(i,:);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     LayIndex = MatCurrLayer(1,1);       % LayerIndex: 
    YoungM1 = MatCurrLayer(1,2);        % YoungM1: Young's Modulus 1
    YoungM2 = MatCurrLayer(1,3);        % YoungM2: Young's Modulus 2
    Poisson12 = MatCurrLayer(1,4);      % Poisson12: Poisson ratio 12
    Poisson23 = MatCurrLayer(1,5);      % Poisson23: Poisson ratio 23
    G12 = MatCurrLayer(1,6);            % G12: shear modulus
    G13 = MatCurrLayer(1,7);            % G13: shear modulus
    G23 = MatCurrLayer(1,8);
   d31 = MatCurrLayer(1,9);            % d31/d11:
    d32 = MatCurrLayer(1,10);            % d32/d12
     PlyAngle = MatCurrLayer(1,11);       % PlyAngle: 
      hE = MatCurrLayer(1,12);            % hE: distance of electrode
    q31 = MatCurrLayer(1,13);            % d31/d11:
    q32 = MatCurrLayer(1,14);           
    g33 = MatCurrLayer(1,15);            
   k33 = MatCurrLayer(1,16);            
   r33 = MatCurrLayer(1,17);
   Alphat1 = MatCurrLayer(1,18); %thermal expansion coefficient
   Alphat2 = MatCurrLayer(1,19);
   PyroE = MatCurrLayer(1,20);   %热释电系数
   PyroM = MatCurrLayer(1,21);   %热磁系数
   c33 = MatCurrLayer(1,22);    %热容
   HC_Current=MatCurrLayer(1,23);  %导热系数
   Density = MatCurrLayer(1,24);
    Lay_zC = MatCurrLayer(1,25:26);  
    IsSmtLay = MatCurrLayer(1,27); 
    %%%%%%%%%%%%%%%%%%%%%%%%%
    Poisson21 = Poisson12*YoungM2/YoungM1;    
  
    %% For isotropic material
    if YoungM1 == YoungM2 && Poisson12 == Poisson23
        G12 = YoungM1/(2*(1+Poisson12));
        G13 = G12;
        G23 = G12;
     end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Contruct C matrix
    C11 = YoungM1/(1-Poisson12*Poisson21);
    C12 = YoungM2*Poisson12/(1-Poisson12*Poisson21);
    C22 = YoungM2/(1-Poisson12*Poisson21);
    x = 5/6;       %correction factor
    %%%%%%%%%%%
    C(1,1) = C11;
    C(1,2) = C12;
    C(2,1) = C12;
    C(2,2) = C22;
    C(3,3) = G12;
    C(4,4) = x*G23;
    C(5,5) = x*G13;
   %% Contruct Lamdat matrix  hzt+
    Alphat(1,1) = Alphat1;
    Alphat(2,1) = Alphat2;
    Lamdat1 = C*Alphat; %5×1  热应力
        Lamdat31 =Lamdat1(1,1);
        Lamdat32 =Lamdat1(2,1);

    %% Construct e , g，q,k,r matrix in material coordinates
   if IsSmtLay == 2 
        d = [d31 d32 0 0 0];
        eTemp = d*C;
        eM(MEELayIndex,:) = eTemp;
%         eM(MEELayIndex,:) = d;
        q1 = [q31 q32 0 0 0];
        q(MEELayIndex,:) =q1;
        gM(MEELayIndex,MEELayIndex) = g33-d31*eM(MEELayIndex,1)-d32*eM(MEELayIndex,1); 
%         gM(MEELayIndex,MEELayIndex) = g33;
        k(MEELayIndex,MEELayIndex)=k33;
        r(MEELayIndex,MEELayIndex)=r33;
       
        p(MEELayIndex,MEELayIndex)=PyroE;
        t(MEELayIndex,MEELayIndex)=PyroM;
        
        Lamdat1 = [Alphat1  Alphat2 0 0 0];
        Lamdat(MEELayIndex,:) =Lamdat1;
        c(MEELayIndex,MEELayIndex)=c33;     
       
        MEELayIndex = MEELayIndex+1;
       
   else  
       
         eM = zeros(DOFPerElemMEE,NumPara);
         gM = zeros(DOFPerElemMEE,DOFPerElemMEE); 
        q=zeros(DOFPerElemMEE,NumPara);    
        k=zeros(DOFPerElemMEE,DOFPerElemMEE);
        r=zeros(DOFPerElemMEE,DOFPerElemMEE);
        Lamdat=zeros(DOFPerElemMEE,NumPara);
        p=zeros(DOFPerElemMEE,DOFPerElemMEE);
        t=zeros(DOFPerElemMEE,DOFPerElemMEE);
        c=zeros(DOFPerElemMEE,DOFPerElemMEE);
   end
    %% Transform material axes to curvilinear coordinates,
    %%% MCTran: Transformation matrix
    %%% PlyAngle: unit, degree
    Theta = PlyAngle/180*pi;
    RT1 = (sin(Theta))^2;
    RT2 = (cos(Theta))^2;
    RT3 = sin(Theta);
    RT4 = cos(Theta);
    RT5 = sin(2*Theta);
  
    MCTran = zeros(5,5);
    MCTran(1,1) = RT2;
    MCTran(1,2) = RT1;
    MCTran(1,3) = 1/2*RT5;
    MCTran(2,1) = RT1;
    MCTran(2,2) = RT2;
    MCTran(2,3) = -1/2*RT5;
    MCTran(3,1) = -RT5;
    MCTran(3,2) = RT5;
    MCTran(3,3) = RT2-RT1;
    MCTran(4,4) = RT4;
    MCTran(4,5) = -RT3;
    MCTran(5,4) = RT3;
    MCTran(5,5) = RT4;    
    %%%%%% 
    C = MCTran'*C*MCTran;
    eM = eM*MCTran; 
    q = q*MCTran;
    Lamdat = Lamdat*MCTran;
    
    MatStru = struct('C',C,'eM', eM, 'gM',gM,'q',q,'k',k,'r',r,'hE', hE,  ...
    'Density',Density,'Lamdat',Lamdat,'PyroE',PyroE,'PyroM',PyroM,'c',c,'c33',c33, ...
       'Lay_zC',Lay_zC,'IsSmtLay',IsSmtLay,'Alphat',Alphat,'HC_Current',HC_Current);            
    %% MateProp: cell varible for all layers            
    MateProp{LayIndex,1} = MatStru;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end
end
