%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Subfuntion SF_ModesAnalysis
%Computing the modes and corresponding shap vector
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [EigenVector,EigenValue]=SF_ModesAnalysis(DispMode,GlobMatr, ...
                                                   FinitElemInfo)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ElemType = FinitElemInfo.ElemType;
Node = FinitElemInfo.Node;

DOFPerNodeM=ElemType(2);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Solve Modes
%We have to know the matrices of MeT,KuuT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
M = GlobMatr.MuuT;
K = GlobMatr.KuuT;
KufPT = GlobMatr.KufPT;
KufMT = GlobMatr.KufMT;
KuzT=GlobMatr.KuzT;
KfuPT = KufPT';
KfuMT = KufMT';
KzuT = KuzT';

%cholesky decomposition
L = chol(K,'lower');
H = pinv(L)*M*(pinv(L)');
%Solution of eigenvalue and eigenvector
[EigenVector,EigenValue]=eig(H);

%
EigenVector = pinv(L')*EigenVector;

% XTemp=Node(:,2);
% YTemp=Node(:,3);
% i=1;
% while(~isempty(XTemp)||~isempty(YTemp))    %Matrix is not empty
%     if ~isempty(XTemp)
%         X(i)=min(XTemp);
%         XTemp(find(XTemp==X(i)))=[];        
%     end
%     if ~isempty(YTemp)
%         Y(i)=min(YTemp);
%         YTemp(find(YTemp==Y(i)))=[];        
%     end
%     i=i+1;
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Mesh(X,Y Z),[X(j),Y(i),Z(i,j)]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Wdisplacement=zeros(length(Y),length(X));
% for i=1:length(Y)
%     for j=2:length(X)
%         NodeIndex=0;
%         for m=1:length(Node(:,1))
%             if X(j)==Node(m,2)&&Y(i)==Node(m,3)
%                 NodeIndex=Node(m,1);
%             end
%         end
%         if NodeIndex~=0
%             if DOFPerNodeM==3
%                 Wdisplacement(i,j)=EigenVector(3*(NodeIndex-3)-2,DispMode); %3dof
%             elseif DOFPerNodeM==5
%                 Wdisplacement(i,j)=EigenVector(5*(NodeIndex-3)-2,DispMode); %5dof
%             end
%         end   
%     end
% end

Eigenfrequency=(1/sqrt(EigenValue(DispMode,DispMode)))/(2*pi);
fprintf('Mode=%d\n',DispMode);
fprintf('Eigenfrequency=%f Hz\n',Eigenfrequency);
% surf(X,Y,Wdisplacement);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end   %end of the function
