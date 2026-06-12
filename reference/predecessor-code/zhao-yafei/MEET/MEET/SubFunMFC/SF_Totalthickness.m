function [Totalthickness] = SF_Totalthickness(FinitElemInfo,Material,MateProp)
%UNTITLED 此处显示有关此函数的摘要
%   此处显示详细说明
totalh = 0;
ElemType = FinitElemInfo.ElemType;
Element = FinitElemInfo.Element;
Node = FinitElemInfo.Node;
HC = 0;
NumElem = length(Element(:,1));
NumLay = ElemType(3);
NodePerElem = ElemType(1);
for LayIndex = 1:NumLay
    MatePropCurrLay = MateProp{LayIndex,1};
    Lay_zC = MatePropCurrLay.Lay_zC;
    LayHigh = abs(Lay_zC(1)-Lay_zC(2));
    totalh = totalh+LayHigh;
     Mate_HC = MatePropCurrLay.HC_Current;
     aa=1/Mate_HC;
    HC=HC+aa*LayHigh; 
end 
Totalthickness = struct( 'totalh',totalh,'HC',HC);
end

