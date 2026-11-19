# PIBIC · Resultado da MLP de 1 GDL

O estudo usou 2.520 simulações, 60 configurações e 10 famílias. Após a média das três realizações de ruído por condição, ficaram 1.080 condições, com 180 por categoria. Todas as condições tiveram uma previsão de teste feita por uma rede treinada sem a sua família.

| Indicador | MAPE MLP | MAPE mediana | R² MLP |
|---|---:|---:|---:|
| Pico absoluto de x | 5.60% | 6.99% | 0.9853 |
| RMS de x | 4.10% | 8.55% | 0.9929 |
| RMS de v | 4.48% | 14.56% | 0.9987 |
| RMS de a | 4.36% | 14.68% | 0.9953 |

A MLP teve MAPE menor que a mediana do treino em **11 de 24** combinações de categoria e indicador. O maior MAPE por categoria foi **8.95%**, para **Pico absoluto de x** em **Banda larga**.

A maior dispersão relativa mediana entre as três realizações foi **10.55%**, para **Pico absoluto de x** em **Banda larga**. Esse número é um coeficiente de variação amostral, calculado dentro de cada condição.

Os resultados valem para o oscilador linear simulado com amortecimento de 2%, condições iniciais nulas e quatro bandas fixadas em relação à frequência natural. A referência é a solução do simulador. A aplicação a medições físicas, outras taxas de amortecimento ou um modelo de 2 GDL exigirá nova avaliação.
