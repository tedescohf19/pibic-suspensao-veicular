function res = prob_3_15(plotar)
% Prob. 3.15: m = 100 kg, k = 400 N/m, f(t) = 10 cos(w t), wn = 2 rad/s.
% w = (a) 2 rad/s (RESSONANCIA), (b) 0.2 rad/s, (c) 20 rad/s.
    if nargin < 1, plotar = true; end
    m = 100; k = 400; F0 = 10;
    w  = [2 0.2 20];
    tf = [40 60 20];
    dt = [1e-3 2e-3 1e-3];
    letras = 'abc';
    for i = 1:3
        res(i) = sdof_caso(['3.15' letras(i)],m,0,k,F0,w(i),0,0,tf(i),dt(i),plotar);
    end
end
