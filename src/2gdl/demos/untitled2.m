% =========================================================================
% SIMULAÇÃO E ANIMAÇÃO: VW GOL EM PISTA ISO 8608 (CLASSE C)
% =========================================================================
clear; clc; close all;

% 1. Parâmetros Físicos do Veículo (VW Gol - 1/4 de carro)
m1 = 250;     % Massa suspensa (Carroceria) [kg]
m2 = 40;      % Massa não suspensa (Roda/Eixo) [kg]
k1 = 15000;   % Rigidez da mola da suspensão [N/m]
c1 = 1500;    % Coeficiente de amortecimento [N.s/m]
k2 = 150000;  % Rigidez do pneu [N/m]

% 2. Configuração do Tempo e Pista ISO 8608 (Classe C)
dt = 0.01;        % Passo de tempo [s]
t = 0:dt:10;      % Tempo total de 10 segundos (como no seu gráfico)
N = length(t);

% Gerando o Perfil da Pista (Classe C: Rugosidade média aleatória)
% Usamos somatório de senóides com frequências e fases aleatórias para imitar a ISO
rng(42); % Semente fixa para a pista ser sempre a mesma ao rodar
z_pista = zeros(1, N);
n_frequencias = 30;
f_min = 0.5; f_max = 5.0;
frequencias = linspace(f_min, f_max, n_frequencias);

for k = 1:n_frequencias
    amplitude = 0.015 * (frequencias(k)^(-0.5)); % Atenuação típica de pista ISO
    fase = 2 * pi * rand();
    z_pista = z_pista + amplitude * sin(2 * pi * frequencias(k) * t + fase);
end
% Convertendo para centímetros para ficar na mesma escala visual do seu gráfico (-6 a 8 cm)
z_pista_cm = z_pista * 100; 

% 3. Resolução das Equações de Movimento (Integração Numérica)
z1 = zeros(1, N); v1 = zeros(1, N); % Carroceria
z2 = zeros(1, N); v2 = zeros(1, N); % Roda

for i = 1:N-1
    % Forças atuantes (trabalhando em metros para a física)
    z_pista_m = z_pista_cm(i) / 100;
    z2_m = z2(i) / 100; z1_m = z1(i) / 100;
    
    F_susp = k1 * (z2_m - z1_m) + c1 * (v2(i) - v1(i));
    F_pneu = k2 * (z_pista_m - z2_m);
    
    a1 = F_susp / m1;
    a2 = (F_pneu - F_susp) / m2;
    
    v1(i+1) = v1(i) + a1 * dt;
    v2(i+1) = v2(i) + a2 * dt;
    z1(i+1) = z1(i) + v1(i+1) * dt * 100; % Convertendo para cm
    z2(i+1) = z2(i) + v2(i+1) * dt * 100; % Convertendo para cm
end

% 4. Configuração da Janela de Animação
fig = figure('Name', 'VW Gol - Pista ISO 8608 Classe C', 'Position', [50, 50, 900, 750]);

% Gráfico Superior (Deslocamentos no Tempo - Estilo do seu print)
ax1 = subplot(2,1,1);
hold on; grid on;
title('Desempenho da Suspensão: VW Gol em Pista ISO 8608 (Classe C)');
xlabel('Tempo (s)'); ylabel('Deslocamento Vertical (cm)');
xlim([0 t(end)]); ylim([-6.5 8.5]);
linha_pista = plot(ax1, t, z_pista_cm, 'k-', 'LineWidth', 1, 'DisplayName', 'Perfil da Pista (Zr)');
linha_roda  = plot(ax1, 0, 0, 'g-', 'LineWidth', 1.2, 'DisplayName', 'Deslocamento da Roda (m)');
linha_carro = plot(ax1, 0, 0, 'r-', 'LineWidth', 1.5, 'DisplayName', 'Deslocamento da Carroceria (M)');
legend('Location', 'northeast');

% Gráfico Inferior (Animação do Modelo Físico)
ax2 = subplot(2,1,2);
title('Animação Física do Sistema');
axis equal; axis off;
xlim([-1.5 1.5]); ylim([-4 10]);

h_m1 = 5.0;  % Altura base da carroceria em cm
h_m2 = 1.5;  % Altura base do eixo em cm
largura = 0.8;

% 5. Loop de Animação
for i = 1:3:N % Pulando a cada 3 frames para fluidez ideal
    
    % Atualiza as linhas do gráfico superior
    set(linha_roda,  'XData', t(1:i), 'YData', z2(1:i));
    set(linha_carro, 'XData', t(1:i), 'YData', z1(1:i));
    
    % Limpa e redesenha o modelo físico inferior
    cla(ax2);
    hold(ax2, 'on');
    
    y_m1 = h_m1 + z1(i);
    y_m2 = h_m2 + z2(i);
    y_p = z_pista_cm(i);
    
    % Desenha o solo irregular da pista
    plot(ax2, [-1.5 1.5], [0 0], 'k-', 'LineWidth', 2);
    
    % Desenha M1 (Carroceria - Vermelho)
    rectangle('Position', [-largura/2, y_m1-0.6, largura, 1.2], 'FaceColor', [0.8 0.2 0.2], 'Parent', ax2);
    text(0, y_m1, 'Carroceria (M)', 'HorizontalAlignment', 'center', 'Color', 'white', 'FontWeight', 'bold', 'Parent', ax2);
    
    % Desenha M2 (Roda/Eixo - Cinza)
    rectangle('Position', [-largura/4, y_m2-0.3, largura/2, 0.6], 'FaceColor', [0.5 0.5 0.5], 'Parent', ax2);
    text(0, y_m2, 'Roda', 'HorizontalAlignment', 'center', 'Color', 'white', 'Parent', ax2);
    
    % Desenha Pneu (Círculo preto tocando a pista)
    raio = 0.8;
    centro_pneu = y_m2 - 0.3 - raio;
    rectangle('Position', [-raio, centro_pneu, 2*raio, 2*raio], 'Curvature', [1 1], 'FaceColor', [0.2 0.2 0.2], 'Parent', ax2);
    
    % Hastes de ligação (Amortecedor e Pneu)
    plot(ax2, [0 0], [y_m2+0.3, y_m1-0.6], 'b-', 'LineWidth', 4);
    
    drawnow limitrate;
end