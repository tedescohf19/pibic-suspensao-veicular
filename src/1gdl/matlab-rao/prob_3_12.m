function res = prob_3_12(plotar)
% Prob. 3.12: pessoa de 70 kgf com frequencia natural vertical de 5.2 Hz.
% (a) rigidez equivalente; (b) piso com vibracao harmonica de 5.3 Hz e
% amplitude 0.1 m (com zeta = 2%).
    if nargin < 1, plotar = true; end
    m = 70; fn = 5.2; wn = 2*pi*fn;
    k = m*wn^2;
    zeta = 0.02; c = 2*zeta*m*wn;
    fprintf('\n(a) k equivalente = %.2f N/m\n', k);
    f = 5.3; w = 2*pi*f; Y = 0.1;
    % Forca equivalente transmitida pela base amortecida: F_eq = Y*sqrt(k^2 + (c*w)^2)
    F_eq = Y*sqrt(k^2 + (c*w)^2);
    res = sdof_caso('3.12b',m,c,k,F_eq,w,0,0,12,1e-3,plotar);
    r = w/wn;
    Z_rel = Y*r^2/sqrt((1-r^2)^2 + (2*zeta*r)^2);
    fprintf('(b) amplitude do deslocamento ABSOLUTO da pessoa = %.4f m\n', res.X_teor);
    fprintf('    amplitude do deslocamento RELATIVO ao piso   = %.4f m\n', Z_rel);
end
