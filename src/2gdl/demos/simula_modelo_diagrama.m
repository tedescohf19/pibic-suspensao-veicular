% =========================================================================
% SIMULAÇÃO DO MODELO DE 1/4 DE VEÍCULO (Estilo Animação MBK)
% Componentes: Massa Suspensa (M), Massa da Roda (m), 
%              Mola (Ks), Amortecedor (Cs) e Mola do Pneu (Kt)
% =========================================================================
function simula_modelo_diagrama_MBK()
    clear; clc; close all;
    
    % 1. Parâmetros Físicos do Sistema (Nomenclatura da sua imagem)
    M  = 250;     % Massa Suspensa (Sprung Mass)
    m  = 40;      % Massa Não Suspensa (Unsprung Mass / Roda)
    Ks = 15000;   % Rigidez da Mola da Suspensão
    Cs = 1500;    % Coeficiente do Amortecedor da Suspensão
    Kt = 150000;  % Rigidez da Mola do Pneu (Pneu modelado como mola)
    
    % 2. Configuração do Tempo e da Pista (Zr)
    tf = 5;       % Simular por 5 segundos
    tspan = [0 tf];
    
    % Perfil da pista: um solavanco que ocorre no instante t=0.5s
    Zr_func = @(t) 0.05 * sin(2*pi*2*(t-0.5)) .* (t > 0.5 & t < 1.0); 
    
    x0 = [0; 0; 0; 0]; % Condições iniciais [Z, Velocidade_Z, Zu, Velocidade_Zu]
    
    % 3. Solução das Equações com ODE45
    opcoes = odeset('RelTol', 1e-4, 'AbsTol', 1e-5);
    [t, X] = ode45(@(t, x) fisica_do_sistema(t, x, M, m, Ks, Cs, Kt, Zr_func), tspan, x0, opcoes);
    
    Z  = X(:, 1); % Deslocamento da massa suspensa (M)
    Zu = X(:, 3); % Deslocamento da massa da roda (m)
    Zr = arrayfun(Zr_func, t); % Deslocamento da pista (solo)
    
    % 4. Configuração da Janela (Estilo MBK)
    fig = figure('Name', 'Modelo 1/4 de Veiculo', 'Position', [100, 100, 950, 500], 'Color', 'w');
    ax1 = subplot(1,2,1); % Animação à esquerda
    ax2 = subplot(1,2,2); % Gráfico à direita
    
    hold(ax2, 'on'); grid(ax2, 'on');
    linha_Z  = plot(ax2, 0, 0, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Massa Suspensa (Z)');
    linha_Zu = plot(ax2, 0, 0, 'g-', 'LineWidth', 1.5, 'DisplayName', 'Massa da Roda (Zu)');
    linha_Zr = plot(ax2, 0, 0, 'k--', 'LineWidth', 1.5, 'DisplayName', 'Pista (Zr)');
    axis(ax2, [0 tf -0.1 0.15]); legend(ax2, 'Location', 'northeast');
    title(ax2, 'Resposta Dinâmica no Tempo');
    
    % 5. Loop de Animação
    for i = 1:5:length(t)
        
        % Atualiza as linhas do gráfico
        set(linha_Z,  'XData', t(1:i), 'YData', Z(1:i));
        set(linha_Zu, 'XData', t(1:i), 'YData', Zu(1:i));
        set(linha_Zr, 'XData', t(1:i), 'YData', Zr(1:i));
        
        % Limpa e redesenha a geometria no frame atual
        cla(ax1); hold(ax1, 'on');
        desenha_modelo_MBK(Z(i), Zu(i), Zr(i), ax1);
        
        axis(ax1, [-1 1 -0.2 1.8]); 
        axis(ax1, 'equal'); box(ax1, 'on');
        title(ax1, 'Animação do Modelo Matemático');
        
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
    
    % Forças nas molas e amortecedor
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
% GEOMETRIA DO DESENHO (Estilo MBK)
% =========================================================================
function desenha_modelo_MBK(Z, Zu, Zr, ax)
    % Posições base na tela + deslocamento calculado
    y_chao = 0.0 + Zr;
    y_m    = 0.5 + Zu;
    y_M    = 1.3 + Z;
    
    % 1. Pista (Chão)
    plot(ax, [-0.6 0.6], [y_chao y_chao], 'k-', 'LineWidth', 2);
    
    % 2. Mola do Pneu (Kt) - Conectando o chão à massa m
    desenha_mola(ax, 0, y_chao, y_m-0.1, 4, 0.04);
    text(0.15, y_chao+0.2, 'K_t', 'Parent', ax, 'FontWeight', 'bold');
    
    % 3. Massa da Roda (m)
    rectangle('Position', [-0.25, y_m-0.1, 0.5, 0.2], 'FaceColor', [0.8 0.8 0.8], 'EdgeColor', 'k', 'Parent', ax);
    text(0, y_m, 'm (Roda)', 'HorizontalAlignment', 'center', 'Parent', ax, 'FontWeight', 'bold');
    
    % 4. Suspensão (Ks e Cs) - Conectando massa m à massa M
    desenha_mola(ax, -0.15, y_m+0.1, y_M-0.2, 5, 0.05); % Mola do lado esquerdo
    text(-0.35, y_m+0.35, 'K_s', 'Parent', ax, 'FontWeight', 'bold');
    
    desenha_amortecedor(ax, 0.15, y_m+0.1, y_M-0.2, 0.04); % Amortecedor do lado direito
    text(0.35, y_m+0.35, 'C_s', 'Parent', ax, 'FontWeight', 'bold');
    
    % 5. Massa Suspensa (M)
    rectangle('Position', [-0.4, y_M-0.2, 0.8, 0.4], 'FaceColor', [0.4 0.6 0.8], 'EdgeColor', 'k', 'Parent', ax);
    text(0, y_M, 'M (Carroceria)', 'HorizontalAlignment', 'center', 'Parent', ax, 'FontWeight', 'bold');
end

% =========================================================================
% FUNÇÕES AUXILIARES DE DESENHO (Zig-zag e Pistão)
% =========================================================================
function desenha_mola(ax, x, y_bottom, y_top, voltas, largura)
    pontos_y = linspace(y_bottom, y_top, 2*voltas + 1);
    pontos_x = zeros(1, 2*voltas + 1);
    for i = 2:2:2*voltas
        pontos_x(i) = largura;
        pontos_x(i+1) = -largura;
    end
    pontos_x(1) = 0; pontos_x(end) = 0;
    plot(ax, x + pontos_x, pontos_y, 'b-', 'LineWidth', 1.5);
end

function desenha_amortecedor(ax, x, y_bottom, y_top, w)
    L = y_top - y_bottom;
    y_base = y_bottom + 0.2*L;
    y_borda = y_bottom + 0.6*L;
    % Cilindro
    plot(ax, [x x], [y_bottom, y_base], 'k-', 'LineWidth', 1.5); 
    plot(ax, [x-w, x+w], [y_base, y_base], 'k-', 'LineWidth', 1.5); 
    plot(ax, [x-w, x-w], [y_base, y_borda], 'k-', 'LineWidth', 1.5); 
    plot(ax, [x+w, x+w], [y_base, y_borda], 'k-', 'LineWidth', 1.5); 
    % Pistão
    y_pistao = y_bottom + 0.45*L;
    plot(ax, [x x], [y_top, y_pistao], 'k-', 'LineWidth', 1.5); 
    plot(ax, [x-0.8*w, x+0.8*w], [y_pistao, y_pistao], 'k-', 'LineWidth', 3); 
end