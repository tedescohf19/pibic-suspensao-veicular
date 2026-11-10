# Expansão do banco de 1 GDL

O banco tem 1.260 novas simulações de um oscilador massa–mola–amortecedor com força externa. O gerador parte de 10 combinações distintas de massa e rigidez entre os casos de referência do banco harmônico. Para cada combinação, usa o sistema nominal e duas variações de massa e rigidez de até 15%, com amortecimento relativo fixo de 2%. São 30 sistemas e três níveis de excitação por sistema. As condições iniciais antes da aplicação da força são nulas.

## Excitações e resultados

A frequência natural é `f_n = √(k/m)/(2π)`. Para comparar as bandas de ruído, a força RMS é igual para a mesma combinação de sistema e escala. A escala de referência `s` vale 2, 5 ou 10 mm. No degrau, `F₀ = ks`. No impulso, `J = m(2π f_n)s`. No ruído, `F_RMS = ks`. Essas escalas são escolhas do estudo numérico e devem ser recalibradas para cargas representativas se o banco for usado para interpretar um veículo real.

| Excitação | Banda de entrada | Casos | Mediana de deslocamento RMS / escala | Mediana de pico de deslocamento / escala |
|---|---|---:|---:|---:|
| Degrau | Força constante após t = 0 | 90 | 1,00 | 1,94 |
| Impulso | Impulso ideal em t = 0 | 90 | 0,095 | 0,97 |
| Ruído subressonante | 0,25 a 0,75 × fₙ | 270 | 1,47 | 4,96 |
| Ruído em torno da ressonância | 0,75 a 1,25 × fₙ | 270 | 8,61 | 25,35 |
| Ruído suprarressonante | 1,25 a 2,50 × fₙ | 270 | 0,66 | 2,34 |
| Ruído de banda larga | 0,25 a 2,50 × fₙ | 270 | 4,11 | 13,00 |

O degrau oscila em torno do equilíbrio `F₀/k` e o RMS inclui esse deslocamento estático. O impulso gera o salto `J/m` na velocidade e uma oscilação livre amortecida. A aceleração registrada no caso de impulso é a aceleração regular após o salto, pois a parcela impulsiva ideal em t = 0 não tem pico nem RMS finito.

Para o ruído, o código gera amostras gaussianas brancas, retém os bins da banda indicada no CSV e ajusta o RMS da força. Há três sementes por família de origem, reutilizadas entre bandas e níveis para comparar o efeito de cada fator. Fixada a semente, a entrada e a resposta são reproduzíveis. A comparação acima é descritiva e usa a janela completa de 64 s, incluindo o transiente inicial. A análise por banda usa frequência em Hz na força aplicada; essa excitação não representa um perfil espacial de pista.

## Como os resultados foram verificados

- Todas as 1.260 linhas têm IDs únicos e seis alvos finitos. As bandas cobrem, considerando todos os sistemas, de 0,076 a 57,31 Hz. A frequência natural varia de 0,305 a 22,92 Hz.
- A resposta usa a solução analítica de degrau ou impulso. Para o ruído, calcula a resposta a cada componente de Fourier e soma o transiente que impõe as condições iniciais.
- Em 12 casos de verificação, cobrindo os extremos de frequência natural em cada tipo de excitação ou banda, o maior erro absoluto de deslocamento entre RK4 e a solução analítica, dividido pelo pico analítico do respectivo caso, foi de 0,183%. Para velocidade, foi de 0,178%.
- Nos mesmos casos, refinar a malha de 512 para 1.024 Hz alterou os picos em até 0,94% e os RMS em até 0,002%. Os picos no banco são máximos amostrados.

## Como reproduzir

Use Python com NumPy. Para gerar o banco, passe o caminho do CSV harmônico original como primeiro argumento.

```powershell
python gerar_banco_1gdl.py "caminho/do/dataset_completo_treinamento_suspensao_1dof.csv" banco_1gdl_excitacoes.csv
```

Para exportar uma série, passe o banco expandido e o ID do caso. O arquivo inclui tempo, força regular, deslocamento, velocidade e aceleração regular.

```powershell
python gerar_banco_1gdl.py banco_1gdl_excitacoes.csv exemplo.csv --serie G01-V0-A1-ruido-larga-1
```

O CSV tem uma linha por simulação. Campos de entrada vazios indicam que aquele parâmetro não se aplica à excitação. Para treinar um modelo sobre várias excitações, use como alvos comuns os picos e RMS que correspondam ao seu objetivo. A amplitude harmônica permanente `X_teor` não tem equivalente comum a todos os casos. Para avaliar generalização, separe os casos por `grupo_origem` e preserve essa separação também ao juntar dados harmônicos, pois os novos sistemas vieram dos mesmos casos de referência. Use a semente como metadado; se a previsão exigir a resposta de uma realização específica, forneça o sinal de força ou uma representação dele como entrada.
