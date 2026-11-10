function res = prob_3_26(plotar)
% Prob. 3.26: k = 4000 N/m, m = 10 kg, c = 40 N.s/m, F(t) = 200 cos(10 t),
% x0 = 0.1 m, v0 = 0 m/s. Respostas permanente e total.
    if nargin < 1, plotar = true; end
    res = sdof_caso('3.26',10,40,4000,200,10,0.1,0,3,1e-3,plotar);
end
