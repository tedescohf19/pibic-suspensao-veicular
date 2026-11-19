from pathlib import Path
import json


"""Treino reproduzível da expansão de 1 GDL. Execute --help para os caminhos."""
import argparse
import sys
from datetime import datetime, timezone

RAIZ = Path(__file__).resolve().parents[3]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--config', type=Path, default=RAIZ / 'experimentos/expansao_1gdl_v1.json')
parser.add_argument('--saida', type=Path, default=RAIZ / 'gerados' / ('expansao_' + datetime.now().strftime('%Y%m%d_%H%M%S_%f')))
args = parser.parse_args()
config = json.loads(args.config.read_text(encoding='utf-8'))
if config['id'] != 'expansao_1gdl_v1' or config['versao'] != 1:
    raise ValueError('Este comando executa a configuração expansao_1gdl_v1, versão 1.')
if config['arquitetura'] != [128, 128, 64] or config['alvos'] != ['x_pico_abs_m', 'x_rms_m', 'v_rms_m_s', 'a_rms_m_s2']:
    raise ValueError('Arquitetura e alvos incompatíveis com a implementação v1.')
if config['n_rodadas'] != 5 or config['ativacao'] != 'SiLU' or config['split'] != 'GroupKFold_teste_e_proximo_fold_validacao_por_grupo_origem':
    raise ValueError('Estratégia de validação ou ativação incompatível com v1.')
if config['agregacao_ruido'] != 'media_aritmetica_por_condicao' or config['escala_alvos'] != ['S', 'S', 'S*wn', 'S*wn**2']:
    raise ValueError('Agregação ou escalas incompatíveis com v1.')
if min(config['epocas_maximas'], config['paciencia'], config['batch_size']) <= 0:
    raise ValueError('Épocas, paciência e lote devem ser positivos.')


import base64
import gzip
import hashlib
import io
import json
import shutil
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import torch
def display(tabela):
    print(tabela.to_string())
from sklearn.metrics import r2_score
from sklearn.model_selection import GroupKFold
from sklearn.preprocessing import StandardScaler
from torch import nn

SEMENTE = config["semente"]
torch.set_num_threads(2)
torch.use_deterministic_algorithms(True)
PASTA = args.saida.resolve()
if PASTA.exists() and any(PASTA.iterdir()):
    raise ValueError(f'A saída já contém arquivos: {PASTA}. Escolha uma pasta de execução nova.')
PASTA.mkdir(parents=True, exist_ok=True)
ALVOS = ['x_pico_abs_m', 'x_rms_m', 'v_rms_m_s', 'a_rms_m_s2']
ROTULOS = dict(zip(ALVOS, ['Pico absoluto de x', 'RMS de x', 'RMS de v', 'RMS de a']))
CATEGORIAS = {
    'degrau': 'Degrau', 'impulso': 'Impulso', 'subressonante': 'Subressonante',
    'ressonante': 'Ressonante', 'suprarressonante': 'Suprarressonante', 'larga': 'Banda larga',
}


dados_csv = (RAIZ / config['csv']).read_bytes()
if hashlib.sha256(dados_csv).hexdigest() != config['csv_sha256']:
    raise ValueError('O CSV difere do experimento registrado. Confira o caminho e a versão do banco.')
banco = pd.read_csv(io.BytesIO(dados_csv))


# @title Calcular a média e a dispersão por condição
assert len(banco) == 2520 and banco.id_simulacao.is_unique
assert banco.grupo_origem.nunique() == 10 and banco.sistema_id.nunique() == 60
assert np.isclose(banco.zeta, .02).all() and np.isclose(banco.tf_s, 64).all()
assert np.isclose(banco.fs_Hz, 512).all() and banco[['x0_m', 'v0_m_s']].eq(0).all().all()
assert np.isfinite(banco[ALVOS]).all().all() and banco[ALVOS].gt(0).all().all()

base = banco.assign(banda=banco.banda.fillna(''))
chaves = ['grupo_origem', 'sistema_id', 'escala_ref_m', 'excitacao', 'banda']
entradas = ['m_kg', 'k_N_m', 'zeta', 'tf_s', 'F_degrau_N', 'J_impulso_N_s',
            'F_ruido_rms_N', 'fmin_Hz', 'fmax_Hz']
