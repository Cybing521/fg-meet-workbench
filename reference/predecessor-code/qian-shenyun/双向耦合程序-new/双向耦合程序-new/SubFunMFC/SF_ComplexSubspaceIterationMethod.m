%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [Frequency] = SF_ComplexSubspaceIterationMethod(GlobMatr,FreqOrder)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Freq = zeros(FreqOrder,2);
Npair = FreqOrder;  
%%  复子空间迭代法 1 
    M = GlobMatr.MuuT;
    K = GlobMatr.KuuT;
%     KufT = GlobMatr.KufT;
%     KfuT = KufT';
    
miu = 0;
K=K+miu*M;       %%%%%%迁移子空间
% m = min(2*Npair,Npair+8);
m=Npair;
n=length(K);
u1=2*rand(n,m)+2*sqrt(-1)*rand(n,m);   %随机生成复数初始迭代值；
er=zeros(m,m);
for i=1:m 
    er(i,i)=miu; 
end

k=0;
while(1)
    k=k+1;  
    u1=K\(M*u1);
    for i=1:m
        s=max(abs(u1(:,i)));
        u1(:,i)=u1(:,i)/s;  
    end
%     Km=transpose(u1)*K*u1;
%     Mm=transpose(u1)*M*u1;%%%%%%%%%%%%MATLAB中a.'是转置，a'是共轭转置%%%%%%
    Km=(u1)'*K*u1;
    Mm=(u1)'*M*u1;%%%%%%%%%%%%MATLAB中a.'是转置，a'是共轭转置%%%%%%
    [A,ev]=eig(Km,Mm);
    for i=1:m
        s=max(abs(A(:,i)));
        A(:,i)=A(:,i)/s;
    end
    u=u1*A;
    dv=diag(ev);
    %%排序%特征值与特征向量排序与否不影响结果
    Temp1=[dv u.'];
    Temp2=sortrows(Temp1);
    dv=Temp2(1:m,1);
    u=Temp2(1:m,2:n+1).';
    for i=1:m ev(i,i)=dv(i); end
    e=ev-er;
    er=ev;
    aa=diag(e(1:Npair,1:Npair));
    bb=diag(ev(1:Npair,1:Npair));
    Eps = max(abs(aa./bb));
    if (Eps<1.0e-3)
        break;
    else
        u1=u;
    end
end
ev=diag(ev)-miu;
FV=[ev u.'];
FVec=sortrows(FV);
EigenValue=FVec(1:Npair,1);%%%特征值的倒数1 /Lambda
EigenVector=FVec(1:Npair,2:n+1).';%%%特征向量
%%  复子空间迭代法 GYS

% m = Npair;
% n = length(K);
% X0 = 2*rand(n,m)*(1 + 1i);
% D0i = eye(m);
% Z0 = K*X0;
% while(1)
%     U0 = K*X0;
%     W0 = M*X0;
%     Kp = X0'*K*X0;
%     Mp = X0'*M*X0;
%     [V0,D0] = eig(Kp,Mp);
%     Temp = sortrows([diag(D0),(X0*V0)']);
%     D0 = diag(Temp(1:m,1));
%     Vec = Temp(1:m,2:n+1)';
%     D0i = D0 - D0i;
%     aa=diag(D0i(1:Npair,1:Npair));
%     bb=diag(D0(1:Npair,1:Npair));
%     Eps = max(abs(aa./bb));
%     if (Eps<1.0e-3)
%         break;
%     else
%         Z0 = (Z0 - U0)*V0 - W0*V0*D0;
%         X0 = K\Z0;
%         for i=1:m
%             s = max(abs(X0(:,i)));
%             X0(:,i) = X0(:,i)/s;
%         end
%         D0i = D0;
%     end
%     Eig = diag(D0);
% end

%%
for i = 1:Npair
% OmegaSquareM(i,2) = Eig(i,end);
Imag = abs(imag(EigenValue(i,end)));
Real = real(EigenValue(i,end));
Freq(i,2) = [real(sqrt(Real)/(2*pi))];
end
%%
OmegaSquare = real(EigenValue(i,end));
Frequency = struct('Freq',Freq,'EigenValue',EigenValue,'EigenVector',EigenVector,'OmegaSquare',OmegaSquare);
end







