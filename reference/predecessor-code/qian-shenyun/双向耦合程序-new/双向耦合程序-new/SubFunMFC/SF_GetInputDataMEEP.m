%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Subfuntion SF_GetInputDataMFC()
%Calculate Get Element, Node, ElemType, etc. matrices
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [FinitElemInfo,Material] = SF_GetInputDataMEEP(InputFile)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Defined flag
FlagN=10;        % FlagN: The total number of flags in Input file
TxtFlag = cell(FlagN,1);
TxtFlag{1,1} = 'ELEMENTINFO START';      % ElemType information start
TxtFlag{2,1} = 'ELEMENTINFO END';        % ElemType information end
TxtFlag{3,1} = 'ELEMENT START';          % Element information start
TxtFlag{4,1} = 'ELEMENT END';            % Element information end
TxtFlag{5,1} = 'NODE START';             % Node information start
TxtFlag{6,1} = 'NODE END';               % Node information start
TxtFlag{7,1} = 'MATERIAL START';         % Material information start
TxtFlag{8,1} = 'MATERIAL END';           % Material information start
TxtFlag{9,1} = 'SHELL-THEORY START';     % Shell type and theory start 
TxtFlag{10,1} = 'SHELL-THEORY END';      % Shell type and theory end 
%%% FlagPos: The positions of Flags in Input file
FlagPos=zeros(FlagN,1);
%%% ElementC: columns of element part in Input file
%%% NodeC: columns of node part in Input file
%%% MaterialC: columns of material part in Input file
ElementC = 28;
NodeC = 12;
MaterialC = 27;

%% Read data
fid = fopen(InputFile);               % Open the Input file
%% InputData: Stored all lines of Input file as cell varible
InputData = textscan(fid, '%s','Delimiter','\n\r');
fclose(fid);                          % Close the Input file
%% Line number of the data
LineNum = cellfun(@length,InputData); % Total lines of Input data

%% Find the flag positions
for i = 1:LineNum
    TxtStr = InputData{1,1}(i);       % Read each line of data
    TxtStr = deblank(TxtStr);         % Delete blanks from end of string
    %%% Find the Flag words in the text and record the positions of Flags
    if strcmp(TxtStr, TxtFlag{1,1})
        FlagPos(1,1) = i;
    elseif strcmp(TxtStr, TxtFlag{2,1})
        FlagPos(2,1) = i;
    elseif strcmp(TxtStr, TxtFlag{3,1})
        FlagPos(3,1) = i;
    elseif strcmp(TxtStr, TxtFlag{4,1})
        FlagPos(4,1) = i;
    elseif strcmp(TxtStr, TxtFlag{5,1})
        FlagPos(5,1) = i;
    elseif strcmp(TxtStr, TxtFlag{6,1})
        FlagPos(6,1) = i;
    elseif strcmp(TxtStr, TxtFlag{7,1})
        FlagPos(7,1) = i;
    elseif strcmp(TxtStr, TxtFlag{8,1})
        FlagPos(8,1) = i;
    elseif strcmp(TxtStr, TxtFlag{9,1})
        FlagPos(9,1) = i;
    elseif strcmp(TxtStr, TxtFlag{10,1})
        FlagPos(10,1) = i;
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Extract the components for ElementInfo vector, FlagPos(1:2)
Pos1 = FlagPos(1,1)+1;               % The position of ElemType vector
Pos2 = FlagPos(2,1)-1; 
NumLine = Pos2 - Pos1 + 1;
TxtStr = InputData{1,1}(Pos1:Pos2);  % Read the data from InputData
for i = 1: NumLine
    OneLine = deblank(TxtStr{i,1});
    if isempty(OneLine) == 0
        %%% Transfered to number, get cell variable
        OneLine = textscan(OneLine, '%d'); 
        %%% From cell to vector
        OneLine = OneLine{1,1};        
        %%% Transpose from column vector to row
        ElementInfo = OneLine';              
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Extract the components for Element matrix, FlagPos(3:4)
Pos1 = FlagPos(3,1)+1;               % The start line of Element matrix
Pos2 = FlagPos(4,1)-1;               % The end line of Element matrix
NumElem = Pos2 - Pos1 + 1;            % Element number
Element = zeros(NumElem, ElementC);   % Intiate Element matrix
TxtStr = InputData{1,1}(Pos1 : Pos2); % Rrcord all the element info to TxtStr
%%% Format the string data to int data and store in Element matrix
ElemIndex = 1;
for i = 1: NumElem
    OneLine = deblank(TxtStr{i,1});     % delete blank at the end
    if isempty(OneLine) == 0
        OneLine = textscan(OneLine, '%d');
        OneLine = OneLine{1,1};
        Element(ElemIndex,:) = OneLine'; 
        ElemIndex = ElemIndex + 1;
    else
        NumElem = NumElem - 1;
    end