grupos = base.groupby(chaves, sort=True)
assert grupos[entradas].nunique(dropna=False).le(1).all().all()
agregacoes = {coluna: (coluna, 'first') for coluna in entradas}
agregacoes.update({alvo: (alvo, 'mean') for alvo in ALVOS})
agregacoes.update({f'dp_{alvo}': (alvo, 'std') for alvo in ALVOS})
dados = grupos.agg(**agregacoes, n_realizacoes=('id_simulacao', 'size'),
                   sementes_distintas=('semente_ruido', 'nunique')).reset_index()
ruido = dados.excitacao.eq('ruido')
assert dados.loc[ruido, 'n_realizacoes'].eq(3).all()
assert dados.loc[ruido, 'sementes_distintas'].eq(3).all()
assert dados.loc[~ruido, 'n_realizacoes'].eq(1).all()
assert base.loc[base.excitacao.eq('ruido')].groupby('semente_ruido').grupo_origem.nunique().eq(1).all()
dados['categoria'] = dados.banda.where(ruido, dados.excitacao)
assert len(dados) == 1080 and dados.categoria.value_counts().eq(180).all()
assert set(dados.categoria) == set(CATEGORIAS)
display(dados.groupby('categoria').n_realizacoes.agg(condicoes='size', simulacoes='sum').reindex(CATEGORIAS))


# @title Preparar as entradas e a divisão por grupo de origem
def preparar_entradas(condicoes):
    massa = condicoes.m_kg.to_numpy()
    rigidez = condicoes.k_N_m.to_numpy()
    wn = np.sqrt(rigidez / massa)
    fn = wn / (2 * np.pi)
    escala = (
        condicoes.F_degrau_N.fillna(0).to_numpy() / rigidez
        + condicoes.J_impulso_N_s.fillna(0).to_numpy() / (massa * wn)
        + condicoes.F_ruido_rms_N.fillna(0).to_numpy() / rigidez
    )
    escalas_y = escala[:, None] * np.column_stack([np.ones_like(wn), np.ones_like(wn), wn, wn**2])
    atributos = pd.DataFrame({
        'log10_T_wn': np.log10(condicoes.tf_s * wn),
        'fmin_sobre_fn': np.round(condicoes.fmin_Hz.fillna(0) / fn, 10),
        'fmax_sobre_fn': np.round(condicoes.fmax_Hz.fillna(0) / fn, 10),
        **{tipo: condicoes.excitacao.eq(tipo).astype(float) for tipo in ['degrau', 'impulso', 'ruido']},
    })
    assert np.isfinite(atributos).all().all() and np.isfinite(escalas_y).all() and (escala > 0).all()
    return atributos, escalas_y

atributos, escalas_y = preparar_entradas(dados)
x = atributos.to_numpy()
y_real = dados[ALVOS].to_numpy()
y_log = np.log10(y_real / escalas_y)
familias = dados.grupo_origem.to_numpy()
testes = [teste for _, teste in GroupKFold(n_splits=5).split(x, groups=familias)]
particoes = []
for rodada, teste in enumerate(testes):
    validacao = testes[(rodada + 1) % len(testes)]
    treino = np.setdiff1d(np.arange(len(dados)), np.r_[validacao, teste])
    grupos_tr, grupos_va, grupos_te = [set(familias[idx]) for idx in (treino, validacao, teste)]
    assert (len(grupos_tr), len(grupos_va), len(grupos_te)) == (6, 2, 2)
    assert not (grupos_tr & grupos_va or grupos_tr & grupos_te or grupos_va & grupos_te)
    particoes.append(dict(rodada=rodada + 1, treino=' '.join(sorted(grupos_tr)),
                         validacao=' '.join(sorted(grupos_va)), teste=' '.join(sorted(grupos_te))))
particoes = pd.DataFrame(particoes)
display(particoes)


# @title Treinar cinco MLPs e gerar previsões fora do treino
class SuspensionMLP(nn.Module):
    def __init__(self, n_entradas, n_alvos):
        super().__init__()
        self.net = nn.Sequential(
            nn.Linear(n_entradas, 128), nn.SiLU(),
            nn.Linear(128, 128), nn.SiLU(),
            nn.Linear(128, 64), nn.SiLU(), nn.Linear(64, n_alvos),
        )

    def forward(self, valores):
        return self.net(valores)


def tensor(valores):
    return torch.as_tensor(valores, dtype=torch.float32)


