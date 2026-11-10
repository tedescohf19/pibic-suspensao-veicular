function zr = gerador_perfil_pista(t, vel_ms, perfil)
    x = vel_ms * t;
    zr = 0;
    if strcmp(perfil, 'Degrau')
        if x >= 1.0
            zr = 0.10; 
        end
    elseif strcmp(perfil, 'Lombada')
        if x >= 1.0 && x <= 3.0
            L = 2.0;
            zr = 0.10 * sin(pi * (x - 1.0) / L);
        end
    elseif strcmp(perfil, 'ISO_8608')
        omega = 2 * pi * 0.5;
        zr = 0.05 * sin(omega * x); 
    end
end