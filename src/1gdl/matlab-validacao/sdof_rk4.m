function [t,x,v] = sdof_rk4(m,c,k,F,t0,tf,dt,x0,v0)
% SDOF_RK4
%
% Resolve:
%
%   m*x'' + c*x' + k*x = F(t)
%
% pelo metodo de Runge-Kutta classico de 4a ordem.
%
% Entradas:
%   m  - massa [kg]
%   c  - amortecimento [N.s/m]
%   k  - rigidez [N/m]
%   F  - function handle da forca externa
%        Exemplo: F = @(t) 100*cos(120*t)
%   t0 - tempo inicial [s]
%   tf - tempo final [s]
%   dt - passo de integracao [s]
%   x0 - deslocamento inicial [m]
%   v0 - velocidade inicial [m/s]
%
% Saidas:
%   t - vetor de tempo [s]
%   x - deslocamento [m]
%   v - velocidade [m/s]
%
% Compativel com MATLAB R2016b.

    % Vetor de tempo
    t = (t0:dt:tf)';
    n = length(t);

    % Pre-alocacao
    x = zeros(n,1);
    v = zeros(n,1);

    % Condicoes iniciais
    x(1) = x0;
    v(1) = v0;

    % Integracao no tempo
    for i = 1:n-1
        ti = t(i);
        yi = [x(i); v(i)];

        % k1
        k1 = sistema(ti, yi, m, c, k, F);

        % k2
        k2 = sistema(ti + dt/2, yi + dt*k1/2, m, c, k, F);

        % k3
        k3 = sistema(ti + dt/2, yi + dt*k2/2, m, c, k, F);

        % k4
        k4 = sistema(ti + dt, yi + dt*k3, m, c, k, F);

        % Atualizacao RK4
        y_next = yi + dt/6*(k1 + 2*k2 + 2*k3 + k4);

        x(i+1) = y_next(1);
        v(i+1) = y_next(2);
    end
end

function dydt = sistema(t,y,m,c,k,F)
    x = y(1);
    v = y(2);

    a = (F(t) - c*v - k*x)/m;

    dydt = [v; a];
end
