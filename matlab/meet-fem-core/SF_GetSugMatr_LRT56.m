%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Subfuntion SF_GetSugMatr_SHELL()
%Get Sug_PANS matrix, only for plate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function [Sug] = SF_GetSugMatr_LRT56(RNLD1,CurvPara)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Sug = zeros(18,18);         % Sug = Suu + Suf

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
d_An = zeros(1,6);
d_An(1) = a1*t1^2+c2^2;
d_An(2) = -(a1*t1*b1 + a2*b2*t1);
d_An(3) = a2*t1*t2 + c1*c2;
d_An(4) = a1*t1 + a2*t2;
d_An(5) = c1 - a1*b1;
d_An(6) = c2 - a2*b2;

%% Sug = Sug + Suf matrix
f_Suu = zeros(1,9);
f_Suu(1) = c1^2*RNLD1(1)+a2*t2^2*RNLD1(2);
f_Suu(2) = a2*t1^2*RNLD1(1)+d_An(1)*RNLD1(2);
f_Suu(3) = a2*t1^2*RNLD1(4)+d_An(1)*RNLD1(5);
f_Suu(4) = a1*b1^2*RNLD1(1)+a2*b2^2*RNLD1(2);
f_Suu(5) = c1^2*RNLD1(7)+a2*t2^2*RNLD1(8);
f_Suu(6) = a2*t1^2*RNLD1(4)+d_An(1)*RNLD1(5);
f_Suu(7) = a2*t1^2*RNLD1(7)+d_An(1)*RNLD1(8);
f_Suu(8) = a1*b1^2*RNLD1(4)+a2*b2^2*RNLD1(5);
f_Suu(9) = a1*b1^2*RNLD1(7)+a2*b2^2*RNLD1(8);

%% For Sug1 = Suu1 + Suf1
SugTemp = zeros(18,18);
SugTemp(1,[1,2,7,8,16]) = [a1*RNLD1(1),a1*RNLD1(3),a1*RNLD1(4), ...
                           a1*RNLD1(6),a1*RNLD1(11)]; 
SugTemp(2,[1,2,7,8,16]) = [a1*RNLD1(3),a1*RNLD1(2),a1*RNLD1(6), ...
                           a1*RNLD1(5),a1*RNLD1(10)]; 
SugTemp(3,[3,4,9,10,17]) = [a2*RNLD1(1),a2*RNLD1(3),a2*RNLD1(4), ...
                           a2*RNLD1(6),a2*RNLD1(11)]; 
SugTemp(4,[3,4,10,17]) = [a2*RNLD1(3),a2*RNLD1(2),a2*RNLD1(5),...
                           a2*RNLD1(10)]; 
SugTemp(5,[5,6,12,16,18]) = [RNLD1(1),RNLD1(3),RNLD1(6),c1*RNLD1(4),...
                           RNLD1(11)]; 
SugTemp(6,[5,6,11,12,18]) = [RNLD1(3),RNLD1(2),RNLD1(6),RNLD1(5),RNLD1(10)]; 
SugTemp(7,[1,2,7,8,16]) = a1*[RNLD1(4),RNLD1(6),RNLD1(7),RNLD1(9),...
                           RNLD1(13)]; 
SugTemp(8,[1,2,7,8,16]) = a1*[RNLD1(6),RNLD1(5),RNLD1(9),RNLD1(8),...
                           RNLD1(12)];
SugTemp(9,[3,9,10,13,17]) = a2*[RNLD1(4),RNLD1(7),RNLD1(9),RNLD1(6),...
                           RNLD1(13)];
SugTemp(10,[3,4,9,10,17]) = a2*[RNLD1(6),RNLD1(5),RNLD1(9),RNLD1(8),...
                           RNLD1(12)];
SugTemp(11,[6,11,12,13,18]) = [RNLD1(6),RNLD1(7),RNLD1(9),c1*RNLD1(4),...
                           RNLD1(13)];
SugTemp(12,[5,6,11,12,18]) = [RNLD1(6),RNLD1(5),RNLD1(9),RNLD1(8),...
                           RNLD1(12)];
SugTemp(13,[9,11,13,16]) = [a2*t2*RNLD1(6),c1*RNLD1(4),f_Suu(1),...
                           a2*t2^2*RNLD1(5)];
SugTemp(14,[14,15,16,17]) = [f_Suu(2),d_An(2)*RNLD1(3),d_An(3)*RNLD1(6),...
                           f_Suu(3)];
SugTemp(15,[14,15,17,18]) = [d_An(2)*RNLD1(3),f_Suu(4),-a1*b1*t1*RNLD1(6),...
                           f_Suu(8)];      
