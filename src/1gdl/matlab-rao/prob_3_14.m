function res = prob_3_14(plotar)
% Prob. 3.14: batimento com periodo de batimento 0.5 s e periodo de
% oscilacao 0.05 s, condicoes iniciais nulas (com zeta = 2%).
    if nargin < 1, plotar = true; end
    Tb = 0.5; Tosc = 0.05;
    dw = 2*pi/Tb;
    wm = 2*pi/Tosc;
    wn = wm + dw/2;
    w  = wm - dw/2;
    fprintf('\n>> wn = %.4f rad/s (%.4f Hz) | w = %.4f rad/s (%.4f Hz)\n', ...
            wn, wn/(2*pi), w, w/(2*pi));

    m = 1; F0 = 1; k = wn^2;
    zeta = 0.02; c = 2*zeta*m*wn;
    dt = 1e-4; tf = 2.25;
    [res,d] = sdof_caso('3.14',m,c,k,F0,w,0,0,tf,dt,plotar);

    % Com amortecimento de 2%, os nos da envoltoria sobem exponencialmente;
    % identificamos os minimos locais da envoltoria movel:
    nw = round(Tosc/dt);
    env = movmax(abs(d.x_rk4), nw);
    % Busca minimos locais separados por pelo menos 0.7*Tb
    min_dist = round(0.7*Tb/dt);
    tc = [];
    for idx = (min_dist+1):(length(env)-min_dist)
        if env(idx) == min(env(idx-min_dist:idx+min_dist))
            if isempty(tc) || (d.t(idx) - tc(end)) > 0.7*Tb
                tc(end+1) = d.t(idx); %#ok<AGROW>
            end
        end
    end
    fprintf('Periodo de batimento medido no RK4 = %.4f s (dado: %.4f s)\n', ...
            mean(diff(tc)), Tb);
end
