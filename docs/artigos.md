# Evidências para redação dos artigos

Cada resultado citado deve identificar banco, versão da configuração, divisão, execução e unidade. Os números de uma rodada ou de um estudo devem ser atribuídos ao mesmo conjunto de evidências.

## Formulações sustentadas pelos arquivos

| Afirmação | Evidência e alcance |
|---|---|
| Foi gerado um banco de 2.520 simulações de 1 GDL | CSV registrado, geradores e auditoria de todas as linhas |
| A MLP prevê quatro indicadores por condição | Código, alvos da configuração e tabelas de previsões |
| A expansão foi avaliada por famílias reservadas | Partições e previsões fora do treino nas cinco rodadas |
| As métricas harmônicas são uma prova de conceito histórica | Relatório original e partições com 28 origens compartilhadas |
| A resposta do simulador foi conferida numericamente | Comparação solução analítica/RK4 em 12 extremos do banco de 1.260 casos, com métrica definida |
| A expansão de 2.520 casos foi reproduzida | Auditoria com recálculo de todos os seis indicadores. Esta verificação usa o próprio gerador |
| A bancada externa é uma etapa planejada | Protocolo de comparação experimental e referências |
| O material de 2 GDL constitui protótipo | Scripts e CSVs preliminares com pendências identificadas |

## Afirmações que exigem evidência adicional

- Predição da trajetória completa `x(t)`, `v(t)`, `a(t)` exige saídas temporais ou uma reconstrução temporal avaliada. A MLP atual retorna indicadores por simulação.
- Ganho de velocidade exige benchmark do simulador e da rede para os mesmos indicadores, no mesmo ambiente, com aquecimento e repetições documentados.
- Avaliação de conforto segundo ISO 2631-1 exige um protocolo e ponderações compatíveis. O banco atual contém aceleração RMS bruta.
- Classes de pista segundo ISO 8608 exigem geração e verificação espectral documentadas. A função histórica `ISO_8608` no lote 2 GDL implementa uma senoide e ignora a classe.
- Validação experimental exige medições externas e comparação efetivamente executada, com parâmetros de ajuste e avaliação separados.
- Generalização para outro amortecimento exige dados e testes que cubram esse parâmetro. O estudo atual fixa 2%.
- Ausência de sobreajuste exige análise das curvas e dos erros reservados. O título da figura histórica, por si só, não sustenta essa conclusão.
- Uma importância SHAP representa atribuições relativas ao modelo, à escala de saída e à referência escolhida. Interpretação causal exige suporte físico ou experimental adicional.

## Identificação de modelos e unidades

No texto, descreva o modelo de 1 GDL como oscilador massa–mola–amortecedor sob força aplicada. O quarto de veículo de 2 GDL recebe deslocamento na base do pneu. Hz e rad/s devem acompanhar a frequência correspondente.

Em 2 GDL, o alvo `J2_Simulado_MATLAB` histórico é RMS da deflexão do pneu em metros. A força dinâmica do pneu requer multiplicação por `k_t`, com unidade N. O RMS em amostras adaptativas de ODE45 exige ponderação temporal ou reamostragem uniforme. Os alvos antigos do CSV base têm procedência computacional ainda a documentar.

## Relação com o plano individual

O plano prevê metamodelagem de suspensão passiva de quarto de veículo em 2 GDL, variação de rigidez e amortecimento e entradas de pista. A etapa de 1 GDL é preparatória. A implementação atual usa PyTorch/AdamW e soluções analíticas/Fourier para os dados de 1 GDL. O plano menciona Keras/Adam e integração RK4 para a implementação futura de quarto de veículo. Essa evolução metodológica deve ser explicitada no relatório.

Para submeter um artigo, complete autores, orientadora, afiliações, edição de Rao utilizada, identificação de parâmetros do veículo, referência dos dados e limitações. O relatório original contém campos genéricos de autoria e orientador. Declare o apoio de ferramentas de IA na programação e redação conforme a política efetivamente aplicável à instituição e ao veículo de publicação, com revisão humana dos resultados.