SugTemp(16,[1,2,5,7,8,13,14,16,17]) = [a1*RNLD1(11),a1*RNLD1(10), ...
                           c1*RNLD1(4),a1*RNLD1(13),a1*RNLD1(12),...
                           a2*t2^2*RNLD1(5),d_An(3)*RNLD1(6),f_Suu(5),...
                           d_An(3)*RNLD1(9)];
SugTemp(17,[3,4,9,10,14,15,16,17]) = [a2*RNLD1(11),a2*RNLD1(10), ...
                           a2*RNLD1(13),a2*RNLD1(12),f_Suu(6),...
                           -a1*b1*t1*RNLD1(6),d_An(3)*RNLD1(9),f_Suu(7)];
SugTemp(18,[5,6,11,12,15,18]) = [RNLD1(11),RNLD1(10),RNLD1(13),RNLD1(12),...
                           f_Suu(8),f_Suu(9)];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
Sug = Sug + SugTemp;

%% For Sug2 = Suu2 + Suf2
SugTemp = zeros(18,18);
SugTemp(1,[14,15,17,18]) = [a1*t1*RNLD1(3),-a1*b1*RNLD1(1),a1*t1*RNLD1(6),...
        -a1*b1*RNLD1(4)];
SugTemp(2,[14,15,17,18]) = [a1*t1*RNLD1(2),-a1*b1*RNLD1(3),a1*t1*RNLD1(5),...
        -a1*b1*RNLD1(6)];
SugTemp(3,[13,14,16,17]) = [a2*t2*RNLD1(3),a2*t1*RNLD1(1), ...
        a2*t2*RNLD1(6),a2*t1*RNLD1(4)];
SugTemp(4,[13,16]) = [a2*t2*RNLD1(2),a2*t2*RNLD1(5)];
SugTemp(5,[11,13]) = [RNLD1(4),c1*RNLD1(1)];
SugTemp(7,[15,17,18]) = [-a1*b1*RNLD1(4),a1*t1*RNLD1(9),-a1*b1*RNLD1(7)]; 
SugTemp(8,[14,15,17,18]) = [a1*t1*RNLD1(5),-a1*b1*RNLD1(6),a1*t1*RNLD1(8),...
        -a1*b1*RNLD1(9)];
SugTemp(9,[14,16,17]) = [a2*t1*RNLD1(4),a2*t2*RNLD1(9),a2*t1*RNLD1(7)];
SugTemp(10,[13,14,16]) = [a2*t2*RNLD1(5),a2*t1*RNLD1(6),a2*t2*RNLD1(8)];
SugTemp(11,[5,16]) = [RNLD1(4),c1*RNLD1(7)];
SugTemp(12,13) = c1*RNLD1(6);
SugTemp(13,[3,4,5,10,12,16,17,18]) = [a2*t2*RNLD1(3),a2*t2*RNLD1(2), ...
        c1*RNLD1(1),a2*t2*RNLD1(5),c1*RNLD1(6),c1^2*RNLD1(4),...
        a2*t2*RNLD1(10),c1*RNLD1(11)];
SugTemp(14,[1,2,3,8,9,10,16,17]) = [a1*t1*RNLD1(3),a1*t1*RNLD1(2), ...
        a2*t1*RNLD1(1),a1*t1*RNLD1(5),a2*t1*RNLD1(4),a2*t1*RNLD1(6), ...
        a1*t1*RNLD1(10),a2*t1*RNLD1(11)];
SugTemp(15,[1,2,7,8,16]) = [-a1*b1*RNLD1(1),-a1*b1*RNLD1(3), ...
        -a1*b1*RNLD1(4),-a1*b1*RNLD1(6),-a1*b1*RNLD1(11)];
SugTemp(16,[3,4,9,10,11,13,14,15,17,18]) = [a2*t2*RNLD1(6),a2*t2*RNLD1(5), ...
        a2*t2*RNLD1(9),a2*t2*RNLD1(8),c1*RNLD1(7),c1^2*RNLD1(4),...
        a1*t1*RNLD1(10),-a1*b1*RNLD1(11),d_An(4)*RNLD1(12),...
        d_An(5)*RNLD1(13)];
SugTemp(17,[1,2,3,7,8,9,13,14,16,17]) = [a1*t1*RNLD1(6), ...
        a1*t1*RNLD1(5),a2*t1*RNLD1(4),a1*t1*RNLD1(9),a1*t1*RNLD1(8), ...
        a2*t1*RNLD1(7),a2*t2*RNLD1(10),a2*t1*RNLD1(11), ...
        d_An(4)*RNLD1(12),2*a2*t1*RNLD1(13)];
