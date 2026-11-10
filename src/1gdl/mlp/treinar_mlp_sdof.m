%% TREINAR_MLP_SDOF.M
% Script completo em MATLAB para:
% 1. Ler os bancos de dados (Treino = 1000, Validacao = 200, Teste Cego = 28 casos Rao)
% 2. Construir a matriz de atributos fisicos adimensionais e logaritmicos
% 3. Treinar uma Rede Neural Multilayer Perceptron (MLP / fitnet)
% 4. Avaliar MAPE e R^2 nos 28 casos do Rao e plotar graficos de paridade.
% Compativel com MATLAB R2016b ou superior (Deep Learning / Neural Network Toolbox).

clear; clc; close all;
rng(42); % Semente fixa para reprodutibilidade

%% 1. Carregar os Bancos de Dados CSV
T_train = readtable('banco_treino_1000.csv');
T_val   = readtable('banco_validacao_200.csv');
T_test  = readtable('banco_teste_cego_28_rao.csv');

% Juntar Treino (1000) + Validacao (200) para usar indices explicitos de divisao na fitnet
T_all = [T_train; T_val];
N_tr = height(T_train);
N_va = height(T_val);

%% 2. Funcao Auxiliar de Engenharia de Atributos Fisica
extrair_X = @(T) [ ...
    T.r, ...
    log10(T.r), ...
    0.5 * log10((1 - T.r.^2).^2 + (2 * 0.02 * T.r).^2), ...
    T.dst, ...
    log10(T.dst), ...
    T.wn, ...
    log10(T.wn), ...
    log10(T.w), ...
    T.x0, ...
    T.v0, ...
    abs(T.x0), ...
    abs(T.v0), ...
    1 - exp(-0.02 .* T.wn .* T.tf), ...
    log10(T.tf .* T.wn) ...
]'; % Transposto: [n_features x n_amostras] (padrao da Neural Network Toolbox)

% Alvos (Saidas Y em escala log10): [X_teor, Xmax_total, x_rms, v_rms, a_rms]
nomes_alvos = {'X_teor', 'Xmax_total', 'x_rms', 'v_rms', 'a_rms'};
extrair_Y_log = @(T) log10([T.X_teor, T.Xmax_total, T.x_rms, T.v_rms, T.a_rms])';

X_all = extrair_X(T_all);
Y_all = extrair_Y_log(T_all);

X_te  = extrair_X(T_test);
Y_te_real = [T_test.X_teor, T_test.Xmax_total, T_test.x_rms, T_test.v_rms, T_test.a_rms]';

%% 3. Configuracao e Treinamento da Rede Neural MLP (fitnet)
% Arquitetura com 3 camadas ocultas [64, 64, 32] e ativacao tangente hiperbolica (tansig)
hiddenSizes = [64, 64, 32];
net = fitnet(hiddenSizes, 'trainlm'); % Levenberg-Marquardt com regularizacao Bayesiana/Early Stopping

% Divisao estrita usando os 1000 casos de treino e 200 de validacao
net.divideFcn = 'divideind';
net.divideParam.trainInd = 1:N_tr;
net.divideParam.valInd   = (N_tr + 1):(N_tr + N_va);
net.divideParam.testInd  = [];

% Parametros de regularizacao contra overfitting
net.performParam.regularization = 1e-3;
net.trainParam.epochs = 300;
net.trainParam.max_fail = 15; % Early stopping na validacao
net.trainParam.showWindow = true;

% Treinar a rede
[net, tr] = train(net, X_all, Y_all);

%% 4. Predicao e Avaliacao nos 28 Casos do Rao (Teste Cego)
Y_pred_tr_real = 10 .^ net(X_all(:, 1:N_tr));
Y_pred_va_real = 10 .^ net(X_all(:, (N_tr+1):end));
Y_pred_te_real = 10 .^ net(X_te);

Y_tr_real = 10 .^ Y_all(:, 1:N_tr);
Y_va_real = 10 .^ Y_all(:, (N_tr+1):end);

