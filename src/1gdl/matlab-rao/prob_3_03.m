function res = prob_3_03(plotar)
% Prob. 3.3: k = 4000 N/m, m = 10 kg, F(t) = 400 cos(10 t). Itens (a), (b), (c).
    if nargin < 1, plotar = true; end
    res = sdof_tres_ics('3.3',10,4000,400,10,2,1e-3,plotar);
end
