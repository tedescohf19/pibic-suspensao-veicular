# Dicionário dos dados

| Pasta | Conteúdo | Cada linha representa |
|---|---|---|
| [1 GDL harmônico](../dados/1gdl/harmonico/) | CSV consolidado, três partições lidas pela MLP e tabela RK4 | Uma simulação |
| [1 GDL expansão](../dados/1gdl/expansao/) | Degrau, impulso e ruído branco filtrado em quatro bandas | Uma simulação |
| [2 GDL](../dados/2gdl/) | CSV base e versão com saídas adicionais do lote MATLAB | Uma configuração preliminar |

## 1 GDL harmônico

Massa em kg, rigidez em N/m, amortecimento em N·s/m, amplitude de força em N, frequência angular em rad/s, condições iniciais em m e m/s e tempo em segundos. Os cinco alvos são a amplitude permanente e o pico de deslocamento em m e o RMS de deslocamento em m, velocidade em m/s e aceleração em m/s². Os valores numéricos do consolidado correspondem aos três bancos separados, com nomes de colunas diferentes. A tabela base_dados_vibracoes_2pct.csv documenta a comparação entre RK4 e solução analítica e fica separada das três partições.

## 1 GDL expansão

id_simulacao identifica cada linha. grupo_origem associa o sistema nominal às suas variações. sistema_id distingue os sistemas do mesmo grupo. excitacao, banda, semente_ruido e limites em Hz descrevem a entrada. Os níveis de entrada estão em N para degrau e RMS de ruído e em N·s para impulso.

Cada RMS usa a janela de 64 s. Cada pico é o maior valor absoluto da malha a 512 Hz. A aceleração do impulso corresponde à parte regular após o salto. Campos vazios indicam parâmetros que não se aplicam. O gerador reconstrói os sinais a partir do ID. A semente é metadado. Para estimar o resultado de uma realização específica de ruído, use o sinal de entrada ou atributos que o representem.

Separe treino e teste por família de origem. Ao juntar os bancos, mantenha também as famílias de origem comuns dos dois estudos no mesmo conjunto. A amplitude harmônica permanente X_teor não é um alvo comum a todas as entradas.

## 2 GDL preliminar

O CSV base contém massas, rigidezes, amortecimento, velocidade, perfil, classe e indicadores. O CSV pronto_para_MLP acrescenta J1_Simulado_MATLAB e J2_Simulado_MATLAB. As colunas de indicadores têm origens distintas e precisam ser harmonizadas antes do treino. Veja a [metodologia de 2 GDL](metodologia.md#protótipo-de-quarto-de-veículo-em-2-gdl).
