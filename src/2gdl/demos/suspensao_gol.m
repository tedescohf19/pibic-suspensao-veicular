% =========================================================================
% SIMULAÇÃO: SUSPENSÃO PASSIVA (1/4 DE VEÍCULO) COM PISTA ISO 8608
% Veículo: VW Gol (Eixo Traseiro Direito)
% Condição de Teste: 40 km/h em Asfalto Classe C (Média/Irregular)
% =========================================================================
clear; clc; close all;

%% 1. PARÂMETROS DO MODELO (O "CARRO")
M  = 169.97;   % Massa suspensa traseira direita (kg)
m  = 26.23;    % Massa não-suspensa traseira direita (kg)
Ks = 6967.8;   % Rigidez da mola (N/m)
Kt = 181387;   % Rigidez do pneu Pirelli (N/m)
Cs = 653.0;    % Coeficiente de amortecimento (N.s/m)

%% 2. SISTEMA EM ESPAÇO DE ESTADOS (A FÍSICA)
% Matriz A: Dinâmica interna do sistema
A = [ 0,          0,           1,      0;
      0,          0,           0,      1;
     -Ks/M,       Ks/M,       -Cs/M,   Cs/M;
      Ks/m,      -(Ks+Kt)/m,   Cs/m,  -Cs/m ];

% Matriz B: Como a pista (Zr) entra no sistema (afetando o pneu)
B = [ 0;
      0;
      0;
      Kt/m ];

% Matriz C: Seleção dos dados de saída [Z_carroceria; Z_roda]
C = [ 1, 0, 0, 0;
      0, 1, 0, 0 ];
      
% Matriz D: Avanço direto (nulo neste caso)
D = [ 0; 
      0 ];

% Cria o modelo do sistema
sys_passive = ss(A, B, C, D);

%% 3. VETOR DE TEMPO E PERFIL DA PISTA (O AMBIENTE)
t = 0:0.01:10;             % Tempo de simulação (10 segundos)
v = 40 / 3.6;              % Velocidade do carro (40 km/h para m/s)
x = v * t;                 % Distância longitudinal percorrida (metros)

% Parâmetros da Norma ISO 8608 (Classe D)
n0  = 0.1;                 % Frequência espacial de referência
Gn0 = 1024e-6;              % Grau de rugosidade (Classe D)

% Configuração da Geração Aleatória
N_senoides = 500;                   % Quantidade de ondas
n_min = 0.01;                       % Frequência mínima
n_max = 10;                         % Frequência máxima
n_freq = linspace(n_min, n_max, N_senoides); 
dn = n_freq(2) - n_freq(1);         % Passo de frequência

Zr = zeros(size(x));                % Inicializa o vetor da pista

% Loop gerador de aleatoriedade da pista
for i = 1:N_senoides
    fase_aleatoria = 2 * pi * rand(); % Sorteio do ângulo
    Amplitude = sqrt(2 * Gn0 * (n0 / n_freq(i))^2 * dn); 
    Zr = Zr + Amplitude * cos(2 * pi * n_freq(i) * x + fase_aleatoria);
end

%% 4. EXECUÇÃO DA SIMULAÇÃO
% Junta o sistema com a pista e calcula a resposta ao longo do tempo
[Y, T, X] = lsim(sys_passive, Zr, t);

% Converte os resultados de metros para centímetros (cm) para melhor visualização
Z_carroceria = Y(:, 1) * 100; 
Z_roda       = Y(:, 2) * 100;
Zr_cm        = Zr * 100;

%% 5. PLOTAGEM DOS RESULTADOS
figure('Color', 'w', 'Position', [100, 100, 900, 500]); 

plot(T, Zr_cm, 'k', 'LineWidth', 1); hold on;        % Pista (Preto)
plot(T, Z_roda, 'g', 'LineWidth', 1.5);              % Roda (Verde)
plot(T, Z_carroceria, 'r', 'LineWidth', 2);          % Carroceria (Vermelho)

% Detalhes estéticos do gráfico
title('Desempenho da Suspensão: VW Gol em Pista ISO 8608 (Classe D)', 'FontSize', 14);
xlabel('Tempo (s)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Deslocamento Vertical (cm)', 'FontSize', 12, 'FontWeight', 'bold');
legend('Perfil da Pista (Zr)', 'Deslocamento da Roda (m)', 'Deslocamento da Carroceria (M)', 'Location', 'best');
grid on;
