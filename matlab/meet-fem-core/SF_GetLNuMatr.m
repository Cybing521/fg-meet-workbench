%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Subfuntion SF_GetLNuMatr()
%Calculate Muu,Kuu,Kuf,Kff for one element
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



function [Nt] = SF_GetLNuMatr(xL,yL,a,b,DOFPerNodeM)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% shape function
N(1)=1/4*(1-xL)*(1-yL)*(-xL-yL-1);
N(2)=1/4*(1+xL)*(1-yL)*(xL-yL-1);
N(3)=1/4*(1+xL)*(1+yL)*(xL+yL-1);
N(4)=1/4*(1-xL)*(1+yL)*(-xL+yL-1);
N(5)=1/2*(1-xL^2)*(1-yL);
N(6)=1/2*(1-yL^2)*(1+xL);
N(7)=1/2*(1-xL^2)*(1+yL);
N(8)=1/2*(1-yL^2)*(1-xL);
%%% Derivative of shape function
DN(1,1) = 1/(4*a)*(1-yL)*(2*xL+yL);
DN(1,2) = 1/(4*b)*(1-xL)*(xL+2*yL);
DN(2,1) = 1/(4*a)*(1-yL)*(2*xL-yL);
DN(2,2) = 1/(4*b)*(1+xL)*(-xL+2*yL);
DN(3,1) = 1/(4*a)*(1+yL)*(2*xL+yL);
DN(3,2) = 1/(4*b)*(1+xL)*(xL+2*yL);
DN(4,1) = 1/(4*a)*(1+yL)*(2*xL-yL);
DN(4,2) = 1/(4*b)*(1-xL)*(-xL+2*yL);
DN(5,1) = -1/(a)*xL*(1-yL);
DN(5,2) = -1/(2*b)*(1-xL^2);
DN(6,1) = 1/(2*a)*(1-yL^2);
DN(6,2) = -1/(b)*(1+xL)*yL;
DN(7,1) = -1/(a)*xL*(1+yL);
DN(7,2) = 1/(2*b)*(1-xL^2);
DN(8,1) = -1/(2*a)*(1-yL^2);
DN(8,2) = -1/(b)*(1-xL)*yL;

%% Nu matrix
IM = eye(DOFPerNodeM,DOFPerNodeM);              %IM(5,5)
Nu = [N(1)*IM, N(2)*IM, N(3)*IM, N(4)*IM, ...
      N(5)*IM, N(6)*IM, N(7)*IM, N(8)*IM];

%% Nt matrix, Nt = Lu*Nu for theta
IM = eye(DOFPerNodeM,DOFPerNodeM); 
LNuTemp = [DN(1,1)*IM,DN(2,1)*IM,DN(3,1)*IM,DN(4,1)*IM, ...
           DN(5,1)*IM,DN(6,1)*IM,DN(7,1)*IM,DN(8,1)*IM ];
%%%
Nt([1,3,5,7,9],:) = LNuTemp;

%%%
LNuTemp = [DN(1,2)*IM,DN(2,2)*IM,DN(3,2)*IM,DN(4,2)*IM, ...
           DN(5,2)*IM,DN(6,2)*IM,DN(7,2)*IM,DN(8,2)*IM ];
%%%
Nt([2,4,6,8,10],:) = LNuTemp;
%%%

Nt([11,12,13,14,15],:) = Nu;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

