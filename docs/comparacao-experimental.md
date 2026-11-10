# Protocolo de comparação com dados externos

## 1 GDL

Comece pelo ensaio de baixa amplitude do [Orion Beam Dataset](https://doi.org/10.17632/p4fg6snh3r.1). O ensaio usa ruído branco limitado a 10–2.000 Hz, força medida por célula de carga e velocidade medida por vibrometria. O [artigo dos dados](https://pmc.ncbi.nlm.nih.gov/articles/PMC8633856/) descreve o protocolo.

1. Escolha um canal e uma ressonância isolada.
2. Compare a resposta experimental velocidade/força com a do oscilador perto desse modo. Compare frequência do pico, largura de banda e magnitude. Para comparar a forma das curvas, normalize a frequência por f/fₙ.
3. Se ajustar parâmetros modais, use outra medição para avaliar o ajuste e registre a faixa, os canais e as unidades.

Os [ensaios de impacto da UnB](https://pmc.ncbi.nlm.nih.gov/articles/PMC10828560/) oferecem magnitude e fase de acelerância para uma comparação modal. Para degrau, o [experimento do MIT](https://ocw.mit.edu/courses/2-003-modeling-dynamics-and-control-i-spring-2005/pages/labs/lab_4/) documenta o protocolo de bancada. Falta selecionar uma série medida de degrau. Estas comparações ainda não foram executadas.

## 2 GDL

O [benchmark Foo–Tan](https://doi.org/10.5281/zenodo.17242919) oferece perfis baseados na ISO 8608 e deslocamentos da carroceria e do pneu medidos em bancada. O arquivo publicado é suspension_dataset.mat. Confirme as unidades, a amostragem e o alinhamento temporal antes de aplicar a mesma entrada ao quarto de veículo. Compare deslocamentos no mesmo intervalo. A força no pneu e a aceleração exigem medições compatíveis ou um método de estimação documentado.
