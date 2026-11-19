# Dados preliminares do quarto de veículo

Os dois CSVs contêm 5.000 configurações. O nome histórico `dataset_pronto_para_MLP.csv` identifica o arquivo produzido pelo lote MATLAB.

A revisão identificou três pendências que afetam o uso dos alvos no treinamento. O perfil `ISO_8608` é uma senoide e ignora a classe. O campo `J2_Simulado_MATLAB` é RMS de deflexão em metros. O RMS dos sinais é calculado sem ponderação temporal sobre amostras adaptativas do ODE45.

O banco base contém indicadores cuja rotina geradora ainda precisa ser identificada. A comparação com o CSV MATLAB mostra que as entradas e os indicadores base foram preservados, com acréscimo de duas saídas.

O próximo banco de treinamento de 2 GDL deverá registrar gerador de pista, semente, classe, velocidade, janela, amostragem e unidade de cada alvo. Os critérios propostos e o estado da revisão estão na [metodologia](../../docs/metodologia.md) e na [auditoria](../../docs/auditoria-2026-11-19.md).
