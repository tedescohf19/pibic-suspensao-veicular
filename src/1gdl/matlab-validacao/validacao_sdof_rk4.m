clear;
clc;
close all;

%% ===============================================================
% DADOS DO SISTEMA
% ================================================================

m = 40;          % kg
k = 4e4;         % N/m
zeta = 0.02;     % taxa de amortecimento

F0 = 100;        % N
omega = 120;     % rad/s

x0 = 0;          % m
v0 = 0;          % m/s

%% ===============================================================
% PROPRIEDADES DINAMICAS
% ================================================================

wn = sqrt(k/m);
c = 2*zeta*m*wn;
wd = wn*sqrt(1-zeta^2);

fprintf('wn = %.8f rad/s\n',wn);
fprintf('wd = %.8f rad/s\n',wd);
fprintf('c  = %.8f N.s/m\n',c);

%% ===============================================================
% FORCA EXTERNA
% ================================================================

F = @(t) F0*cos(omega*t);

%% ===============================================================
% PARAMETROS DE INTEGRACAO
% ================================================================

t0 = 0;
tf = 5;
dt = 1e-3;

%% ===============================================================
% SOLUCAO NUMERICA POR RK4
% ================================================================

[t,x_rk4,v_rk4] = sdof_rk4(m,c,k,F,t0,tf,dt,x0,v0);

%% ===============================================================
% SOLUCAO EXATA
% ================================================================

X = F0 / sqrt((k-m*omega^2)^2 + (c*omega)^2);

phi = atan2(c*omega, k-m*omega^2);

% Constantes da resposta transiente
C1 = x0 - X*cos(phi);
vp0 = X*omega*sin(phi);
C2 = (v0 + zeta*wn*C1 - vp0)/wd;

% Resposta exata
x_exata = ...
    exp(-zeta*wn*t).* ...
    (C1*cos(wd*t) + C2*sin(wd*t)) ...
    + X*cos(omega*t - phi);

%% ===============================================================
% ERRO
% ================================================================

erro = x_rk4 - x_exata;
erro_max = max(abs(erro));
erro_rms = sqrt(mean(erro.^2));
erro_rel = erro_max / max(abs(x_exata));

fprintf('\n');
fprintf('Amplitude permanente = %.10e m\n',X);
fprintf('Amplitude permanente = %.6f mm\n',X*1000);
fprintf('Fase = %.8f rad\n',phi);
fprintf('Fase = %.6f graus\n',phi*180/pi);

fprintf('\n');
fprintf('C1 = %.10e m\n',C1);
fprintf('C2 = %.10e m\n',C2);

fprintf('\n');
fprintf('Erro maximo = %.10e m\n',erro_max);
fprintf('Erro RMS    = %.10e m\n',erro_rms);
fprintf('Erro relativo maximo = %.10e\n',erro_rel);

%% ===============================================================
% GRAFICO 1 - RESPOSTAS
% ================================================================

figure;
plot(t,x_exata*1000,'k-','LineWidth',1.5);
hold on;
plot(t,x_rk4*1000,'r--','LineWidth',1.0);
grid on;
box on;
xlabel('Tempo [s]');
ylabel('Deslocamento [mm]');
title('Comparacao: solucao exata x RK4');
legend('Solucao exata','RK4','Location','best');

%% ===============================================================
% GRAFICO 2 - ZOOM NO INICIO
% ================================================================

figure;
plot(t,x_exata*1000,'k-','LineWidth',1.5);
hold on;
plot(t,x_rk4*1000,'r--','LineWidth',1.0);
grid on;
box on;
xlim([0 0.5]);
xlabel('Tempo [s]');
ylabel('Deslocamento [mm]');
title('Comparacao no inicio da resposta');
legend('Solucao exata','RK4','Location','best');

%% ===============================================================
% GRAFICO 3 - ERRO
% ================================================================

figure;
plot(t,erro,'LineWidth',1.2);
grid on;
box on;
xlabel('Tempo [s]');
ylabel('Erro [m]');
title('Erro: RK4 - solucao exata');
