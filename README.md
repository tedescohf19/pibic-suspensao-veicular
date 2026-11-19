# PIBIC · Predição da resposta dinâmica de suspensão veicular

O projeto desenvolve metamodelos neurais para suspensão passiva. A etapa atual usa um oscilador de 1 GDL sob força aplicada para organizar a geração de dados e o treinamento. O objetivo do plano individual é chegar ao quarto de veículo de 2 GDL, excitado por deslocamento da pista.

**Para executar o treino atual, comece pelo [roteiro de organização](docs/organizacao.md).** Para redigir, use a [relação entre afirmações e evidências](docs/artigos.md). A [auditoria de 19/11/2026](docs/auditoria-2026-11-19.md) registra o que foi verificado e as pendências.

| Estudo | Banco | Situação |
|---|---|---|
| Harmônico histórico de 1 GDL | 1.228 simulações e cinco indicadores | Prova de conceito com origens compartilhadas entre partições |
| Expansão de 1 GDL v1 | 2.520 simulações, 60 sistemas, 10 famílias | Treino reproduzido e avaliado em cinco rodadas por família |
| Quarto de veículo de 2 GDL | 5.000 configurações preliminares | Revisão do gerador de pista e dos alvos necessária |
| XAI | Proposta aplicada à representação atual | Implementação e avaliação pendentes |
| Comparação experimental | Fontes e protocolo selecionados | Execução pendente |

## Treinamento atual

O banco de 2.520 casos inclui 180 degraus, 180 impulsos e 540 realizações em cada uma de quatro bandas de ruído. A média das três realizações por condição produz 1.080 condições. A MLP estima pico absoluto de deslocamento e RMS de deslocamento, velocidade e aceleração. Os alvos usam a janela completa de 64 s. A aceleração RMS é bruta e, no impulso, corresponde à parte regular após o salto de velocidade.

Em cada rodada, seis famílias são usadas para treino, duas para validação e duas para teste. A rede ajusta alvos adimensionais em log e as previsões são reconstruídas no SI. A intensidade participa das escalas físicas. A arquitetura PyTorch tem camadas 128–128–64 e SiLU.

| Indicador | MAPE de teste, revisão de 19/11 | MAPE do baseline |
|---|---:|---:|
| Pico absoluto de deslocamento | 5,60% | 6,99% |
| Deslocamento RMS | 4,10% | 8,55% |
| Velocidade RMS | 4,48% | 14,56% |
| Aceleração RMS | 4,36% | 14,68% |

A MLP supera a mediana do treino no resultado geral dos quatro indicadores e em 11 de 24 combinações de categoria e alvo. As tabelas completas, cinco checkpoints, figuras e ambiente estão em [resultados da revisão](resultados/expansao_1gdl/revisao_20261119/relatorio_mlp_1gdl.md). Consulte a [metodologia do treino](docs/treinamento-expansao.md) para interpretar as escalas, a dispersão do ruído e os limites de generalização.

## Executar

Use Python 3.11 ou mais recente. A revisão foi executada em Python 3.12, CPU, com versões registradas no ambiente da execução. Na raiz do repositório execute

```powershell
python -m pip install -r requirements-mlp.txt
python scripts/verificar_projeto.py
python src/1gdl/mlp/treinar_expansao_1gdl.py
```

O comando lê a configuração e confere o hash do CSV. Cada execução grava tabelas, gráficos, proveniência, cinco modelos e um ZIP em uma nova pasta dentro de `gerados/`. Essa pasta fica fora do Git. O [notebook atual](notebooks/treino_expansao_1gdl.ipynb) oferece a mesma entrada no Colab.

Para recalcular os seis indicadores de todas as simulações e conferir os CSVs execute

```powershell
python scripts/verificar_projeto.py --recalcular
```

## Arquivos e rastreabilidade

- [Organização, geração de dados e comandos por etapa](docs/organizacao.md)
- [Configuração do experimento atual](experimentos/expansao_1gdl_v1.json)
- [Manifesto dos nove CSVs com hashes e esquemas](experimentos/manifesto_dados.json)
- [Dicionário dos dados](docs/dados.md)
- [Metodologia e leitura crítica do estudo harmônico e de 2 GDL](docs/metodologia.md)
- [Geração e verificação do banco inicial de 1.260 casos](docs/expansao-1gdl.md)
- [Protocolo de comparação experimental](docs/comparacao-experimental.md)
- [Referências e papel de cada fonte](docs/referencias.md)
- [Notebooks e capturas históricas](notebooks/historico/README.md)
- [Relatório técnico original](docs/relatorio-tecnico-original.pdf)

O relatório e a figura harmônica registram uma etapa anterior. As 28 origens dos casos Rao aparecem no treino e na validação desse estudo. Os modelos MATLAB e PyTorch históricos usam arquiteturas diferentes. O banco de 2 GDL tem pendências identificadas junto aos arquivos. Livros, artigos e normas são creditados por referência à fonte, com os parâmetros e protocolos a conferir na redação de cada artigo.
