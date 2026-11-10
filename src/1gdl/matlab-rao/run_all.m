%% RUN_ALL  Roda todos os problemas e grava a base de dados (CSV + MAT).
clear; clc; close all;

res = [prob_img_40kg(false), prob_3_01(false), prob_3_03(false), ...
       prob_3_04(false), prob_3_05(false), prob_3_06(false), ...
       prob_3_07(false), prob_3_08(false), prob_3_09(false), ...
       prob_3_11(false), prob_3_12(false), prob_3_14(false), ...
       prob_3_15(false), prob_3_26(false), prob_3_27(false), ...
       prob_3_28(false), prob_3_29(false)];

campos = {'m','c','k','F0','w','x0','v0','wn','zeta','r','dst', ...
          'X_teor','phi_deg','Xmax_total','X_rk4_perm','erro_max','tf','dt'};

fid = fopen('base_dados_vibracoes.csv','w');
fprintf(fid,'id,%s\n',strjoin(campos,','));
for i = 1:numel(res)
    fprintf(fid,'%s',res(i).id);
    for j = 1:numel(campos)
        fprintf(fid,',%.10g',res(i).(campos{j}));
    end
    fprintf(fid,'\n');
end
fclose(fid);
save('base_dados_vibracoes.mat','res');
fprintf('\n%d casos gravados em base_dados_vibracoes.csv / .mat\n', numel(res));
