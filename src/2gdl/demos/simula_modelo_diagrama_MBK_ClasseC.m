% =========================================================================
% SIMULAÇÃO 1/4 DE VEÍCULO (Estilo MBK) - PISTA ISO 8608 CLASSE C
% =========================================================================
function simula_modelo_diagrama_MBK_ClasseC()
    clear; clc; close all;
    
    % 1. Parâmetros Físicos do Sistema
    M  = 250;     % Massa Suspensa 
    m  = 40;      % Massa Não Suspensa (Roda)
    Ks = 15000;   % Rigidez da Suspensão
    Cs = 1500;    % Amortecimento da Suspensão
    Kt = 150000;  % Rigidez do Pneu 
    
    % 2. Configuração do Tempo
    tf = 10;       % Simular por 10 segundos
    tspan = [0 tf];
    
    % 3. Gerador de Pista ISO 8608 - Classe C
    rng(42); % Semente fixa para a pista ser a mesma em todos os testes
    n_freq = 30;
    frequencias = linspace(0.5, 5.0, n_freq);
    fases = 2 * pi * rand(1, n_freq);
    amplitudes = 0.015 * (frequencias.^(-0.5)); % Atenuação característica da norma
    
    % Função contínua da pista para o solver ode45
    Zr_func = @(t) sum(amplitudes .* sin(2 * pi * frequencias * t + fases));
    
    x0 = [0; 0; 0; 0]; % Condições iniciais [Z, vZ, Zu, vZu]
    
    % 4. Solução das Equações com ODE45
    opcoes = odeset('RelTol', 1e-4, 'AbsTol', 1e-5);
    [t, X] = ode45(@(t, x) fisica_do_sistema(t, x, M, m, Ks, Cs, Kt, Zr_func), tspan, x0, opcoes);
    
    Z  = X(:, 1); % Deslocamento da massa suspensa (M)
    Zu = X(:, 3); % Deslocamento da massa da roda (m)
    
    % Extraindo o vetor da pista para plotar
    Zr = zeros(length(t), 1);
    for k = 1:length(t)
        Zr(k) = Zr_func(t(k));
    end
    
    % 5. Configuração da Janela (Estilo MBK)
    fig = figure('Name', 'Modelo MBK - Pista Classe C', 'Position', [50, 50, 1000, 550], 'Color', 'w');
    ax1 = subplot(1,2,1); % Animação à esquerda
    ax2 = subplot(1,2,2); % Gráfico à direita
    
    hold(ax2, 'on'); grid(ax2, 'on');
    linha_Z  = plot(ax2, 0, 0, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Massa Suspensa (Z)');
    linha_Zu = plot(ax2, 0, 0, 'g-', 'LineWidth', 1.5, 'DisplayName', 'Massa da Roda (Zu)');
    linha_Zr = plot(ax2, 0, 0, 'k-', 'LineWidth', 1.0, 'DisplayName', 'Pista Classe C (Zr)');
    % Escala ajustada para os solavancos da Classe C (+- 8 cm)
    axis(ax2, [0 tf -0.08 0.08]); legend(ax2, 'Location', 'northeast');
    title(ax2, 'Desempenho na Pista ISO 8608');
    xlabel(ax2, 'Tempo (s)'); ylabel(ax2, 'Deslocamento (m)');
    
    % 6. Loop de Animação
    for i = 1:4:length(t) % Pula frames para otimizar o tempo real
        % Atualiza as linhas do gráfico
        set(linha_Z,  'XData', t(1:i), 'YData', Z(1:i));
        set(linha_Zu, 'XData', t(1:i), 'YData', Zu(1:i));
        set(linha_Zr, 'XData', t(1:i), 'YData', Zr(1:i));
        
        % Redesenha o modelo
        cla(ax1); hold(ax1, 'on');
        desenha_modelo_MBK(Z(i), Zu(i), Zr(i), ax1);
        
        axis(ax1, [-1 1 -0.2 1.8]); 
        axis(ax1, 'equal'); box(ax1, 'on');
        title(ax1, 'Comportamento Vibracional');
        
        drawnow limitrate;
    end
end

% =========================================================================
% FÍSICA DO SISTEMA 
% =========================================================================
function dx = fisica_do_sistema(t, x, M, m, Ks, Cs, Kt, Zr_func)
    Z = x(1); dZ = x(2);
    Zu = x(3); dZu = x(4);
    Zr = Zr_func(t);
    
    F_mola_susp   = Ks * (Z - Zu);
    F_amort_susp  = Cs * (dZ - dZu);
    F_mola_pneu   = Kt * (Zu - Zr);
    
    dx = zeros(4,1);
    dx(1) = dZ;
    dx(2) = (-F_mola_susp - F_amort_susp) / M;
    dx(3) = dZu;
    dx(4) = (F_mola_susp + F_amort_susp - F_mola_pneu) / m;
end

% =========================================================================
% GEOMETRIA DO DESENHO
% =========================================================================
function desenha_modelo_MBK(Z, Zu, Zr, ax)
    y_chao = 0.0 + Zr;
    y_m    = 0.5 + Zu;
    y_M    = 1.3 + Z;
    
    % Chão
    plot(ax, [-0.6 0.6], [y_chao y_chao], 'k-', 'LineWidth', 2);
    
    % Kt (Pneu)
    desenha_mola(ax, 0, y_chao, y_m-0.1, 4, 0.04);
    text(0.15, y_chao+0.2, 'K_t', 'Parent', ax, 'FontWeight', 'bold');
    
    % m (Roda)
    rectangle('Position', [-0.25, y_m-0.1, 0.5, 0.2], 'FaceColor', [0.8 0.8 0.8], 'EdgeColor', 'k', 'Parent', ax);
    text(0, y_m, 'm', 'HorizontalAlignment', 'center', 'Parent', ax, 'FontWeight', 'bold');
    
    % Ks e Cs (Suspensão)
    desenha_mola(ax, -0.15, y_m+0.1, y_M-0.2, 5, 0.05); 
    text(-0.35, y_m+0.35, 'K_s', 'Parent', ax, 'FontWeight', 'bold');
    desenha_amortecedor(ax, 0.15, y_m+0.1, y_M-0.2, 0.04);
    text(0.35, y_m+0.35, 'C_s', 'Parent', ax, 'FontWeight', 'bold');
    
    % M (Carroceria)
    rectangle('Position', [-0.4, y_M-0.2, 0.8, 0.4], 'FaceColor', [0.4 0.6 0.8], 'EdgeColor', 'k', 'Parent', ax);
    text(0, y_M, 'M', 'HorizontalAlignment', 'center', 'Parent', ax, 'FontWeight', 'bold');
end

% =========================================================================
% FUNÇÕES DE DESENHO (Zig-zag e Pistão)
% =========================================================================
function desenha_mola(ax, x, y_bottom, y_top, voltas, largura)
    pontos_y = linspace(y_bottom, y_top, 2*voltas + 1);
    pontos_x = zeros(1, 2*voltas + 1);
    for i = 2:2:2*voltas; pontos_x(i) = largura; pontos_x(i+1) = -largura; end
    pontos_x(1) = 0; pontos_x(end) = 0;
    plot(ax, x + pontos_x, pontos_y, 'b-', 'LineWidth', 1.5);
end

function desenha_amortecedor(ax, x, y_bottom, y_top, w)
    L = y_top - y_bottom;
    y_base = y_bottom + 0.2*L; y_borda = y_bottom + 0.6*L; y_pistao = y_bottom + 0.45*L;
    plot(ax, [x x], [y_bottom, y_base], 'k-', 'LineWidth', 1.5); 
    plot(ax, [x-w, x+w], [y_base, y_base], 'k-', 'LineWidth', 1.5); 
    plot(ax, [x-w, x-w], [y_base, y_borda], 'k-', 'LineWidth', 1.5); 
    plot(ax, [x+w, x+w], [y_base, y_borda], 'k-', 'LineWidth', 1.5); 
    plot(ax, [x x], [y_top, y_pistao], 'k-', 'LineWidth', 1.5); 
    plot(ax, [x-0.8*w, x+0.8*w], [y_pistao, y_pistao], 'k-', 'LineWidth', 3); 
end