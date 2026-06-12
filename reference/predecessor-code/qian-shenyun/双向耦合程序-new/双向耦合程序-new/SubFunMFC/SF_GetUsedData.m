%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Subfuntion SF_GetUsedData()
%Output the data that was used during calculation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [] = SF_GetUsedData(FileName,FinitElemInfo,Material,MateProp)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ElemType = FinitElemInfo.ElemType;
Element = FinitElemInfo.Element;
Node = FinitElemInfo.Node;
NumLay = ElemType(3);
%% Open/create a file
fid = fopen(FileName,'wt');
%% Output ElemType
fprintf(fid,'***********************************************************\n');
fprintf(fid,'ElemType = \n%d,%d,%d,%d,%d;\n',ElemType);
fprintf(fid,'\n\n');

%% Output Material matrix
fprintf(fid,'***********************************************************\n');
fprintf(fid,'Material = \n');
for i = 1:length(Material(:,1))
    fprintf(fid,'%d,%.2E,%.2E,%.2f,%.2f,%.2E,%.2E,%.2E,%.2E,%.2E,%.2f,%.2E,%.2E,%.2E,%2E,%.2E,%.2E,%.2E,%.2E,%.2E,%.2E,%.2E,%.2E,%.2E,%d;\n', ...
            Material(i,:));
end
fprintf(fid,'\n\n');

%% Ouput Element matrix
fprintf(fid,'***********************************************************\n');
fprintf(fid,'Element = \n');
for i = 1:length(Element(:,1))
    fprintf(fid,'%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d;\n', ...
            Element(i,:));
end
fprintf(fid,'\n\n');

%% Output Node matrix
fprintf(fid,'***********************************************************\n');
fprintf(fid,'Node = \n');
for i = 1:length(Node(:,1))
    fprintf(fid,'%d,%.5f,%.5f,%.5f,%d,%d,%d,%d,%d,%d,%d,%d;\n', ...
            Node(i,:));
end
fprintf(fid,'\n\n');

%% Output MateProp
fprintf(fid,'***********************************************************\n');
fprintf(fid,'MateProp = \n');
for i = 1:NumLay
    fprintf(fid,'\n\nLayer%d = \n',i);
    %% Ouput C matrix
    fprintf(fid,'\nc = \n');
    Matr = MateProp{i,1}.C;
    for j = 1:length(Matr(:,1))
        fprintf(fid,'%.4E  %.4E  %.4E  %.4E  %.4E\n',Matr(j,:));
    end
    if Material(i,27)==1
    %% output eP matrix
    fprintf(fid,'\neP = \n');
    Matr = MateProp{i,1}.eP;
    for j = 1:length(Matr(:,1))
        fprintf(fid,'%.4E  %.4E  %.4E  %.4E  %.4E\n',Matr(j,:));
    end 
     %% output gp matrix
    fprintf(fid,'\ngp = \n');
    Matr = MateProp{i,1}.gP;
    Fmt = '%.4E';
    for k = 1:length(Matr(:,1))-1
       Fmt = strcat(Fmt, '%.4E');
    end
    Fmt = strcat(Fmt, '\n');
    for j = 1:length(Matr(:,1))
        fprintf(fid,Fmt,Matr(j,:));
    end
     
    else if Material(i,27)==2
    %% output eM matrix
    fprintf(fid,'\neM = \n');
    Matr = MateProp{i,1}.eM;
    for j = 1:length(Matr(:,1))
        fprintf(fid,'%.4E  %.4E  %.4E  %.4E  %.4E\n',Matr(j,:));
    end   
    %% output gM matrix
    fprintf(fid,'\ngM = \n');
    Matr = MateProp{i,1}.gM;
    Fmt = '%.4E';
    for k = 1:length(Matr(:,1))-1
       Fmt = strcat(Fmt, '  %.4E');
    end
    Fmt = strcat(Fmt, '\n');
    for j = 1:length(Matr(:,1))
        fprintf(fid,Fmt,Matr(j,:));
    end
