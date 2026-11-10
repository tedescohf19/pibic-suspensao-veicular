function res = sdof_tres_ics(idbase,m,k,F0,w,tf,dt,plotar)
% SDOF_TRES_ICS  Roda os itens (a), (b), (c) dos problemas 3.3 a 3.6:
%   (a) x0 = 0.1 m, v0 = 0 | (b) x0 = 0, v0 = 10 m/s | (c) x0 = 0.1 m, v0 = 10 m/s
    ic = [0.1 0; 0 10; 0.1 10];
    letras = 'abc';
    for i = 1:3
        res(i) = sdof_caso([idbase letras(i)],m,0,k,F0,w,ic(i,1),ic(i,2),tf,dt,plotar);
    end
end
