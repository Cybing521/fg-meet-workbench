%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Subfuntion SF_GetSugMatr_RVK5()
%Get Sug_PANS matrix, only for plate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function [Sug] = SF_GetSugMatr_RVK5(RNLD1,CurvPara)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Sug = zeros(15,15);         % Sug = Suu + Suf

%% Get curvilinear coordinates parameters
% s1 = CurvPara.s1;
% s2 = CurvPara.s2;

%% Sug = Sug + Suf matrix
Sug(5,[5,6]) = [RNLD1(1),RNLD1(3)];
Sug(6,[5,6]) = [RNLD1(3),RNLD1(2)];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end