%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Subfuntion SF_GetSugMatr_SHELL()
%Get Sug_PANS matrix, only for plate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function [Sug] = SF_GetSugMatr_LRT5(RNLD1,CurvPara)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Sug = zeros(15,15);         % Sug = Suu + Suf

%% Get curvilinear coordinates parameters
a1 = CurvPara.a1;
a2 = CurvPara.a2;
b1 = CurvPara.b1;
b2 = CurvPara.b2;
c1 = CurvPara.c1;
c2 = CurvPara.c2;
t1 = CurvPara.t1;
t2 = CurvPara.t2;

%% d_An: d1-d9
d_An = zeros(1,4);
d_An(1) = a1*t1^2+c2^2;
d_An(2) = -(a1*t1*b1 + a2*b2*t1);
d_An(3) = a2*t1*t2 + c1*c2;
d_An(4) = a1*t1 + a2*t2;

%% Sug = Sug + Suf matrix
f_Suu = zeros(1,7);
f_Suu(1) = c1^2*RNLD1(1)+a2*t2^2*RNLD1(2);
f_Suu(2) = a2*t1^2*RNLD1(1)+d_An(1)*RNLD1(2);
f_Suu(3) = a2*t1^2*RNLD1(4)+d_An(1)*RNLD1(5);
f_Suu(4) = a1*b1^2*RNLD1(1)+a2*b2^2*RNLD1(2);
f_Suu(5) = c1^2*RNLD1(7)+a2*t2^2*RNLD1(8);
f_Suu(6) = a2*t1^2*RNLD1(4)+d_An(1)*RNLD1(5);
f_Suu(7) = a2*t1^2*RNLD1(7)+d_An(1)*RNLD1(8);

%% For Sug1 = Suu1 + Suf1
SugTemp = zeros(15,15);
SugTemp(1,[1,2,7,8,14]) = [a1*RNLD1(1),a1*RNLD1(3),a1*RNLD1(4), ...
                           a1*RNLD1(6),a1*RNLD1(11)]; 
SugTemp(2,[1,2,7,8,14]) = [a1*RNLD1(3),a1*RNLD1(2),a1*RNLD1(6), ...
                           a1*RNLD1(5),a1*RNLD1(10)]; 
SugTemp(3,[3,4,9,10,15]) = [a2*RNLD1(1),a2*RNLD1(3),a2*RNLD1(4), ...
                            a2*RNLD1(6),a2*RNLD1(11)]; 
SugTemp(4,[3,4,10,15]) = [a2*RNLD1(3),a2*RNLD1(2),a2*RNLD1(5),a2*RNLD1(10)]; 
SugTemp(5,[5,6,14]) = [RNLD1(1),RNLD1(3),c1*RNLD1(4)]; 
SugTemp(6,[5,6]) = [RNLD1(3),RNLD1(2)]; 
SugTemp(7,[1,2,7,8,14]) = a1*[RNLD1(4),RNLD1(6),RNLD1(7),RNLD1(9),RNLD1(13)]; 
SugTemp(8,[1,2,7,8,14]) = a1*[RNLD1(6),RNLD1(5),RNLD1(9),RNLD1(8),RNLD1(12)];
SugTemp(9,[3,9,10,11,15]) = a2*[RNLD1(4),RNLD1(7),RNLD1(9),RNLD1(6),RNLD1(13)];
SugTemp(10,[3,4,9,10,15]) = a2*[RNLD1(6),RNLD1(5),RNLD1(9),RNLD1(8),RNLD1(12)];
SugTemp(11,[9,11,14]) = [a2*t2*RNLD1(6),f_Suu(1),a2*t2^2*RNLD1(5)];
SugTemp(12,[12,15]) = [f_Suu(2),f_Suu(3)];
SugTemp(13,[12,13,15]) = [d_An(1)*RNLD1(3),f_Suu(4),-a1*b1*t1*RNLD1(6)];      
SugTemp(14,[1,2,5,7,8,11,12,14,15]) = [a1*RNLD1(11),a1*RNLD1(10), ...
        c1*RNLD1(4),a1*RNLD1(13),a1*RNLD1(12),a2*t2^2*RNLD1(5), ...
        d_An(3)*RNLD1(6),f_Suu(5),d_An(3)*RNLD1(9)];
SugTemp(15,[3,4,9,10,12,13,14,15]) = [a2*RNLD1(11),a2*RNLD1(10), ...
        a2*RNLD1(13),a2*RNLD1(12),f_Suu(6),-a1*b1*t1*RNLD1(6), ...
        d_An(3)*RNLD1(9),f_Suu(7)];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
Sug = Sug + SugTemp;

%% For Sug2 = Suu2 + Suf2
SugTemp = zeros(15,15);
SugTemp(1,[12,13,15]) = [a1*t1*RNLD1(3),-a1*b1*RNLD1(1),a1*t1*RNLD1(6)];
SugTemp(2,[12,13,15]) = [a1*t1*RNLD1(2),-a1*b1*RNLD1(3),a1*t1*RNLD1(5)];
SugTemp(3,[11,12,14,15]) = [a2*t2*RNLD1(3),a2*t1*RNLD1(1), ...
        a2*t2*RNLD1(6),a2*t1*RNLD1(4)];
