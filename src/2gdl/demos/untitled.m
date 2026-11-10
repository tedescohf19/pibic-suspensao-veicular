% =========================================================================
% MODELO DE 1/4 DE VEÍCULO (Conforme Diagrama do Usuário)
% =========================================================================
function simula_modelo_diagrama()
    clear; clc; close all;
    
    % 1. Parâmetros do Sistema (Baseados na imagem)
    M  = 250;     % Sprung Mass (Massa suspensa)
    m  = 40;      % Unsprung Mass (Massa não suspensa)
    Ks = 15000;   % Suspension Stiffness (Rigidez da suspensão)
    Cs = 1500;    % Suspension Damping (Amortecimento da suspensão)
    Kt = 150000;  % Tire Stiffness (Rigidez do pneu)
    
    % 2. Entradas do Sistema
    tf = 5;       % Tempo de simulação (segundos)
    tspan = [0 tf];
    
    % Perfil da pista (Zr): Um solavanco para CIMA. 
    % Como no diagrama Z é para baixo, um obstáculo para cima é negativo!
    Zr_func = @(t) -0.05 * sin(2*pi*1*t) .* (t < 1); 
    
    % Forças externas do diagrama (Fb e Fw)
    Fb_func = @(t) 0; % Força Fb (para baixo) sobre M. Ex: Downforce aerodinâmico
    Fw_func = @(t) 0; % Força Fw (para cima) sobre m.
    
    % Condições iniciais [Z; dZ; Zu; dZu]
    x0 = [0; 0; 0; 0]; 
    
    % 3. Solução das Equações com ODE45
    opcoes = odeset('RelTol', 1e-4, 'AbsTol', 1e-5);
    [t, X] = ode45(@(t, x) eq_estado_diagrama(t, x, M, m, Ks, Cs, Kt, Zr_func, Fb_func, Fw_func), tspan, x0, opcoes);
    
    Z  = X(:, 1); % Deslocamento da massa M
    Zu = X(:, 3); % Deslocamento da massa m
    Zr = arrayfun(Zr_func, t); % Deslocamento da pista
    
    % 4. Configuração da Janela de Animação
    fig = figure('Name', 'Modelo 1/4 Veiculo - Diagrama', 'Position', [100, 100, 900, 500], 'Color', 'w');
    ax1 = subplot(1,2,1); title(ax1, 'Diagrama Animado');
    ax2 = subplot(1,2,2); title(ax2, 'Resposta no Tempo');
    
    hold(ax2, 'on'); grid(ax2, 'on');
    % Multiplicamos por -1 no plot apenas para o gráfico ficar visualmente 
    % "para cima" quando o carro sobe, facilitando a leitura humana.
    linha_Z  = plot(ax2, 0, 0, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Sprung Mass (Z)');
    linha_Zu = plot(ax2, 0, 0, 'g-', 'LineWidth', 1.5, 'DisplayName', 'Unsprung Mass (Zu)');
    linha_Zr = plot(ax2, 0, 0, 'r--', 'LineWidth', 1.5, 'DisplayName', 'Road (Zr)');
    axis(ax2, [0 tf -0.05 0.1]); legend(ax2, 'Location', 'northeast');
    
    % 5. Loop de Animação
    for i = 1:5:length(t)
        % Atualiza Gráfico Direito (Visualização invertida para intuição)
        set(linha_Z,  'XData', t(1:i), 'YData', -Z(1:i));
        set(linha_Zu, 'XData', t(1:i), 'YData', -Zu(1:i));
        set(linha_Zr, 'XData', t(1:i), 'YData', -Zr(1:i));
        
        % Atualiza Desenho Esquerdo
        cla(ax1); hold(ax1, 'on');
        desenha_modelo(Z(i), Zu(i), Zr(i), ax1);
        axis(ax1, [-1 1 -0.2 1.5]); axis(ax1, 'equal'); box(ax1, 'on');
        drawnow limitrate;
    end
end

% =========================================================================
% FÍSICA DO SISTEMA - RIGOROSAMENTE CONFORME A IMAGEM
% =========================================================================
function dx = eq_estado_diagrama(t, x, M, m, Ks, Cs, Kt, Zr_func, Fb_func, Fw_func)
    % Extração dos estados
    Z   = x(1);  % Posição de M (positivo p/ baixo)
    dZ  = x(2);  % Velocidade de M
    Zu  = x(3);  % Posição de m (positivo p/ baixo)
    dZu = x(4);  % Velocidade de m
    
    % Entradas no tempo t
    Zr = Zr_func(t);
    Fb = Fb_func(t);
    Fw = Fw_func(t);
    
    % Forças nas molas e amortecedores (Baseadas na diferença de posição)
    F_suspensao_mola = Ks * (Z - Zu);
    F_suspensao_amort = Cs * (dZ - dZu);
    F_pneu_mola = Kt * (Zu - Zr);
    
    % Montagem das Equações Diferenciais (Seguindo as setas da sua imagem)
    dx = zeros(4,1);
    
    dx(1) = dZ;
    % Equação de M (Fb aponta p/ baixo = +, F_suspensao empurra p/ cima = -)
    dx(2) = (-F_suspensao_mola - F_suspensao_amort + Fb) / M; 
    
    dx(3) = dZu;
    % Equação de m (F_suspensao empurra p/ baixo = +, F_pneu empurra p/ cima = -, Fw p/ cima = -)
    dx(4) = (F_suspensao_mola + F_suspensao_amort - F_pneu_mola - Fw) / m; 
end

% =========================================================================
% GEOMETRIA DO DESENHO NA TELA
% =========================================================================
function desenha_modelo(Z, Zu, Zr, ax)
    % A tela do computador tem o Y positivo para cima. 
    % Portanto, subtraímos Z (que é para baixo) da altura base.
    y_M  = 1.0 - Z;
    y_m  = 0.3 - Zu;
    y_chao = -Zr;
    
    % 1. Pista
    plot(ax, [-0.5 0.5], [y_chao y_chao], 'k-', 'LineWidth', 2);
    
    % 2. Roda/Pneu (Mola Kt fictícia representada pela roda tocando o chão)
    raio = 0.1; centro_roda = y_chao + raio;
    rectangle('Position', [-raio, y_chao, 2*raio, 2*raio], 'Curvature', [1 1], 'EdgeColor', 'b', 'Parent', ax);
    plot(ax, [0 0], [centro_roda+raio, y_m-0.05], 'b-', 'LineWidth', 2); 
    
    % 3. Massa Não Suspensa (m)
    rectangle('Position', [-0.2, y_m-0.05, 0.4, 0.1], 'FaceColor', [0.5 0.5 0.5], 'Parent', ax);
    text(0, y_m, 'm', 'HorizontalAlignment', 'center', 'Color', 'white', 'Parent', ax);
    
    % 4. Massa Suspensa (M)
    rectangle('Position', [-0.3, y_M-0.15, 0.6, 0.3], 'FaceColor', [0.2 0.2 0.2], 'Parent', ax);
    text(0, y_M, 'M', 'HorizontalAlignment', 'center', 'Color', 'white', 'Parent', ax);
    
    % 5. Suspensão (Mola Ks e Amortecedor Cs)
    plot(ax, [-0.15 -0.15], [y_m+0.05, y_M-0.15], 'r-', 'LineWidth', 2); % Representa Ks
    plot(ax, [ 0.15  0.15], [y_m+0.05, y_M-0.15], 'b-', 'LineWidth', 4); % Representa Cs
end