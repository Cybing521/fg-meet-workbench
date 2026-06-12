%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Subfuntion SF_GetAnMatr_PLATE()
%Get An matrix, only for PLATE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [An] = SF_GetAnMatr_MRT5(Theta,CurvPara)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
An = zeros(13,15); 

% Theta = Kth*LNu*Qde;

%% Get curvilinear coordinates parameters
a1 = CurvPara.a1;
a2 = CurvPara.a2;
b1 = CurvPara.b1;
b2 = CurvPara.b2;
c1 = CurvPara.c1;
c2 = CurvPara.c2;
t1 = CurvPara.t1;
t2 = CurvPara.t2;

%% An matrix
%%% d_An:
d_An4 = a1*t1 + a2*t2;

%% For An1 matrix:
    
AnTemp = zeros(13,15);
AnTemp(1,[5,11]) = [Theta(5), c1^2*Theta(11)];
AnTemp(2,[6,12]) = [Theta(6), c2^2*Theta(12)];
AnTemp(3,[5,6,11,12]) = [Theta(6), Theta(5), c1*c2*Theta(12), ...
       c1*c2*Theta(11)];
AnTemp(4,[5,14]) = [c1*Theta(14), c1*Theta(5)];
AnTemp(5,[12,15]) = [c2^2*Theta(15), c2^2*Theta(12)];
AnTemp(6,[5,12,14,15]) = [c1*Theta(15), c1*c2*Theta(14), ...
       c1*c2*Theta(12), c2*Theta(5)];
AnTemp(7,14) = c1^2*Theta(14);
AnTemp(8,15) = c2^2*Theta(15);
AnTemp(9,[14,15]) = [c1*c2*Theta(15), c1*c2*Theta(14)];
AnTemp(10,[2,4,14,15]) = [a1*Theta(14), a2*Theta(15), ...
       a1*Theta(2), a2*Theta(4)];
AnTemp(11,[1,3,14,15]) = [a1*Theta(14), a2*Theta(15), a1*Theta(1), ...
       a2*Theta(3)];
AnTemp(12,[8,10,14,15]) = [a1*Theta(14), a2*Theta(15), ...
       a1*Theta(8), a2*Theta(10)];
AnTemp(13,[7,9,14,15]) = [a1*Theta(14), a2*Theta(15), a1*Theta(7), ...
       a2*Theta(9)];
%%%%%%%%%%%%%%%%%%%%%%%%%% Adding An1
An = An + AnTemp;

%% For An2 matrix:
AnTemp = zeros(13,15);
AnTemp(1,[5,11]) = [c1*Theta(11), c1*Theta(5)];
AnTemp(2,[6,12]) = [c2*Theta(12), c2*Theta(6)];
AnTemp(3,[5,6,11,12]) = [c2*Theta(12), c1*Theta(11), c1*Theta(6)...
       c2*Theta(5)];
AnTemp(4,[11,14]) = [c1^2*Theta(14), c1^2*Theta(11)];
AnTemp(5,[6,15]) = [c2*Theta(15), c2*Theta(6)];
AnTemp(6,[6,11,14,15]) = [c1*Theta(14), c1*c2*Theta(15), ...
       c1*Theta(6), c1*c2*Theta(11)];
AnTemp(10,[11,12,14,15]) = [a2*t2*Theta(15), a1*t1*Theta(14), ...
       a1*t1*Theta(12), a2*t2*Theta(11)];
AnTemp(11,[12,13,14,15]) = [a2*t1*Theta(15), -a1*b1*Theta(14), ...
       -a1*b1*Theta(13), a2*t1*Theta(12)];
AnTemp(12,[14,15]) = [d_An4*Theta(15), d_An4*Theta(14)];
AnTemp(13,15) = 2*a2*t1*Theta(15);
%%%%%%%%%%%%%%%%%%%%%%%%%% Adding An2
An = An + AnTemp;

%% For An3 matrix:
AnTemp(10,[13,15]) = [-a2*b2*Theta(15), -a2*b2*Theta(13)];
%%%%%%%%%%%%%%%%%%%%%%%%%% Adding An3
An = An + AnTemp;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

