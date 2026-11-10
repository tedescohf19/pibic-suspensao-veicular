function res = prob_3_06(plotar)
% Prob. 3.6: k = 4000 N/m, m = 10 kg, F(t) = 400 cos(30 t).
    if nargin < 1, plotar = true; end
    res = sdof_tres_ics('3.6',10,4000,400,30,2,1e-3,plotar);
end
