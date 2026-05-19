%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Subfuntion SF_GetAnMatr_LRT5()
%Get An matrix, only for PLATE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [An] = SF_GetAnMatr_LRT5(Theta,CurvPara)
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
%%% d_An: d1-d9
d_An = zeros(1,4);
d_An(1) = a1*t1^2+c2^2;
d_An(2) = -(a1*t1*b1 + a2*b2*t1);
d_An(3) = a2*t1*t2 + c1*c2;
d_An(4) = a1*t1 + a2*t2;

%% For An1 matrix:
    
AnTemp = zeros(13,15);
AnTemp(1,[1,3,5,11,12,13]) = [a1*Theta(1), a2*Theta(3), Theta(5), ...
       c1^2*Theta(11), a2*t1^2*Theta(12), a1*b2^2*Theta(13)];
AnTemp(2,[2,4,6,11,12,13]) = [a1*Theta(2), a2*Theta(4), Theta(6), ...
       a2*t2^2*Theta(11), d_An(1)*Theta(12), a2*b2^2*Theta(13)];
AnTemp(3,[1,2,3,4,5,6,12,13]) = [a1*Theta(2), a1*Theta(1), ... 
       a2*Theta(4), a2*Theta(3), Theta(6), Theta(5), ...
       d_An(2)*Theta(13), d_An(2)*Theta(12)];
AnTemp(4,[1,3,5,7,9,12,14,15]) = [a1*Theta(7), a2*Theta(9), ...
       c1*Theta(14),a1*Theta(1),a2*Theta(3), a2*t1^2*Theta(15), ...
       c1*Theta(5), a2*t1^2*Theta(12)];
AnTemp(5,[2,4,8,10,11,12,14,15]) = [a1*Theta(8), a2*Theta(10), ...
       a1*Theta(2), a2*Theta(4), a2*t2^2*Theta(14), ...
       d_An(1)*Theta(15) a2*t2^2*Theta(11), d_An(1)*Theta(12)];
AnTemp(6,[1,2,3,7,8,9,10,11,12,13,14,15]) = [a1*Theta(8), ...
       a1*Theta(7), a2*Theta(10), a1*Theta(2), a1*Theta(1), ...
       a2*t2*Theta(11), a2*Theta(3), a2*t2*Theta(9), d_An(3)*Theta(14), ...
       -a1*b1*t1*Theta(15), d_An(3)*Theta(12), -a1*b1*t1*Theta(13)];
AnTemp(7,[7,9,14,15]) = [a1*Theta(7), a2*Theta(9), c1^2*Theta(14), ...
       a2*t1^2*Theta(15)];
AnTemp(8,[8,10,14,15]) = [a1*Theta(8), a2*Theta(10), ...
       a2*t2^2*Theta(14), d_An(1)*Theta(15)];
AnTemp(9,[7,8,9,10,14,15]) = [a1*Theta(8), a1*Theta(7), ...
       a2*Theta(10), a2*Theta(9), d_An(3)*Theta(15), d_An(3)*Theta(14)];
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
AnTemp(1,[1,3,5,11,12,13]) = [-a1*b1*Theta(13), a2*t1*Theta(12), ...
       c1*Theta(11), c1*Theta(5), a2*t1*Theta(3), -a1*b1*Theta(1)];
AnTemp(2,[2,4,11,12]) = [a1*t1*Theta(12), a2*t2*Theta(11), ...
       a2*t2*Theta(4), a1*t1*Theta(2)];
AnTemp(3,[1,2,3,11,12,13]) = [a1*t1*Theta(12), -a1*b1*Theta(13), ...
       a2*t2*Theta(11), a2*t2*Theta(3), a1*t1*Theta(1), -a1*b1*Theta(2)];
AnTemp(4,[3,7,9,11,12,13,14,15]) = [a2*t1*Theta(15), ...
       -a1*b1*Theta(13), a2*t1*Theta(12), c1^2*Theta(14), ...
       a2*t1*Theta(9), -a1*b1*Theta(7), c1^2*Theta(11), a2*t1*Theta(3)];
AnTemp(5,[2,4,8,10,11,12,14,15]) = [a1*t1*Theta(15), a2*t2*Theta(14), ...
       a1*t1*Theta(12), a2*t2*Theta(11), a2*t2*Theta(10), ...
       a1*t1*Theta(8), a2*t2*Theta(4), a1*t1*Theta(2)];