%% output q matrix
    fprintf(fid,'\nq = \n');
    Matr = MateProp{i,1}.q;
    for j = 1:length(Matr(:,1))
        fprintf(fid,'%.4E  %.4E  %.4E  %.4E  %.4E\n',Matr(j,:));
    end
%%  output Alphat matrix
    fprintf(fid,'\nAlphat = \n');
    Matr = MateProp{i,1}.Lamdat;
    for j = 1:length(Matr(:,1))
        fprintf(fid,'%.4E  %.4E  %.4E  %.4E  %.4E\n',Matr(j,:));
    end
 %%%%%%%%%%%%%%%%%%% 
 %% output Lamdat matrix
    fprintf(fid,'\nq = \n');
    Matr = MateProp{i,1}.q;
    for j = 1:length(Matr(:,1))
        fprintf(fid,'%.4E  %.4E  %.4E  %.4E  %.4E\n',Matr(j,:));
    end
  %% output PyroE matrix   
 fprintf(fid,'\nPyroE = \n');
    Matr = MateProp{i,1}.PyroE;
    Fmt = '%.4E';
    for k1 = 1:length(Matr(:,1))-1
       Fmt = strcat(Fmt, '  %.4E');
    end
    Fmt = strcat(Fmt, '\n');
    for j = 1:length(Matr(:,1))
        fprintf(fid,Fmt,Matr(j,:));
    end
 %%%%%%%%%%%%%%%%%%%%%%%
  %% output PyroM matrix   
 fprintf(fid,'\nPyroM = \n');
    Matr = MateProp{i,1}.PyroM;
    Fmt = '%.4E';
    for k1 = 1:length(Matr(:,1))-1
       Fmt = strcat(Fmt, '  %.4E');
    end
    Fmt = strcat(Fmt, '\n');
    for j = 1:length(Matr(:,1))
        fprintf(fid,Fmt,Matr(j,:));
    end
  %%%%%%%%%%%%%%%%%%%%%%%
    %% output HC matrix   
 fprintf(fid,'\nHC = \n');
    Matr = MateProp{i,1}.HC_Current;
    Fmt = '%.4E';
    for k1 = 1:length(Matr(:,1))-1
       Fmt = strcat(Fmt, '  %.4E');
    end
    Fmt = strcat(Fmt, '\n');
    for j = 1:length(Matr(:,1))
        fprintf(fid,Fmt,Matr(j,:));
    end
   %% output k matrix   
    fprintf(fid,'\nk = \n');
    Matr = MateProp{i,1}.k;
    Fmt = '%.4E';
    for k1 = 1:length(Matr(:,1))-1
       Fmt = strcat(Fmt, '  %.4E');
    end
    Fmt = strcat(Fmt, '\n');
    for j = 1:length(Matr(:,1))
        fprintf(fid,Fmt,Matr(j,:));
    end
    %% output r matrix     
        fprintf(fid,'\nr = \n');
    Matr = MateProp{i,1}.r;
    Fmt = '%.4E';
    for k = 1:length(Matr(:,1))-1
       Fmt = strcat(Fmt, '  %.4E');
    end
    Fmt = strcat(Fmt, '\n');
    for j = 1:length(Matr(:,1))
        fprintf(fid,Fmt,Matr(j,:));
    end  
    %% output c matrix     
        fprintf(fid,'\nr = \n');
    Matr = MateProp{i,1}.c;
    Fmt = '%.4E';
    for k = 1:length(Matr(:,1))-1
       Fmt = strcat(Fmt, '  %.4E');
    end
    Fmt = strcat(Fmt, '\n');
    for j = 1:length(Matr(:,1))
        fprintf(fid,Fmt,Matr(j,:));
    end  
        end
    end
end
   fprintf(fid,'\n\n');
 
%% Close the file
fclose(fid); 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end