%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Subfuntion SF_GetAnMatr_PLATE()
%Get An matrix, only for PLATE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [An] = SF_GetAnMatr_PLATE(Theta)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
An = zeros(13,15); 

%% An matrix
An(1,[1,3,5]) = [Theta(1),Theta(3),Theta(5)];
An(2,[2,4,6]) = [Theta(2),Theta(4),Theta(6)];
An(3,[1,2,3,4,5,6]) = [Theta(2),Theta(1),Theta(4),Theta(3), ...
                       Theta(6),Theta(5)]; 
An(4,[1,3,7,9]) = [Theta(7),Theta(9),Theta(1),Theta(3)];
An(5,[2,4,8,10]) = [Theta(8),Theta(10),Theta(2),Theta(4)];
An(6,[1,2,3,4,7,8,9,10]) = [Theta(8),Theta(7),Theta(10),Theta(9), ...
                            Theta(2),Theta(1),Theta(4),Theta(3)];
An(7,[7,9]) = [Theta(7),Theta(9)];
An(8,[8,10]) = [Theta(8),Theta(10)];
An(9,[7,8,9,10]) = [Theta(8),Theta(7),Theta(10),Theta(9)];
An(10,[2,4,14,15]) = [Theta(14),Theta(15),Theta(2),Theta(4)];
An(11,[1,3,14,15]) = [Theta(14),Theta(15),Theta(1),Theta(3)];
An(12,[8,10,14,15]) = [Theta(14),Theta(15),Theta(8),Theta(10)];
An(13,[7,9,14,15]) = [Theta(14),Theta(15),Theta(7),Theta(9)];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

