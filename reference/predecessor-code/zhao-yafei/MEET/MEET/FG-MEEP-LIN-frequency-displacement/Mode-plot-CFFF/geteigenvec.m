load('CFFF-V-index-2-P-0.2.mat')
DispMode = 1;
[EigenVector,EigenValue]=SF_ModesAnalysis(DispMode,GlobMatr, ...
                                                   FinitElemInfo);
save('EigenVector_health.mat','EigenVector')
                                               