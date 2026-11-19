# Auditoria técnica e organização de 19/11/2026

## Escopo e evidências

Revisão da árvore pública do GitHub no commit `09a22cf3eb329079d2b7cc44bbb77c7830e6748c`, dos nove CSVs agora integrados, dos scripts Python e MATLAB, dos três notebooks locais, do relatório técnico original e do plano individual disponíveis no espaço de trabalho. A árvore local original correspondia à árvore pública, embora tivesse um commit local diferente. Materiais excluídos pelo pesquisador foram mantidos fora do levantamento.

A revisão inclui leitura de código, conferência de dados, recálculo do banco expandido e nova execução integral do treino. MATLAB não foi executado nesta revisão. A revisão das referências registra seu papel e as lacunas de identificação; não constitui reprodução integral de cada trabalho citado.

## Achados e tratamento

| Achado | Evidência | Tratamento |
|---|---|---|
| GitHub desatualizado em relação ao Colab | README indicava expansão de 1.260 casos e treino pendente | Banco de 2.520, configuração, script, notebooks e resultados integrados |
| Risco de usar o arquivo errado no treino | Bancos harmônicos, expansão e 2 GDL possuem esquemas e alvos distintos | Roteiro de execução e conferência de SHA-256 do banco atual |
| Teste harmônico com origens compartilhadas | As 28 origens aparecem no treino, validação e referências | Identificado como estudo histórico; avisos de execução e títulos corrigidos |
| Confusão entre 2.520 simulações e exemplos de treino | Três realizações por condição de ruído | Exportadas 1.080 condições e dispersões. Documentadas as 360 combinações sistema/categoria e três escalas |
| MLP ajusta respostas normalizadas | Escalas físicas dependem de m, k e intensidade | Documentada a função completa e o que foi incorporado fisicamente |
| Portabilidade dos resultados do Colab | Pesos e tabelas estavam no armazenamento temporário | Nova execução local exportada com cinco checkpoints, tabelas e ambiente |
| Ganho frente ao baseline varia por categoria | MLP supera mediana em 11 de 24 combinações | Tabelas completas e limitações disponíveis para os artigos |
| Perfil ISO_8608 do lote 2 GDL é uma senoide | `gerador_perfil_pista.m` usa 0,05 sin(2π·0,5·x) e não recebe classe | Identificado como preliminar no roteiro e no próprio lote |
| J2 do lote MATLAB mede deflexão | `rms(z_u-z_r)` | Unidade documentada como m; alvo de força dinâmica requer k_t |
| RMS do lote 2 GDL usa saída adaptativa | `rms(accel_s)` sobre tempos do ode45 | Pendente reamostragem uniforme ou integração temporal e regeneração do banco |
| Relatório original descreve trajetórias, conforto normativo e ganho em microssegundos | Texto da capa e resumo ultrapassa as evidências exportadas | Matriz de afirmações para orientar a nova redação |
| Amortecimento fixo e condições iniciais nulas na expansão | Conferência de todas as linhas | Domínio explicitado. Novas condições requerem dados e avaliação próprios |
| XAI e comparação experimental ainda planejadas | Ausência de execução e tabelas correspondentes | Situação identificada no README e nos roteiros |

O relatório original é preservado como documento histórico. Sua capa indica erro RK4 inferior a 10⁻⁶ m, enquanto a tabela registra máximo próximo de 2,52×10⁻⁶ m. O R² 0,9994 da capa corresponde ao pico de deslocamento; a média dos cinco valores publicados é 0,9992. O rótulo de conforto requer ponderação e protocolo específicos. Essas observações já constavam parcialmente da metodologia e agora estão associadas às orientações de redação.

## Verificação numérica

- Nove CSVs registrados com SHA-256, número de linhas e esquema.
- 1.228 linhas no banco harmônico, com alvos equivalentes nas três partições e parâmetros derivados consistentes.
- 2.520 IDs únicos, 60 sistemas, 10 famílias e primeiras 1.260 linhas preservadas.
- Frequência natural entre aproximadamente 0,2983 e 22,9231 Hz na expansão atual.
- Os seis indicadores das 2.520 linhas foram recalculados. Maior diferença relativa observada de aproximadamente 5,77×10⁻¹³, atribuível à serialização e leitura numérica.
- O recálculo usa o mesmo gerador. A verificação independente com RK4 já arquivada cobre 12 extremos do banco anterior de 1.260 casos. Seu erro máximo normalizado de deslocamento foi aproximadamente 0,183%. A ampliação não recebeu uma nova campanha independente de RK4 nesta revisão.
- A geração em duas etapas foi comparada com os CSVs registrados, incluindo o gerador portátil das variantes V3–V5.
- O treinamento atual foi executado integralmente em cinco rodadas com famílias de teste e validação reservadas e exportação de todas as evidências.

O [relatório automatizado](../resultados/auditoria_20261119.json) registra as verificações de integridade. A aprovação dessas verificações cobre as verificações implementadas e convive com as pendências científicas listadas.

## Resultado da nova execução

| Alvo | MAPE de teste | R² de teste |
|---|---:|---:|
| Pico absoluto de deslocamento | 5,60% | 0,9853 |
| Deslocamento RMS | 4,10% | 0,9929 |
| Velocidade RMS | 4,48% | 0,9987 |
| Aceleração RMS | 4,36% | 0,9953 |

Os números arredondados reproduziram os exibidos no Colab de 12/11. A evidência completa desta revisão está no [relatório da execução](../resultados/expansao_1gdl/revisao_20261119/relatorio_mlp_1gdl.md), com métricas por categoria, família, previsões, ambiente e pesos. A MLP obteve menor MAPE geral que a referência simples nos quatro alvos. A mediana do treino foi superior em 13 das 24 combinações por categoria e alvo.

## Pendências que afetam novas conclusões

1. Revisar o gerador de pista de 2 GDL, registrar parâmetros espectrais e converter frequência espacial em temporal pela velocidade.
2. Recalcular os alvos de 2 GDL com unidades, janelas e amostragem definidas e identificar a procedência dos indicadores antigos.
3. Para estudar amortecimento, gerar variações de zeta e incluí-lo na representação da nova versão.
4. Para publicação, comparar a MLP com modelos interpretáveis usando as mesmas partições e medir o ganho computacional com benchmark equivalente.
5. Executar o protocolo externo e a análise XAI antes de apresentar seus resultados como concluídos.
6. Confirmar a edição e os enunciados de Rao, a identificação dos parâmetros veiculares e os metadados bibliográficos de cada fonte usada no artigo.

## Rastreabilidade da revisão

As versões do ambiente e o hash do script executado constam em `resultados/expansao_1gdl/revisao_20261119/proveniencia.json`. O script atual e a configuração geram saídas em novas pastas. Os notebooks históricos mantêm seus próprios códigos e bancos embutidos para identificar a etapa correspondente. A entrada atual do Colab baixa uma versão identificada do comando e do banco.