def treinar_rodada(treino, validacao, teste, rodada):
    torch.manual_seed(SEMENTE + rodada)
    scaler_x = StandardScaler().fit(x[treino])
    scaler_y = StandardScaler().fit(y_log[treino])
    x_tr, x_va, x_te = (tensor(scaler_x.transform(x[idx])) for idx in (treino, validacao, teste))
    y_tr, y_va = (tensor(scaler_y.transform(y_log[idx])) for idx in (treino, validacao))
    modelo = SuspensionMLP(x.shape[1], len(ALVOS))
    perda = nn.MSELoss()
    otimizador = torch.optim.AdamW(modelo.parameters(), lr=config['learning_rate'], weight_decay=config['weight_decay'])
    scheduler = torch.optim.lr_scheduler.ReduceLROnPlateau(otimizador, factor=.5, patience=15)
    historico = []
    melhor_val, melhor_epoca = float('inf'), 0
    for epoca in range(1, config['epocas_maximas'] + 1):
        modelo.train()
        for lote in torch.randperm(len(x_tr)).split(config['batch_size']):
            otimizador.zero_grad(set_to_none=True)
            perda(modelo(x_tr[lote]), y_tr[lote]).backward()
            otimizador.step()
        modelo.eval()
        with torch.no_grad():
            mse_tr = perda(modelo(x_tr), y_tr).item()
            mse_va = perda(modelo(x_va), y_va).item()
        historico.append(dict(rodada=rodada, epoca=epoca, mse_treino=mse_tr, mse_validacao=mse_va))
        if mse_va < melhor_val:
            melhor_val, melhor_epoca = mse_va, epoca
            melhor_estado = {nome: valor.detach().clone() for nome, valor in modelo.state_dict().items()}
        scheduler.step(mse_va)
        if epoca - melhor_epoca >= config['paciencia']:
            break

    modelo.load_state_dict(melhor_estado)
    with torch.no_grad():
        pred_log = scaler_y.inverse_transform(modelo(x_te).numpy())
    torch.save({
        'pesos': melhor_estado, 'atributos': list(atributos.columns), 'alvos': ALVOS,
        'media_x': scaler_x.mean_.tolist(), 'escala_x': scaler_x.scale_.tolist(),
        'media_y_log': scaler_y.mean_.tolist(), 'escala_y_log': scaler_y.scale_.tolist(),
        'familias_treino': sorted(set(familias[treino])),
        'familias_validacao': sorted(set(familias[validacao])),
        'familias_teste': sorted(set(familias[teste])),
        'melhor_epoca': melhor_epoca,
    }, PASTA / f'mlp_rodada_{rodada}.pt')
    print(f'Rodada {rodada}/5 | melhor época {melhor_epoca} de {epoca} | MSE validação {melhor_val:.5f}')
    return np.power(10., pred_log) * escalas_y[teste], historico


y_pred = np.full_like(y_real, np.nan)
y_referencia = np.full_like(y_real, np.nan)
rodadas_teste = np.zeros(len(dados), dtype=int)
historicos = []
for rodada, teste in enumerate(testes, start=1):
    validacao = testes[rodada % len(testes)]
    treino = np.setdiff1d(np.arange(len(dados)), np.r_[validacao, teste])
    y_pred[teste], historico = treinar_rodada(treino, validacao, teste, rodada)
    historicos.extend(historico)
    medianas = pd.DataFrame(y_log[treino], index=dados.categoria.iloc[treino], columns=ALVOS).groupby(level=0).median()
    y_referencia[teste] = np.power(10., medianas.loc[dados.categoria.iloc[teste]].to_numpy()) * escalas_y[teste]
    assert not rodadas_teste[teste].any()
    rodadas_teste[teste] = rodada

assert np.isfinite(y_pred).all() and np.isfinite(y_referencia).all() and rodadas_teste.all()
historicos = pd.DataFrame(historicos)


# @title Medir o erro de teste e a dispersão do ruído
registros = []
categorias_teste = ['geral', *CATEGORIAS]
for categoria in categorias_teste:
    selecao = np.ones(len(dados), dtype=bool) if categoria == 'geral' else dados.categoria.eq(categoria).to_numpy()
    for j, alvo in enumerate(ALVOS):
        real, pred, ref = y_real[selecao, j], y_pred[selecao, j], y_referencia[selecao, j]
        erro = np.abs(pred - real)
        erro_pct = 100 * erro / real
        desvio = dados.loc[selecao, f'dp_{alvo}'].to_numpy() / real * 100
        dispersao = np.nanmedian(desvio) if np.isfinite(desvio).any() and categoria != 'geral' else np.nan
        registros.append(dict(categoria=categoria, alvo=alvo, n=int(selecao.sum()),
            mae_SI=erro.mean(), mape_pct=erro_pct.mean(), p90_erro_pct=np.percentile(erro_pct, 90),
            r2=r2_score(real, pred), mape_referencia_pct=np.mean(100 * np.abs(ref - real) / real),
            mediana_cv_ruido_pct=dispersao))
