 figure
A1=plot(A(1:6,1),A(1:6,2));
  hold on
 A2=plot(A(1:6,1),A(1:6,3));
 hold on
   A3=plot(A(1:6,1),A(1:6,4));
 hold on
 A4=plot(A(1:6,1),A(1:6,5));
%  hold on
% A5=plot(A(1:6,1),A(1:6,6));
%  hold on
%  A6=plot(A(1:6,1),A(1:6,7));
%  hold on
%  A7=plot(A(1:6,1),A(1:6,8));
%  hold on
%  A8=plot(A(1:6,1),A(1:6,9));
%  hold on
%  A9=plot(A(1:6,1),A(1:6,10));
%  hold on
%  A10=plot(A(1:6,1),A(1:6,11));






% lgd1=legend([A1,A2,],'第一个图例','第二个图例','orientation','horizontal','location','north');
% legend boxoff;
% ah=axes('position',get(gca,'position'),'visible','off');
% lgd2=legend(ah,[A3,A4],'第三个图例','第四个图例','orientation','horizontal','location','north');
% legend boxoff;
% ah=axes('position',get(gca,'position'),'visible','off');
% lgd3=legend(ah,[A5,A6],'第五个图例','第六个图例','orientation','horizontal','location','north');
% legend boxoff;
% ah=axes('position',get(gca,'position'),'visible','off');
% lgd4=legend(ah,[A7,A8],'第七个图例','第八个图例','orientation','horizontal','location','north');
% legend boxoff;
% 
% 
% 
% % lgd2=legend(ah,[A5,A6,A7,A8],'第五个图例','第六个图例','第七个图例','第八个图例','orientation','horizontal','location','north');
% % legend boxoff;
% % hFig = figure(1);
% % %%% set(hFig,'position',[x,y,width,height])
% % set(hFig,'position',[200,300,400,200])
% % 
% % %axis([0 1 -0.1 1]);
% close all
% clc
% x=0:5:400;
% y=x;
% [X,Y]=meshgrid(x,y);%这里很重要
% Z=S1(1:81,1);
% [X,Y,Z]=griddata(x,y,z,linspace(0,400,80)',linspace(0,400,80),'v4');%v4'代表插值方法为matlab4格点样条函数内插?
% surf(X,Y,Z);
% % contourf(X,Y,Z);%等值线图
%  shading faceted;
%  shading interp;%伪彩色图
% clc
% B=A(1:625,1);
% [A1,PS]=mapminmax(B);
% A1