SugTemp(18,[1,2,7,8,13,16]) = [-a1*b1*RNLD1(4),-a1*b1*RNLD1(6),...
        -a1*b1*RNLD1(7),-a1*b1*RNLD1(9),c1*RNLD1(11),d_An(5)*RNLD1(13)];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
Sug = Sug + SugTemp;

%% For Sug3 = Suu3 + Suf3
SugTemp = zeros(18,18);
SugTemp(3,[15,18]) = [-a2*b2*RNLD1(3),-a2*b2*RNLD1(3)];
SugTemp(4,[9,14,15,18]) = [a2*RNLD1(6),a2*t1*RNLD1(3),-a2*b2*RNLD1(2),...
        -a2*b2*RNLD1(5)];
SugTemp(5,17) = c2*RNLD1(6);
SugTemp(6,[13,14,16,17]) = [c1*RNLD1(3),c2*RNLD1(2),c1*RNLD1(6), ...
        c2*RNLD1(5)];
SugTemp(7,14) = a1*t1*RNLD1(6);
SugTemp(9,[4,18]) = [a2*RNLD1(6),-a2*b2*RNLD1(9)];
SugTemp(10,[15,17,18]) = [-a2*b2*RNLD1(5),a2*t1*RNLD1(9),-a2*b2*RNLD1(8)];
SugTemp(12,[14,16,17]) = [c2*RNLD1(5),c1*RNLD1(9),-c2*RNLD1(8)];
SugTemp(13,6) = c1*RNLD1(3);
SugTemp(14,[4,6,7,12,18]) = [a2*t1*RNLD1(3),c2*RNLD1(2),a1*t1*RNLD1(6),...
        c2*RNLD1(5),c2*RNLD1(10)];
SugTemp(15,[3,4,10,17]) = [-a2*b2*RNLD1(3),-a2*b2*RNLD1(2), ...
        -a2*b2*RNLD1(5),-a2*b2*RNLD1(10)];
SugTemp(16,[6,12]) = [c1*RNLD1(6),c1*RNLD1(9)];
SugTemp(17,[5,6,10,12,15,18]) = [c2*RNLD1(6),c2*RNLD1(5),a2*t1*RNLD1(9), ...
        -c2*RNLD1(8),-a2*b2*RNLD1(10),d_An(6)*RNLD1(12)];
SugTemp(18,[3,4,9,10,14,17]) = [-a2*b2*RNLD1(6),-a2*b2*RNLD1(5),...
        -a2*b2*RNLD1(9),-a2*b2*RNLD1(8),c2*RNLD1(10),d_An(6)*RNLD1(12)];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
Sug = Sug + SugTemp;

%% For Sug4 = Suu4 + Suf4
SugTemp = zeros(18,18);
SugTemp(9,15) = -a2*b2*RNLD1(6);
SugTemp(13,[14,15,17,18]) = [d_An(3)*RNLD1(3),-a2*t2*b2*RNLD1(2), ... 
        d_An(3)*RNLD1(6),-a2*b2*t2*RNLD1(5)];
SugTemp(14,[13,18]) = [d_An(3)*RNLD1(3),d_An(2)*RNLD1(6)];
SugTemp(15,[9,13,16]) = -a2*b2*[RNLD1(6),t2*RNLD1(2),t2*RNLD1(5)];
SugTemp(16,[15,18]) = [-a2*b2*t2*RNLD1(5),-a2*b2*t2*RNLD1(8)];
SugTemp(17,[13,18]) = [d_An(3)*RNLD1(6),d_An(2)*RNLD1(9)];
SugTemp(18,[13,14,16,17]) = [-a2*b2*t2*RNLD1(5),d_An(2)*RNLD1(6),...
        -a2*b2*t2*RNLD1(8),d_An(2)*RNLD1(9)];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
Sug = Sug + SugTemp;

%% For Sug5 = Suu5 + Suf5
SugTemp = zeros(18,18);
SugTemp(5,14) = c2*RNLD1(3);
SugTemp(11,[14,17]) = [c2*RNLD1(6),c2*RNLD1(9)];
SugTemp(14,[5,11]) = [c2*RNLD1(3),c2*RNLD1(6)];
SugTemp(15,17) = -a2*t1*b2*RNLD1(6);
SugTemp(17,[11,15]) = [c2*RNLD1(9),-a2*t1*b2*RNLD1(6)];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
Sug = Sug + SugTemp;

%% For Sug6 = Suu6 + Suf6
SugTemp = zeros(18,18);
SugTemp(4,17) = a2*t1*RNLD1(6);
SugTemp(17,4) = a2*t1*RNLD1(6);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
Sug = Sug + SugTemp;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end