fprintf('\n================ DESEMPENHO DA MLP NO MATLAB ================\n');
for i = 1:numel(nomes_alvos)
    mape_tr = mean(abs((Y_tr_real(i,:) - Y_pred_tr_real(i,:)) ./ Y_tr_real(i,:))) * 100;
    mape_va = mean(abs((Y_va_real(i,:) - Y_pred_va_real(i,:)) ./ Y_va_real(i,:))) * 100;
    mape_te = mean(abs((Y_te_real(i,:) - Y_pred_te_real(i,:)) ./ Y_te_real(i,:))) * 100;
    
    ss_res = sum((Y_te_real(i,:) - Y_pred_te_real(i,:)).^2);
    ss_tot = sum((Y_te_real(i,:) - mean(Y_te_real(i,:))).^2);
    r2_te = 1 - ss_res / ss_tot;
    
    fprintf('%-12s | Treino MAPE: %5.2f%% | Val MAPE: %5.2f%% | Teste Cego (28 Rao) MAPE: %5.2f%% (R2 = %.4f)\n', ...
            nomes_alvos{i}, mape_tr, mape_va, mape_te, r2_te);
end

%% 5. Graficos de Convergencia e Paridade
figure('Name','Resultados MLP - SDOF Suspensao','Position',[100 100 1100 800]);

subplot(2,2,1);
semilogy(0:tr.num_epochs, tr.perf, 'b-', 'LineWidth', 1.5); hold on;
semilogy(0:tr.num_epochs, tr.vperf, 'r--', 'LineWidth', 1.5);
grid on; box on;
xlabel('Epoca'); ylabel('MSE Loss (escala log)');
title('Convergencia do Treinamento (Sem Overfitting)');
legend('Treino (1000)', 'Validacao (200)', 'Location', 'best');

subplot(2,2,2);
loglog(Y_va_real(2,:)*1e3, Y_pred_va_real(2,:)*1e3, 'o', 'Color', [0.9 0.5 0], 'MarkerSize', 5); hold on;
loglog(Y_te_real(2,:)*1e3, Y_pred_te_real(2,:)*1e3, 'r^', 'MarkerFaceColor', 'r', 'MarkerSize', 7);
loglog([0.1 3500], [0.1 3500], 'k--', 'LineWidth', 1.2);
grid on; box on;
xlabel('Max|x| Real (RK4) [mm]'); ylabel('Max|x| Previsto (MLP) [mm]');
title('Paridade: Deslocamento Maximo Total');
legend('Validacao', '28 Casos Rao', 'Ideal (y=x)', 'Location', 'northwest');

subplot(2,2,3);
loglog(Y_va_real(3,:)*1e3, Y_pred_va_real(3,:)*1e3, 'bo', 'MarkerSize', 5); hold on;
loglog(Y_te_real(3,:)*1e3, Y_pred_te_real(3,:)*1e3, 'r^', 'MarkerFaceColor', 'r', 'MarkerSize', 7);
loglog([0.08 2500], [0.08 2500], 'k--', 'LineWidth', 1.2);
grid on; box on;
xlabel('x_{RMS} Real (RK4) [mm]'); ylabel('x_{RMS} Previsto (MLP) [mm]');
title('Paridade: Deslocamento RMS');
legend('Validacao', '28 Casos Rao', 'Ideal (y=x)', 'Location', 'northwest');

subplot(2,2,4);
loglog(Y_va_real(5,:), Y_pred_va_real(5,:), 'go', 'MarkerSize', 5); hold on;
loglog(Y_te_real(5,:), Y_pred_te_real(5,:), 'r^', 'MarkerFaceColor', 'r', 'MarkerSize', 7);
loglog([0.02 2500], [0.02 2500], 'k--', 'LineWidth', 1.2);
grid on; box on;
xlabel('a_{RMS} Real (RK4) [m/s^2]'); ylabel('a_{RMS} Previsto (MLP) [m/s^2]');
title('Paridade: Aceleracao RMS (Conforto)');
legend('Validacao', '28 Casos Rao', 'Ideal (y=x)', 'Location', 'northwest');

% Salvar modelo treinado
save('modelo_mlp_suspensao_1dof.mat', 'net', 'tr', 'nomes_alvos');
