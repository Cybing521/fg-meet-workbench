%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Subfuntion SF_GetSugMatr_SHELL()
%Get Sug_PANS matrix, only for plate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function [Sug] = SF_GetSugMatr_MRT5(RNLD1,CurvPara)
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

%% d_An: d1-d4
d_An4 = a1*t1 + a2*t2;

%% Sug = Sug + Suf matrix

f_Suu8 = c1*c2*RNLD1(6)+a2*t2*RNLD1(10);

%% For Sug1 = Suu1 + Suf1
SugTemp = zeros(15,15);
SugTemp(1,14) = a1*RNLD1(11); 
SugTemp(2,14) = a1*RNLD1(10); 
SugTemp(3,15) = a2*RNLD1(11); 
SugTemp(4,15) = a2*RNLD1(10); 
SugTemp(5,[5,6,14,15]) = [RNLD1(1),RNLD1(3),c1*RNLD1(4),c2*RNLD1(6)]; 
SugTemp(6,[5,6]) = [RNLD1(3),RNLD1(2)]; 
SugTemp(7,14) = a1*RNLD1(13); 
SugTemp(8,14) = a1*RNLD1(12);
SugTemp(9,15) = a2*RNLD1(13);
SugTemp(10,15) = a2*RNLD1(12);
SugTemp(11,[11,12]) = [c1^2*RNLD1(1),c1*c2*RNLD1(3)];
SugTemp(12,[11,12,14,15]) = [c1*c2*RNLD1(3), c2^2*RNLD1(2), ...
        c1*c2*RNLD1(6), c2^2*RNLD1(5)];
SugTemp(14,[1,2,5,7,8,12,14,15]) = [a1*RNLD1(11),a1*RNLD1(10), ...
        c1*RNLD1(4),a1*RNLD1(13),a1*RNLD1(12), ...
        c1*c2*RNLD1(6),c1^2*RNLD1(7),c1*c2*RNLD1(9)];
SugTemp(15,[3,4,5,9,10,12,14,15]) = [a2*RNLD1(11),a2*RNLD1(10), ...
        c2*RNLD1(6), a2*RNLD1(13),a2*RNLD1(12),c2^2*RNLD1(5), ...
        c1*c2*RNLD1(9),c2^2*RNLD1(8)];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
Sug = Sug + SugTemp;

%% For Sug2 = Suu2 + Suf2
SugTemp = zeros(15,15);
SugTemp(5,[11,12]) = [c1*RNLD1(1), c2*RNLD1(3)];
SugTemp(6,[11,12,14,15]) = [c1*RNLD1(3), c2*RNLD1(2), c1*RNLD1(6), ...
        c2*RNLD1(5)];
SugTemp(11,[5,6,14,15]) = [c1*RNLD1(1),c1*RNLD1(3),c1^2*RNLD1(4),f_Suu8];
SugTemp(12,[5,6,14,15]) = [c2*RNLD1(3),c2*RNLD1(2), ...
        a1*t1*RNLD1(10),a2*t1*RNLD1(11)];
SugTemp(13,14) = -a1*b1*RNLD1(11);
SugTemp(14,[6,11,12,13,15]) = [c1*RNLD1(6), c1^2*RNLD1(4), ...
        a1*t1*RNLD1(10),-a1*b1*RNLD1(11), d_An4*RNLD1(12)];
SugTemp(15,[6,11,12,14,15]) = [c2*RNLD1(5),f_Suu8,a2*t1*RNLD1(11), ...
        d_An4*RNLD1(12),2*a2*t1*RNLD1(13)];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
Sug = Sug + SugTemp;

%% For Sug3 = Suu3 + Suf3
SugTemp = zeros(15,15);
SugTemp(13,15) = -a2*b2*RNLD1(10);
SugTemp(15,13) = -a2*b2*RNLD1(10);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
Sug = Sug + SugTemp;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end