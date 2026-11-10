function res = prob_3_01(plotar)
% Rao 5a ed., Prob. 3.1: peso de 50 N, mola de 4000 N/m, forca de 60 N a 6 Hz.
% (a) extensao pelo peso, (b) deslocamento estatico da forca maxima,
% (c) amplitude do movimento forcado.
    if nargin < 1, plotar = true; end
    g = 9.81; W = 50; k = 4000; F0 = 60; f = 6;
    m = W/g; w = 2*pi*f;
    fprintf('\n(a) extensao da mola pelo peso = %.4f mm\n', W/k*1e3);
    fprintf('(b) deslocamento estatico da forca maxima = %.4f mm\n', F0/k*1e3);
    res = sdof_caso('3.1',m,0,k,F0,w,0,0,3,5e-4,plotar);
    fprintf('(c) amplitude do movimento forcado = %.4f mm\n', res.X_teor*1e3);
end
