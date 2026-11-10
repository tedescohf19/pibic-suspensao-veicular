function dz = modelo_quarto_veiculo(t, z, Ms, mu, ks, cs, kt, vel_ms, perfil)
    zr = gerador_perfil_pista(t, vel_ms, perfil);
    
    dz = zeros(4,1);
    dz(1) = z(2); 
    dz(2) = (-ks * (z(1) - z(3)) - cs * (z(2) - z(4))) / Ms; 
    dz(3) = z(4); 
    dz(4) = (ks * (z(1) - z(3)) + cs * (z(2) - z(4)) - kt * (z(3) - zr)) / mu;
end