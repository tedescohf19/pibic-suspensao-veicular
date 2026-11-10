function res = prob_3_04(plotar)
% Prob. 3.4: k = 4000 N/m, m = 10 kg, F(t) = 400 cos(20 t)  (RESSONANCIA, wn = 20).
    if nargin < 1, plotar = true; end
    res = sdof_tres_ics('3.4',10,4000,400,20,3,1e-3,plotar);
end