metricas = pd.DataFrame(registros)
previsoes = dados.assign(rodada_teste=rodadas_teste).copy()
for j, alvo in enumerate(ALVOS):
    previsoes[f'prev_{alvo}'] = y_pred[:, j]
    previsoes[f'ref_mediana_{alvo}'] = y_referencia[:, j]
familia_resultados = []
for familia, tabela in previsoes.groupby('grupo_origem'):
    for alvo in ALVOS:
        mape = (100 * (tabela[f'prev_{alvo}'] / tabela[alvo] - 1).abs()).mean()
        familia_resultados.append({'familia': familia, 'alvo': alvo, 'mape_pct': mape})
familia_resultados = pd.DataFrame(familia_resultados)

def tabela_por_categoria(coluna):
    tabela = metricas.pivot(index='categoria', columns='alvo', values=coluna)
    return tabela.reindex(index=categorias_teste, columns=ALVOS).rename(
        index={**CATEGORIAS, 'geral': 'Geral'}, columns=ROTULOS)

print('MAPE (%) da MLP nas famílias reservadas')
display(tabela_por_categoria('mape_pct').round(2))
print('MAPE (%) da referência baseada nas medianas do treino')
display(tabela_por_categoria('mape_referencia_pct').round(2))
print('Dispersão do ruído: mediana do desvio padrão / média das três realizações (%)')
display(tabela_por_categoria('mediana_cv_ruido_pct').dropna(how='all').round(2))


# @title Curvas de aprendizagem, paridade e erros por condição
cores = ['#2166ac', '#d6604d', '#4393c3', '#762a83', '#228450', '#b66a0c']
fig, eixos = plt.subplots(2, 3, figsize=(12, 6.8), layout='constrained', sharey=True)
for ax, (rodada, hist) in zip(eixos.flat, historicos.groupby('rodada')):
    ax.semilogy(hist.epoca, hist.mse_treino, color='#2166ac', label='Treino')
    ax.semilogy(hist.epoca, hist.mse_validacao, color='#d6604d', label='Validação')
    melhor = hist.loc[hist.mse_validacao.idxmin(), 'epoca']
    ax.axvline(melhor, color='0.35', linestyle=':', linewidth=1, label='Melhor época')
    ax.set(title=f'Rodada {rodada}', xlabel='Época', ylabel='MSE em escala de treino')
    ax.grid(alpha=.2)
eixos.flat[-1].axis('off')
eixos.flat[0].legend(fontsize=8)
fig.savefig(PASTA / 'curvas_aprendizagem.png', dpi=150)
plt.close(fig)

fig, eixos = plt.subplots(2, 2, figsize=(10.8, 8.2), layout='constrained')
for j, (ax, alvo, unidade, fator) in enumerate(zip(eixos.flat, ALVOS, ['mm', 'mm', 'm/s', 'm/s²'], [1000, 1000, 1, 1])):
    sim, pred = fator * y_real[:, j], fator * y_pred[:, j]
    for (categoria, nome), cor in zip(CATEGORIAS.items(), cores):
        sel = dados.categoria.eq(categoria)
        ax.scatter(sim[sel], pred[sel], s=13, alpha=.6, color=cor, label=nome)
    lo, hi = min(sim.min(), pred.min()), max(sim.max(), pred.max())
    ax.plot([lo, hi], [lo, hi], '--', color='0.25', linewidth=1)
    ax.set(xscale='log', yscale='log', title=ROTULOS[alvo],
           xlabel=f'Referência simulada ({unidade})', ylabel=f'MLP ({unidade})')
    ax.set_aspect('equal', adjustable='box')
    ax.grid(alpha=.2, which='both')
eixos.flat[0].legend(fontsize=7, loc='lower right')
fig.savefig(PASTA / 'paridade_teste.png', dpi=150)
plt.close(fig)

fig, eixos = plt.subplots(2, 2, figsize=(11, 6), layout='constrained')
for ax, alvo in zip(eixos.flat, ALVOS):
    linhas = metricas.loc[metricas.alvo.eq(alvo)].set_index('categoria').loc[list(CATEGORIAS)]
    pos = np.arange(len(CATEGORIAS))
    ax.bar(pos - .18, linhas.mape_pct, width=.36, color='#2166ac', label='MLP')
    ax.bar(pos + .18, linhas.mape_referencia_pct, width=.36, color='#888888', label='Mediana do treino')
    ax.set_xticks(pos, CATEGORIAS.values(), rotation=18, ha='right')
    ax.set(title=ROTULOS[alvo], ylabel='MAPE (%)')
    ax.grid(axis='y', alpha=.2)
