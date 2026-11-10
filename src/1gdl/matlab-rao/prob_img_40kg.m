function res = prob_img_40kg(plotar)
% Exercicio da imagem: massa de 40 kg, mola 4e4 N/m, forca harmonica de
% 100 N a 120 rad/s. Amplitude da resposta forcada?  (sem amortecimento)
    if nargin < 1, plotar = true; end
    m = 40; c = 0; k = 4e4; F0 = 100; w = 120;
    res = sdof_caso('IMG',m,c,k,F0,w,0,0,1,1e-4,plotar);
    fprintf('>> Amplitude da resposta forcada = %.4f mm\n', res.X_teor*1e3);
end
