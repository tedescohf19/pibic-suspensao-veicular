function res = prob_3_11(plotar,F0,w)
% Prob. 3.11: massa de 100 kg em plano inclinado de 20 graus, mola de 4000 N/m,
% forca f(t) = F0 cos(w t) ao longo do plano, condicoes iniciais nulas.
% O livro deixa F0 e w literais; aqui valem F0 = 100 N e w = 10 rad/s como
% EXEMPLO (passe outros valores: prob_3_11(true, F0, w)).
% Medindo x a partir da posicao de equilibrio estatico, a componente do peso
% so desloca o equilibrio e m x'' + k x = F0 cos(w t).
    if nargin < 1, plotar = true; end
    if nargin < 2, F0 = 100; end
    if nargin < 3, w = 10; end
    g = 9.81; m = 100; k = 4000; theta = 20*pi/180;
    fprintf('\nDeslocamento estatico pelo peso (m g sin(theta)/k) = %.4f mm\n', ...
            m*g*sin(theta)/k*1e3);
    res = sdof_caso('3.11',m,0,k,F0,w,0,0,3,1e-3,plotar);
end
