# Experimento de treinamento da expansão de 1 GDL

Configuração executável em [expansao_1gdl_v1.json](../experimentos/expansao_1gdl_v1.json). Implementação em [treinar_expansao_1gdl.py](../src/1gdl/mlp/treinar_expansao_1gdl.py).

## Dados e agregação

O banco contém 2.520 simulações, 60 sistemas e 10 famílias. Preserva as primeiras 1.260 simulações. Cada família tem um nominal e cinco variações de massa e rigidez, com fatores de até ±15%. Todas as simulações usam amortecimento relativo de 2%, 64 s, 512 Hz e condições iniciais nulas antes da aplicação da excitação.

| Excitação | Simulações | Condições após agregação |
|---|---:|---:|
| Degrau | 180 | 180 |
| Impulso | 180 | 180 |
| Ruído subressonante | 540 | 180 |
| Ruído ressonante | 540 | 180 |
| Ruído suprarressonante | 540 | 180 |
| Ruído de banda larga | 540 | 180 |
| Total | 2.520 | 1.080 |

A chave de agregação é `(grupo_origem, sistema_id, escala_ref_m, excitacao, banda)`. Calcula-se a média aritmética de cada indicador entre as três realizações de ruído. O desvio padrão amostral é exportado como `dp_...`. Condições determinísticas têm uma realização e desvio padrão ausente. A semente identifica a realização e permanece como metadado.

As três amplitudes por sistema se relacionam pela linearidade do modelo. Depois da normalização física, suas entradas são equivalentes. Cada família continua inteira na mesma partição. As 1.080 condições correspondem a 360 combinações de sistema e categoria, com três escalas cada. As três realizações de ruído também constituem uma estimativa amostral limitada da média.

## Grandezas que a rede ajusta

Defina `wn = sqrt(k/m)` em rad/s e `fn = wn/(2*pi)` em Hz. A escala S vale `F/k` para degrau, `F_RMS/k` para ruído e `J/(m*wn)` para impulso. Os quatro alvos são divididos por `S`, `S`, `S*wn` e `S*wn**2`. O treino usa o logaritmo decimal desses alvos adimensionais e normalizadores ajustados apenas nas famílias de treino.

As seis entradas são `log10(T*wn)`, `fmin/fn`, `fmax/fn` e os três indicadores de tipo de excitação. Para degrau e impulso, os limites de banda entram como zero. Massa, rigidez e intensidade são usadas nas transformações físicas. A reconstrução em unidades SI multiplica a previsão adimensional pelas mesmas escalas.

A rede preserva a arquitetura PyTorch 128–128–64 com SiLU do estudo anterior, com pesos novos. Usa AdamW, MSE nos alvos normalizados, lote 64, taxa inicial 0,003 e weight decay 0,0001. O limite é 300 épocas, com interrupção após 45 épocas sem nova melhor perda de validação. Um scheduler reduz a taxa após estagnação. Cada checkpoint contém pesos, parâmetros dos normalizadores, alvos, atributos e famílias da respectiva rodada.

## Avaliação

Cinco rodadas de GroupKFold. Em cada uma, duas famílias ficam para teste, duas para validação e seis para treino. A validação usa o próximo fold em ordem circular. Cada condição recebe uma previsão de teste uma vez, por um modelo que excluiu sua família. A seleção de época usa a validação. O baseline é a mediana dos alvos adimensionais em log por categoria nas famílias de treino.

As métricas MAPE, MAE, percentil 90 do erro percentual e R² usam as previsões reconstruídas no SI. São reportadas globalmente, por categoria e por família. A coluna `mediana_cv_ruido_pct` descreve a dispersão das três realizações do banco. Seu significado difere do erro preditivo da rede.

O protocolo mede generalização para famílias reservadas dentro do desenho numérico. A escolha de arquitetura e transformações é compartilhada entre rodadas. Novas escolhas orientadas pelos resultados desse teste requerem avaliação final adicional para estimar o desempenho da seleção de modelos.

## Duas execuções identificadas

O Colab de 12/11/2026 registrou MAPE de 5,60%, 4,10%, 4,48% e 4,36%, respectivamente, e ganho sobre o baseline em 11 de 24 combinações de alvo e categoria. A evidência local dessa execução é a captura, preservada junto aos notebooks históricos. O notebook local contém código e CSV embutido, com saídas vazias. A captura sustenta os números arredondados apresentados na conversa.

A revisão de 19/11/2026 executa o comando reproduzível com ambiente registrado e exporta as tabelas completas. Consulte o relatório dentro de `resultados/expansao_1gdl/revisao_20261119/`. Ao citar um número em um artigo, indique a execução correspondente. Resultados de ambientes diferentes devem ser comparados pelas tabelas de cada execução.

## Limites de aplicação e explicabilidade

A resposta é de um oscilador linear sob força aplicada à massa. O RMS inclui o transiente e, no degrau, o equilíbrio estático. Os picos são máximos amostrados a 512 Hz. No impulso ideal, a aceleração exportada é a parte regular após o salto de velocidade. O RMS de aceleração é bruto.

Para XAI, registre se a explicação tem como objeto os alvos adimensionais ou a função completa reconstruída no SI. A proporcionalidade com intensidade é incorporada pelas escalas físicas. Preserve os indicadores de excitação e os pares de limites de banda como combinações válidas. As quatro bandas discretas limitam inferências sobre varreduras contínuas. Analise os quatro alvos separadamente e referências retiradas do treino de cada rodada. A execução de XAI permanece pendente.
