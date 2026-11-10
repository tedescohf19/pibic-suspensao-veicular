function res = prob_3_09(plotar)
% Prob. 3.9: m = 10 kg, k = 5000 N/m, forca de 250 N com frequencia w;
% amplitude maxima 100 mm. Achar w.
% |k - m w^2| = F0/X  ->  w^2 = (k -+ F0/X)/m  (duas solucoes).
    if nargin < 1, plotar = true; end
    m = 10; k = 5000; F0 = 250; Xobs = 0.1;
    w2 = [(k - F0/Xobs), (k + F0/Xobs)]/m;
    w2 = w2(w2 > 0);
    letras = 'abcd';
    for i = 1:numel(w2)
        w = sqrt(w2(i));
        fprintf('\n>> w candidato = %.4f rad/s\n', w);
        res(i) = sdof_caso(['3.9' letras(i)],m,0,k,F0,w,0,0,2,5e-4,plotar);
    end
end
