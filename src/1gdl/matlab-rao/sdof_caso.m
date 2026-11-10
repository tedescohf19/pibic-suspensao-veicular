function [res,dados] = sdof_caso(id,m,c,k,F0,w,x0,v0,tf,dt,plotar)
% SDOF_CASO  Roda um caso m*x'' + c*x' + k*x = F0*cos(w*t) por RK4 e pela
%   solucao exata, compara, imprime e devolve um struct (uma linha da base).
%   Forca taxa de amortecimento zeta = 2% (0.02) em todos os casos.
    if nargin < 11, plotar = false; end

    wn = sqrt(k/m);
    % Impoe taxa de amortecimento de 2% (zeta = 0.02) em todos os casos
    zeta = 0.02;
    c = 2*zeta*m*wn;

    F = @(t) F0*cos(w*t);

    % resposta total (com as condicoes iniciais dadas)
    [t,x_rk4,~] = sdof_rk4(m,c,k,F,0,tf,dt,x0,v0);
    [x_ex,X,phi] = sdof_exata(m,c,k,F0,w,x0,v0,t);

    % resposta permanente por RK4 (condicoes iniciais da solucao particular)
    if isnan(X)
        x_perm = NaN(size(t));
        X_rk4_perm = NaN;
        phi_deg = NaN;
    else
        [~,x_perm,~] = sdof_rk4(m,c,k,F,0,tf,dt,X*cos(phi),X*w*sin(phi));
        X_rk4_perm = max(abs(x_perm));
        phi_deg = phi*180/pi;
    end

    erro_max = max(abs(x_rk4 - x_ex));

    res = struct('id',id,'m',m,'c',c,'k',k,'F0',F0,'w',w,'x0',x0,'v0',v0, ...
                 'wn',wn,'zeta',zeta,'r',w/wn,'dst',F0/k, ...
                 'X_teor',X,'phi_deg',phi_deg, ...
                 'Xmax_total',max(abs(x_ex)),'X_rk4_perm',X_rk4_perm, ...
                 'erro_max',erro_max,'tf',tf,'dt',dt);
    dados = struct('t',t,'x_rk4',x_rk4,'x_exata',x_ex,'x_perm',x_perm);

    fprintf('\n=== Problema %s ===\n', id);
    fprintf('wn = %.4f rad/s | zeta = %.4f | c = %.4f N.s/m | r = w/wn = %.4f | dst = %.4f mm\n', ...
            wn, zeta, c, w/wn, F0/k*1e3);
    if isnan(X)
        fprintf('Ressonancia (c = 0 e w = wn): nao existe regime permanente.\n');
    else
        fprintf('Amplitude permanente: teorica = %.6f mm | RK4 = %.6f mm | fase = %.4f graus\n', ...
                X*1e3, X_rk4_perm*1e3, phi_deg);
    end
    fprintf('Max|x| (resposta total) = %.6f mm | erro max RK4 = %.3e m\n', ...
            res.Xmax_total*1e3, erro_max);

    if plotar
        figure('Name',['Problema ' id]);
        plot(t,x_ex*1e3,'k-',t,x_rk4*1e3,'r--');
        hold on;
        if isnan(X)
            legend('Total exata','Total RK4','Location','best');
        else
            plot(t,x_perm*1e3,'b-.');
            legend('Total exata','Total RK4','Permanente RK4','Location','best');
        end
        grid on; box on;
        xlabel('t [s]'); ylabel('x [mm]');
        title(['Problema ' id ' (zeta = 2%)']);
    end
end
