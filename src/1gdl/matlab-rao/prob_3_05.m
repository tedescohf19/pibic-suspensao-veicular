function res = prob_3_05(plotar)
% Prob. 3.5: k = 4000 N/m, m = 10 kg, F(t) = 400 cos(20.1 t)  (BATIMENTO).
% Periodo de batimento = 2*pi/(wn - w) = 62.8 s, por isso tf = 70 s.
    if nargin < 1, plotar = true; end
    res = sdof_tres_ics('3.5',10,4000,400,20.1,70,2e-3,plotar);
end