eixos.flat[0].legend(fontsize=8)
fig.savefig(PASTA / 'erros_por_categoria.png', dpi=150)
plt.close(fig)


# @title Resumo do estudo e exportação dos resultados
gerais = metricas.loc[metricas.categoria.eq('geral')].set_index('alvo').loc[ALVOS]
detalhadas = metricas.loc[metricas.categoria.ne('geral')]
pior = detalhadas.loc[detalhadas.mape_pct.idxmax()]
dispersoes = metricas.dropna(subset=['mediana_cv_ruido_pct'])
dp_max = dispersoes.loc[dispersoes.mediana_cv_ruido_pct.idxmax()]
vence = int((detalhadas.mape_pct < detalhadas.mape_referencia_pct).sum())
relatorio = [
    '# PIBIC · Resultado da MLP de 1 GDL', '',
    'O estudo usou 2.520 simulações, 60 configurações e 10 famílias. Após a média das três realizações de ruído por condição, ficaram 1.080 condições, com 180 por categoria. Todas as condições tiveram uma previsão de teste feita por uma rede treinada sem a sua família.', '',
    '| Indicador | MAPE MLP | MAPE mediana | R² MLP |',
    '|---|---:|---:|---:|',
]
for alvo, linha in gerais.iterrows():
    relatorio.append(f'| {ROTULOS[alvo]} | {linha.mape_pct:.2f}% | {linha.mape_referencia_pct:.2f}% | {linha.r2:.4f} |')
relatorio.extend([
    '', f'A MLP teve MAPE menor que a mediana do treino em **{vence} de {len(detalhadas)}** combinações de categoria e indicador. O maior MAPE por categoria foi **{pior.mape_pct:.2f}%**, para **{ROTULOS[pior.alvo]}** em **{CATEGORIAS[pior.categoria]}**.',
    '', f'A maior dispersão relativa mediana entre as três realizações foi **{dp_max.mediana_cv_ruido_pct:.2f}%**, para **{ROTULOS[dp_max.alvo]}** em **{CATEGORIAS[dp_max.categoria]}**. Esse número é um coeficiente de variação amostral, calculado dentro de cada condição.',
    '', 'Os resultados valem para o oscilador linear simulado com amortecimento de 2%, condições iniciais nulas e quatro bandas fixadas em relação à frequência natural. A referência é a solução do simulador. A aplicação a medições físicas, outras taxas de amortecimento ou um modelo de 2 GDL exigirá nova avaliação.',
])
texto = '\n'.join(relatorio) + '\n'
(PASTA / 'relatorio_mlp_1gdl.md').write_text(texto, encoding='utf-8')
previsoes.to_csv(PASTA / 'previsoes_teste.csv', index=False)
metricas.to_csv(PASTA / 'metricas_por_categoria.csv', index=False)
familia_resultados.to_csv(PASTA / 'metricas_por_familia.csv', index=False)
particoes.to_csv(PASTA / 'particoes_por_familia.csv', index=False)
historicos.to_csv(PASTA / 'curvas_aprendizagem.csv', index=False)
(PASTA / 'proveniencia.json').write_text(json.dumps({
    'arquivo_fonte': config['csv'], 'experimento': config,
    'python': sys.version, 'numpy': np.__version__, 'pandas': pd.__version__,
    'sklearn': __import__('sklearn').__version__, 'matplotlib': __import__('matplotlib').__version__,
    'executado_em_utc': datetime.now(timezone.utc).isoformat(),
    'script_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(), 'sha256': hashlib.sha256(dados_csv).hexdigest(),
    'sementes_treino': [SEMENTE + rodada for rodada in range(1, 6)], 'torch': str(torch.__version__),
}, indent=2), encoding='utf-8')
dados.to_csv(PASTA / 'condicoes_agregadas.csv', index=False)
(PASTA / 'relatorio_mlp_1gdl.md').write_text(texto, encoding='utf-8')
shutil.copy2(args.config, PASTA / 'configuracao.json')
arquivo_zip = shutil.make_archive(str(PASTA), 'zip', root_dir=PASTA)
print(texto)
print(f'Treino e avaliação concluídos. Resultados em {PASTA}. Pacote em {arquivo_zip}.')