end
%%% Extract the usefull information
Element = Element(1:NumElem,:);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Extract the components for Node matrix, FlagPos(5:6)
Pos1 = FlagPos(5,1)+1;
Pos2 = FlagPos(6,1)-1;
NumNode = Pos2 - Pos1 + 1;
Node = zeros(NumNode, NodeC);
TxtStr = InputData{1,1}(Pos1 : Pos2);
NodeIndex = 1;
for i = 1: NumNode
    OneLine = deblank(TxtStr{i,1});
    if isempty(OneLine) == 0
        OneLine = textscan(OneLine, '%.12f');
        OneLine = OneLine{1,1};
        Node(NodeIndex,:) = OneLine';  
        NodeIndex = NodeIndex + 1;
    else
        NumNode = NumNode - 1;
    end
end
%%% Extract the usefull information
Node = Node(1:NumNode,:);

% convert float value to int value except the coordinates of X,Y,Z
Node(:,1)=int16(Node(:,1));
Node(:,5:NodeC)=int16(Node(:,5:NodeC));

%% Extract the Material properties, FlagPos(7:8)
Pos1 = FlagPos(7,1)+1;
Pos2 = FlagPos(8,1)-1;
NumLay = Pos2 - Pos1 + 1;
Material = zeros(NumLay, MaterialC);
TxtStr = InputData{1,1}(Pos1 : Pos2);
MateIndex = 1;
for i = 1: NumLay
    OneLine = deblank(TxtStr{i,1});
    if isempty(OneLine) == 0
        OneLine = textscan(OneLine, '%.8f');
        OneLine = OneLine{1,1};
        Material(MateIndex,:) = OneLine';  
        MateIndex = MateIndex + 1;
    else
        NumLay = NumLay - 1;
    end
end
%%% Extract the usefull information
Material = Material(1:NumLay,:);

%% Get shell type and theory
Pos1 = FlagPos(9,1)+1;
Pos2 = FlagPos(10,1)-1;
NumShellTheory = Pos2 - Pos1 + 1;
ShellTheory = zeros(2,1);
TxtStr = InputData{1,1}(Pos1 : Pos2);

ShellTheoIndex = 1;
for i = 1: NumShellTheory
    OneLine = deblank(TxtStr{i,1});
    if isempty(OneLine) == 0
        OneLine = textscan(OneLine, '%s');
        OneLine = char(OneLine{1,1});             % Cell to charactor array
        switch OneLine
            case {'PLATE','RVK5'}
                TypeIndex = 1;
            case {'CYLINDER','MRT5'}
                TypeIndex = 2;
            case {'SPHERE','LRT5'}
                TypeIndex = 3;
            case {'LRT56'}
                TypeIndex = 4;    
            case {'MFC'}
                TypeIndex = 0;
            otherwise 
                TypeIndex = -1;
        end
        ShellTheory(ShellTheoIndex,1) = TypeIndex;
        ShellTheoIndex = ShellTheoIndex + 1;
    end
end
%% Get every sum Layer type 
data=Material(:,MaterialC);
NumMEELay=numel(find(data==2));
%% Get ElemType
%%% ElemType = [Node/Elem DOF/Node NumSmtLay DOF/SmtLay NumLay]
%%% MaterialC: record the variable of 'IsSmtLay'  
NumLay = length(Material(:,1));                 % Number of layers                  
ElemType = [ElementInfo(1),ElementInfo(2),NumLay,ElementInfo(3),NumMEELay];  
%% Constuct FinitElemInfo structure variable
FinitElemInfo = struct('ElemType',ElemType,'Element',Element,'Node',Node, ...
                       'ShellTheory',ShellTheory);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end