function [t,x,v] = sdof_rk4(m,c,k,F,t0,tf,dt,x0,v0)
% SDOF_RK4  Resolve m*x'' + c*x' + k*x = F(t) por Runge-Kutta classico de 4a ordem.
%   m [kg], c [N.s/m], k [N/m], F = function handle F(t) [N]
%   t0,tf,dt [s], x0 [m], v0 [m/s]
%   Saidas: t, x (deslocamento), v (velocidade)
% Compativel com MATLAB R2016b.
    t = (t0:dt:tf)';
    n = length(t);
    x = zeros(n,1);
    v = zeros(n,1);
    x(1) = x0;
    v(1) = v0;
    for i = 1:n-1
        ti = t(i);
        yi = [x(i); v(i)];
        k1 = sistema(ti,        yi,             m, c, k, F);
        k2 = sistema(ti + dt/2, yi + dt*k1/2,   m, c, k, F);
        k3 = sistema(ti + dt/2, yi + dt*k2/2,   m, c, k, F);
        k4 = sistema(ti + dt,   yi + dt*k3,     m, c, k, F);
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
