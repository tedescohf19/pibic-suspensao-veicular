function [x,X,phi] = sdof_exata(m,c,k,F0,w,x0,v0,t)
% SDOF_EXATA  Solucao analitica de m*x'' + c*x' + k*x = F0*cos(w*t)
%   (subamortecido ou sem amortecimento), com x(0)=x0 e x'(0)=v0.
%   Saidas: x(t) resposta total, X amplitude permanente, phi fase [rad]
%   Na ressonancia sem amortecimento (c=0, w=wn) X = phi = NaN.
    t = t(:);
    wn = sqrt(k/m);
    zeta = c/(2*m*wn);
    if zeta >= 1
        error('sdof_exata: apenas casos subamortecidos (zeta < 1).');
    end
    wd = wn*sqrt(1 - zeta^2);
    den = k - m*w^2;
    if c == 0 && abs(den) < 1e-9*k
        X = NaN;
        phi = NaN;
        x = x0*cos(wn*t) + (v0/wn)*sin(wn*t) + F0/(2*m*wn)*t.*sin(wn*t);
        return
    end
    X = F0/sqrt(den^2 + (c*w)^2);
    phi = atan2(c*w, den);
    C1 = x0 - X*cos(phi);
    vp0 = X*w*sin(phi);
    C2 = (v0 + zeta*wn*C1 - vp0)/wd;
    x = exp(-zeta*wn*t).*(C1*cos(wd*t) + C2*sin(wd*t)) + X*cos(w*t - phi);
end
