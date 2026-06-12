%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Subfuntion SF_FEMtoSSM
%Transfer Finite element model to state space model
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%[M,C,K,F,S]=SF_FEMtoSSM(MuuT,CuT,KuuT,KufT,KffT,FuT)
%M,C,K,F:Mass matrix,Damping matrix,Stiffness matrix,Force vector
%S:{Q}=[S]{Z}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [M,C,K,F,S]=SF_FEMtoSSM_3(M_F2S,C_F2S,K_F2S,F_F2S)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % %%%%%%%%Specification for calling the subfunction
% % M_F2S=MuuT;
% % C_F2S=CuuT;
% % K_F2S=KuuT;
% % F_F2S=FuT;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
FinalDofM=length(M_F2S(1,:));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Eigenvector and eigenvalue
L=chol(K_F2S,'lower'); %对矩阵进行Cholesky分解
H=L\M_F2S/(L');
%Solution of eigenvalue and eigenvector
[EigenVector,EigenValue]=eig(full(H));

EigenValue = sparse(EigenValue);
S=(L')\EigenVector;         %Mode shapes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%below,OK!!!!
M=S'*M_F2S*S;
C=S'*C_F2S*S;
K=S'*K_F2S*S;
F=S'*F_F2S;

M=sparse(diag(diag(M)));
C=sparse(diag(diag(C)));
K=sparse(diag(diag(K)));

%C=pinv(M)*C;
%K=pinv(M)*K;
%F=pinv(M)*F;
%M=pinv(M)*M;


% for i=1:FinalDofM
%    C(i,i)=C(i,i)/M(i,i);
%    K(i,i)=K(i,i)/M(i,i);
%    F(i)=F(i)/M(i,i);
%    
%    M(i,i)=M(i,i)/M(i,i);
% end

%%%%%%%%%%%%%%%%%%%%

%C=pinv(S)*pinv(M)*pinv(S')*S'*C*S;
%K=pinv(S)*pinv(M)*pinv(S')*S'*K*S;
%F=pinv(S)*pinv(M)*pinv(S')*S'*FuT;
%M=pinv(S)*pinv(M)*pinv(S')*S'*M*S;

% M=S'*M*S;
% C=S'*C*S;
% K=S'*K*S;
% F=S'*FuT;
% 
% M=diag(diag(M));
% C=diag(diag(C));
% K=diag(diag(K));

%C=pinv(M)*C;
%K=pinv(M)*K;
%F=pinv(M)*F;
%M=pinv(M)*M;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end   %end of the function

