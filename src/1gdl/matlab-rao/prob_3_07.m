function res = prob_3_07(plotar)
% Prob. 3.7 (5a ed.): massa de peso 100 N, mola de 2000 N/m, F(t) = 25 cos(w t)
% em RESSONANCIA (w = wn) com zeta = 2%. Amplitude do movimento forcado ao fim de
% (a) 1/4 de ciclo, (b) 2 1/2 ciclos, (c) 5 3/4 ciclos.
    if nargin < 1, plotar = true; end
    g = 9.81; W = 100; k = 2000; F0 = 25;
    m = W/g; wn = sqrt(k/m); T = 2*pi/wn;
    zeta = 0.02; c = 2*zeta*m*wn;
    ciclos = [0.25 2.5 5.75];
    [res,d] = sdof_caso('3.7',m,c,k,F0,wn,0,0,6*T,T/2000,plotar);
    for i = 1:3
        tN = ciclos(i)*T;
        % Envoltoria com amortecimento zeta na ressonancia (x0=0, v0=0):
        amp = (F0/(2*zeta*k))*(1 - exp(-zeta*wn*tN));
        xN = interp1(d.t,d.x_rk4,tN);
        fprintf('%5.2f ciclos: amplitude (envoltoria amortecida) = %.4f mm | x(tN) via RK4 = %.4f mm\n', ...
                ciclos(i), amp*1e3, xN*1e3);
    end
end
