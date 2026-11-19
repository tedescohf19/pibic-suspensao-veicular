# Organização e roteiro de execução

Esta organização foi revisada em 19/11/2026. A etapa de 1 GDL prepara os procedimentos de geração de dados e metamodelagem previstos para o quarto de veículo de 2 GDL no plano individual.

## Qual estudo executar

| Estudo | Entradas físicas | Alvos da rede | Situação |
|---|---|---|---|
| Harmônico histórico | Força harmônica aplicada à massa, condições iniciais variáveis | Amplitude permanente, pico de x e RMS de x, v e a | Resultado histórico com famílias compartilhadas |
| Expansão 1 GDL v1 | Força degrau, impulso e ruído limitado em banda, condições iniciais nulas | Pico absoluto de x e RMS de x, v e a | Experimento configurado e reproduzível |
| Quarto de veículo 2 GDL | Deslocamento da pista na base do pneu | Critérios ainda em revisão no banco preliminar | Revisão do gerador e dos alvos necessária |
| XAI | Previsões e entradas do experimento escolhido | Importâncias e explicações por alvo | Proposta metodológica, execução pendente |

## Estrutura

- `dados/` guarda os CSVs de referência. Seus nomes, contagens, colunas e hashes constam em [manifesto_dados.json](../experimentos/manifesto_dados.json).
- `experimentos/` identifica a versão do banco, a arquitetura, as sementes e a estratégia de avaliação.
- `src/1gdl/expansao/` gera os bancos e reconstrói as séries.
- `src/1gdl/mlp/treinar_expansao_1gdl.py` executa o experimento atual. O script `treinar_mlp_sdof.py` reproduz a etapa harmônica histórica.
- `notebooks/` oferece a entrada no Colab. `notebooks/historico/` preserva os notebooks anteriores e os links de execução registrados.
- `resultados/` guarda evidências versionadas com identificação da execução.
- `gerados/` recebe cada nova execução, incluindo pesos e dados intermediários. A pasta fica fora do Git.
- `docs/` descreve os métodos, as limitações e a relação entre afirmações e evidências para os artigos.

## Executar o treinamento atual

Use um ambiente Python próprio e instale [requirements-mlp.txt](../requirements-mlp.txt). O ambiente registrado da revisão está em `resultados/expansao_1gdl/revisao_20261119/ambiente.txt`. As versões exatas dessa execução servem para reproduzir seu resultado, considerando também plataforma e hardware.

```powershell
python -m pip install -r requirements-mlp.txt
python scripts/verificar_projeto.py
python src/1gdl/mlp/treinar_expansao_1gdl.py
```

Cada execução recebe uma pasta com data e hora. Para nomear uma execução, passe `--saida gerados/meu_experimento`. A saída deve estar vazia. O comando confere o SHA-256 do CSV configurado e rejeita um banco diferente.

Os arquivos de saída incluem condições agregadas, previsões de teste, partições por família, métricas por categoria e por família, curvas, gráficos, cinco checkpoints e proveniência com versões e hashes. O ZIP fica ao lado da pasta da execução. Guarde ambos antes de encerrar uma sessão temporária do Colab.

## Reproduzir a geração dos dados

```powershell
New-Item -ItemType Directory -Force gerados | Out-Null
python src/1gdl/expansao/gerar_banco_1gdl.py dados/1gdl/harmonico/dataset_completo_treinamento_suspensao_1dof.csv gerados/banco_1260.csv
python src/1gdl/expansao/ampliar_banco_1gdl.py dados/1gdl/harmonico/dataset_completo_treinamento_suspensao_1dof.csv gerados/banco_1260.csv gerados/banco_2520.csv
python scripts/verificar_projeto.py --recalcular
```

A conferência com `--recalcular` lê o banco registrado e recalcula os seis indicadores de todas as 2.520 linhas. A equivalência entre a saída dos geradores e o banco registrado também foi verificada na revisão.

## Preparar uma nova versão

Alterações de amortecimento, janelas, entradas, bandas ou estratégia de divisão devem receber uma configuração e uma execução próprias. Recalcule as respostas ao mudar parâmetros físicos. Registre a procedência de cada novo banco antes de incorporá-lo ao treino.

Ao combinar excitações harmônicas e da expansão, reconstrua o agrupamento a partir dos casos Rao comuns. Os grupos das duas etapas têm a mesma origem física. A amplitude permanente `X_teor` pertence à etapa harmônica. A avaliação conjunta requer uma nova versão do experimento.
