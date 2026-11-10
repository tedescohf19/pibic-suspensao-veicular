# Metodologia e leitura dos resultados

## Oscilador de 1 GDL

O sistema é um oscilador massa–mola–amortecedor sob força externa, dado por m x″ + c x′ + k x = F(t). O estado contém deslocamento e velocidade. A aceleração vem da equação de equilíbrio. O estudo fixa o amortecimento relativo em 2%. A [implementação MATLAB](../src/1gdl/matlab-rao/) compara o RK4 com a solução analítica usando casos de excitação harmônica de Rao adaptados a esse amortecimento.

O banco harmônico contém 1.000 simulações de treino, 200 de validação e 28 casos de referência. A rede PyTorch recebe 14 atributos, incluindo razão de frequência, frequência natural, impedância e condições iniciais. Tem três camadas ocultas de 128, 128 e 64 neurônios, usa SiLU e AdamW e treina por 450 épocas. Ajusta os normalizadores no treino e restaura os pesos da época de menor perda de validação.

## Leitura dos resultados publicados

Os números abaixo vêm do [relatório técnico original](relatorio-tecnico-original.pdf). O treinamento original não foi repetido durante a montagem deste repositório.

| Alvo | MAPE na validação | MAPE nos 28 casos | R² nos 28 casos |
|---|---:|---:|---:|
| Amplitude em regime permanente | 2,88% | 1,90% | 0,9995 |
| Pico de deslocamento | 4,99% | 1,89% | 0,9994 |
| Deslocamento RMS | 5,34% | 1,77% | 0,9993 |
| Velocidade RMS | 4,21% | 2,11% | 0,9991 |
| Aceleração RMS | 4,17% | 2,38% | 0,9989 |

- A MLP retorna indicadores por simulação. A solução física produz a trajetória no tempo. Um ganho de velocidade da MLP precisa de uma medição comparável com o cálculo físico dos mesmos indicadores.
- Todos os 28 casos aparecem como origem de variações no treino e na validação. A rede ainda precisa ser avaliada em famílias reservadas.
- O maior erro de deslocamento registrado na tabela RK4 é aproximadamente 2,52 × 10⁻⁶ m. A capa do relatório afirma valor inferior a 10⁻⁶ m. O valor 0,9994 é o R² do pico de deslocamento. A média dos cinco valores na avaliação é 0,9992.
- A curva de validação estabiliza enquanto a perda de treino continua caindo. O título “Sem overfitting” da figura deve ser lido com essa limitação. O RMS de aceleração é bruto. Uma avaliação pela ISO 2631-1 precisa de ponderação em frequência e condições de medição compatíveis.

## Expansão em 1 GDL

O [gerador Python](../src/1gdl/expansao/) usa solução analítica para degrau e impulso. Para o ruído limitado em banda, resolve a resposta a cada componente de Fourier e acrescenta o transiente que satisfaz as condições iniciais. Veja o [desenho do experimento e a conferência com RK4](expansao-1gdl.md).

## Protótipo de quarto de veículo em 2 GDL

A mola e o amortecedor conectam a carroceria à roda. A rigidez do pneu liga a roda ao deslocamento da pista. O protótipo usa integração por ODE45 e tem um banco de 5.000 configurações.

No lote arquivado, o perfil rotulado ISO_8608 usa uma senoide fixa e ignora o valor de classe. J2_Simulado_MATLAB é a deflexão do pneu em metros. A força dinâmica do pneu no modelo linear é a deflexão multiplicada pela rigidez do pneu, em newtons. O RMS do lote é calculado diretamente nas amostras adaptativas do ODE45. A revisão deve usar amostragem uniforme ou integração no tempo.

A etapa seguinte deve gerar perfis com densidade espectral documentada, conferir as unidades e definir janelas. Os alvos propostos são aceleração RMS da carroceria, curso máximo da suspensão e força dinâmica RMS no pneu. Reserve realizações completas da pista antes de gerar as variações de treino.

O plano individual integra a frente de metamodelagem do LABSISCO/UnB. Classificação de pista e controle semiativo por imitação fazem parte do projeto mais amplo do laboratório.