SugTemp(4,[11,14]) = [a2*t2*RNLD1(2),a2*t2*RNLD1(5)];
SugTemp(5,11) = c1*RNLD1(1);
SugTemp(7,[13,15]) = [-a1*b1*RNLD1(4),a1*t1*RNLD1(9)]; 
SugTemp(8,[12,13,15]) = [a1*t1*RNLD1(5),-a1*b1*RNLD1(6),a1*t1*RNLD1(8)];
SugTemp(9,[12,14,15]) = [a2*t1*RNLD1(4),a2*t2*RNLD1(9),a2*t1*RNLD1(7)];
SugTemp(10,[11,12,14]) = [a2*t2*RNLD1(5),a2*t1*RNLD1(6),a2*t2*RNLD1(8)];
SugTemp(11,[3,4,5,10,14,15]) = [a2*t2*RNLD1(3),a2*t2*RNLD1(2), ...
        c1*RNLD1(1),a2*t2*RNLD1(5),c1^2*RNLD1(4),a2*t2*RNLD1(10)];
SugTemp(12,[1,2,3,8,9,10,14,15]) = [a1*t1*RNLD1(3),a1*t1*RNLD1(2), ...
        a2*t1*RNLD1(1),a1*t1*RNLD1(5),a2*t1*RNLD1(4),a2*t1*RNLD1(6), ...
        a1*t1*RNLD1(10),a2*t1*RNLD1(11)];
SugTemp(13,[1,2,7,8,14]) = [-a1*b1*RNLD1(1),-a1*b1*RNLD1(3), ...
        -a1*b1*RNLD1(4),-a1*b1*RNLD1(6),-a1*b1*RNLD1(11)];
SugTemp(14,[3,4,9,10,11,12,13,15]) = [a2*t2*RNLD1(6),a2*t2*RNLD1(5), ...
        a2*t2*RNLD1(9),a2*t2*RNLD1(8),c1^2*RNLD1(4),a1*t1*RNLD1(10), ...
        -a1*b1*RNLD1(11),d_An(4)*RNLD1(12)];
SugTemp(15,[1,2,3,7,8,9,11,12,14,15]) = [a1*t1*RNLD1(6), ...
        a1*t1*RNLD1(5),a2*t1*RNLD1(4),a1*t1*RNLD1(9),a1*t1*RNLD1(8), ...
        a2*t1*RNLD1(7),a2*t2*RNLD1(10),a2*t1*RNLD1(11), ...
        d_An(4)*RNLD1(12),2*a2*t1*RNLD1(13)];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
Sug = Sug + SugTemp;

%% For Sug3 = Suu3 + Suf3
SugTemp = zeros(15,15);
SugTemp(3,13) = -a2*b2*RNLD1(3);
SugTemp(4,[9,12,13]) = [a2*RNLD1(6),a2*t1*RNLD1(3),-a2*b2*RNLD1(2)];
SugTemp(5,15) = c2*RNLD1(6);
SugTemp(6,[11,12,14,15]) = [c1*RNLD1(3),c2*RNLD1(2),c1*RNLD1(6), ...
        c2*RNLD1(5)];
SugTemp(7,12) = a1*t1*RNLD1(6);
SugTemp(9,4) = a2*RNLD1(6);
SugTemp(10,[13,15]) = [-a2*b2*RNLD1(5),a2*t1*RNLD1(9)];
SugTemp(11,6) = c1*RNLD1(3);
SugTemp(12,[4,6,7]) = [a2*t1*RNLD1(3),c2*RNLD1(2),a1*t1*RNLD1(6)];
SugTemp(13,[3,4,10,15]) = [-a2*b2*RNLD1(3),-a2*b2*RNLD1(2), ...
        -a2*b2*RNLD1(5),-a2*b2*RNLD1(10)];
SugTemp(14,6) = c1*RNLD1(6);
SugTemp(15,[5,6,10,13]) = [c2*RNLD1(6),c2*RNLD1(5),a2*t1*RNLD1(9), ...
        -a2*b2*RNLD1(10)];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
Sug = Sug + SugTemp;

%% For Sug4 = Suu4 + Suf4
SugTemp = zeros(15,15);
SugTemp(9,13) = -a2*b2*RNLD1(6);
SugTemp(11,[12,13,15]) = [d_An(3)*RNLD1(3),-a2*t2*b2*RNLD1(2), ... 
        d_An(3)*RNLD1(6)];
SugTemp(12,11) = d_An(3)*RNLD1(3);
SugTemp(13,[9,11,14]) = -a2*b2*[RNLD1(6),t2*RNLD1(2),t2*RNLD1(5)];
SugTemp(14,13) = -a2*b2*t2*RNLD1(5);
SugTemp(15,11) = d_An(3)*RNLD1(6);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
Sug = Sug + SugTemp;

%% For Sug5 = Suu5 + Suf5
SugTemp = zeros(15,15);
SugTemp(5,12) = c2*RNLD1(3);
SugTemp(12,5) = c2*RNLD1(3);
SugTemp(13,15) = -a2*t1*b2*RNLD1(6);
SugTemp(15,13) = -a2*t1*b2*RNLD1(6);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
Sug = Sug + SugTemp;

%% For Sug6 = Suu6 + Suf6
SugTemp = zeros(15,15);
SugTemp(4,15) = a2*t1*RNLD1(6);
SugTemp(15,4) = a2*t1*RNLD1(6);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
Sug = Sug + SugTemp;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end