AnTemp(6,[1,3,8,10,12,13,14,15]) = [a1*t1*Theta(15), a2*t2*Theta(14), ...
       -a1*b1*Theta(13), a2*t1*Theta(12), a2*t1*Theta(10), ...
       -a1*b1*Theta(8), a2*t2*Theta(3), a1*t1*Theta(1)];
AnTemp(7,[9,15]) = [a2*t1*Theta(15), a2*t1*Theta(9)];
AnTemp(8,[8,10,14,15]) = [a1*t1*Theta(15), a2*t2*Theta(14), ...
       a2*t2*Theta(10), a1*t1*Theta(8)];
AnTemp(9,[7,9,14,15]) = [a1*t1*Theta(15), a2*t2*Theta(14), ...
       a2*t2*Theta(9), a1*t1*Theta(7)];
AnTemp(10,[11,12,14,15]) = [a2*t2*Theta(15), a1*t1*Theta(14), ...
       a1*t1*Theta(12), a2*t2*Theta(11)];
AnTemp(11,[12,13,14,15]) = [a2*t1*Theta(15), -a1*b1*Theta(14), ...
       -a1*b1*Theta(13), a2*t1*Theta(12)];
AnTemp(12,[14,15]) = [d_An(4)*Theta(15), d_An(4)*Theta(14)];
AnTemp(13,15) = 2*a2*t1*Theta(15);
%%%%%%%%%%%%%%%%%%%%%%%%%% Adding An2
An = An + AnTemp;

%% For An3 matrix:
AnTemp = zeros(13,15);
AnTemp(2,[4,6,12,13]) = [-a2*b2*Theta(13), c2*Theta(12), ...
       c2*Theta(6), -a2*b2*Theta(4)];
AnTemp(3,[3,4,6,11,12,13]) = [-a2*b2*Theta(13), a2*t1*Theta(12), ...
       c1*Theta(11), c1*Theta(6), a2*t1*Theta(4), -a2*b2*Theta(3)];
AnTemp(5,[6,10,13,15]) = [c2*Theta(15), -a2*b2*Theta(13), ...
       -a2*b2*Theta(10), c2*Theta(6)];
AnTemp(6,[4,5,6,7,9,12,14,15]) = [a2*Theta(9), c2*Theta(15), ...
       c1*Theta(14), a1*t1*Theta(12), a2*Theta(4), a1*t1*Theta(7), ...
       c1*Theta(6), c2*Theta(5)];
AnTemp(9,[10,15]) = [a2*t1*Theta(15), a2*t1*Theta(10)];
AnTemp(10,[13,15]) = [-a2*b2*Theta(15), -a2*b2*Theta(13)];
%%%%%%%%%%%%%%%%%%%%%%%%%% Adding An3
An = An + AnTemp;

%% For An4 matrix:
AnTemp = zeros(13,15);
AnTemp(2,[11,13]) = [-a2*t2*b2*Theta(13), -a2*t2*b2*Theta(11)];
AnTemp(3,[11,12]) = [d_An(3)*Theta(12), d_An(3)*Theta(11)];
AnTemp(5,[13,14]) = [-a2*b2*t2*Theta(14), -a2*b2*t2*Theta(13)];
AnTemp(6,[9,11,13,15]) = [-a2*b2*Theta(13), d_An(3)*Theta(15), ...
       -a2*b2*Theta(9), d_An(3)*Theta(11)];
%%%%%%%%%%%%%%%%%%%%%%%%%% Adding An4
An = An + AnTemp;

%% For An5 matrix:
AnTemp = zeros(13,15);
AnTemp(3,[5,12]) = [c2*Theta(12), c2*Theta(5)];
AnTemp(6,[13,15]) = [-a2*t1*b2*Theta(15), -a2*t1*b2*Theta(13)];
%%%%%%%%%%%%%%%%%%%%%%%%%% Adding An5
An = An + AnTemp;

%% For An6 matrix:
AnTemp = zeros(13,15);
AnTemp(6,[4,15]) = [a2*t1*Theta(15), a2*t1*Theta(4)];
%%%%%%%%%%%%%%%%%%%%%%%%%% Adding An6
An = An + AnTemp;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

