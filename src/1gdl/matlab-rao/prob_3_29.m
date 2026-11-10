function res = prob_3_29(plotar)
% Prob. 3.29: k = 4000 N/m, m = 10 kg, c = 40 N.s/m, F(t) = 200 cos(20 t),
% x0 = 0 m, v0 = 10 m/s. Respostas permanente e total.
    if nargin < 1, plotar = true; end
    res = sdof_caso('3.29',10,40,4000,200,20,0,10,3,1e-3,plotar);
end
