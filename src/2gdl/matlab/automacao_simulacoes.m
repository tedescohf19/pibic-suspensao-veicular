% automacao_simulacoes.m
clear; clc;

% 1. Carregar o ficheiro completo diretamente pelo código
disp('A carregar o ficheiro CSV...');
opts = detectImportOptions('dataset_suspensao_completo.csv');
dados = readtable('dataset_suspensao_completo.csv', opts);

num_amostras = height(dados);

% Criar vetores limpos para os NOVOS J1 e J2 que vamos calcular
J1_NOVOS_RMS = zeros(num_amostras, 1);
J2_NOVOS_RMS = zeros(num_amostras, 1);

tspan = [0 5]; 
z0 = [0; 0; 0; 0]; 

disp('Iniciando as simulações em lote. Isso pode levar alguns minutos...');
tic; 

for i = 1:num_amostras
    % O código lê APENAS as colunas 1 a 12 (ignora os Js antigos durante o cálculo)
    Ms = dados.M_s(i);
    mu = dados.m_u(i);
    ks = dados.k_s(i);
    cs = dados.c_s(i);
    kt = dados.k_t(i);
    vel_ms = dados.Velocidade_kmh(i) / 3.6; 
    perfil = string(dados.Perfil_Pista{i});
    
    [t_out, z_out] = ode45(@(t, z) modelo_quarto_veiculo(t, z, Ms, mu, ks, cs, kt, vel_ms, perfil), tspan, z0);
    
    num_passos = length(t_out);
    accel_s = zeros(num_passos, 1);
    deflexao_pneu = zeros(num_passos, 1);
    
    for k = 1:num_passos
        zr = gerador_perfil_pista(t_out(k), vel_ms, perfil);
        F_mola = ks * (z_out(k,1) - z_out(k,3));
        F_amort = cs * (z_out(k,2) - z_out(k,4));
        
        accel_s(k) = (-F_mola - F_amort) / Ms;
        deflexao_pneu(k) = z_out(k,3) - zr; 
    end
    
    % Guarda os novos valores
    J1_NOVOS_RMS(i) = rms(accel_s);
    J2_NOVOS_RMS(i) = rms(deflexao_pneu);
    
    if mod(i, 500) == 0
        fprintf('Processado %d de %d amostras...\n', i, num_amostras);
    end
end

tempo_total = toc; 

% 2. Opcional: Se quiser, podemos renomear as colunas velhas para não haver confusão
try
    dados.Properties.VariableNames{'J1_Conforto'} = 'J1_Antigo';
    dados.Properties.VariableNames{'J2_Seguranca'} = 'J2_Antigo';
catch
    % Se as colunas não existirem com este nome, ignora
end

% 3. Adicionar as NOVAS colunas calculadas ao dataset
dados.J1_Simulado_MATLAB = J1_NOVOS_RMS;
dados.J2_Simulado_MATLAB = J2_NOVOS_RMS;

writetable(dados, 'dataset_pronto_para_MLP.csv');

fprintf('\nSimulação finalizada!\nTempo total de integração (Benchmark): %.2f segundos.\n', tempo_total);
disp('O arquivo "dataset_pronto_para_MLP.csv" foi criado com sucesso.');