"""Confere integridade, unidades físicas e separação dos estudos do PIBIC."""
import argparse
import ast
import hashlib
import importlib.util
import json
import re
import sys
from pathlib import Path

import numpy as np
import pandas as pd


RAIZ = Path(__file__).resolve().parents[1]


def conferir(condicao, mensagem):
    if not condicao:
        raise ValueError(mensagem)


def ler(caminho):
    return pd.read_csv(RAIZ / caminho)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--recalcular', action='store_true', help='Recalcula os seis indicadores das 2.520 simulações.')
    parser.add_argument('--saida', type=Path, default=RAIZ / 'gerados/auditoria.json')
    parser.add_argument('--resultados', type=Path, default=RAIZ / 'resultados/expansao_1gdl/revisao_20261119')
    args = parser.parse_args()
    manifest = json.loads((RAIZ / 'experimentos/manifesto_dados.json').read_text(encoding='utf-8'))
    for item in manifest['arquivos']:
        caminho = RAIZ / item['caminho']
        conferir(hashlib.sha256(caminho.read_bytes()).hexdigest() == item['sha256'], f'Conteúdo divergente: {caminho}')

    total_codigo = 0
    for caminho in RAIZ.rglob('*.py'):
        if any(p in caminho.parts for p in ['.git', 'gerados', '.venv']):
            continue
        ast.parse(caminho.read_text(encoding='utf-8-sig'), filename=str(caminho))
        total_codigo += 1
    for caminho in (RAIZ / 'notebooks').rglob('*.ipynb'):
        notebook = json.loads(caminho.read_text(encoding='utf-8'))
        for celula in notebook['cells']:
            if celula['cell_type'] == 'code':
                fonte = ''.join(celula['source'])
                if not fonte.startswith(('!', '%%')):
                    ast.parse(fonte)

    historico = ler('dados/1gdl/harmonico/dataset_completo_treinamento_suspensao_1dof.csv')
    conferir(len(historico) == 1228 and historico.id.is_unique, 'IDs ou tamanho do harmônico inválidos.')
    mapa = dict(X_teor='u_teor_m', Xmax_total='u_max_total_m', x_rms='u_rms_m',
                v_rms='u_dot_rms_m_s', a_rms='u_ddot_rms_m_s2')
    familias_historicas = []
    for split, nome in [('treino', 'banco_treino_1000.csv'), ('validacao', 'banco_validacao_200.csv'), ('teste_cego_rao', 'banco_teste_cego_28_rao.csv')]:
        separado = ler('dados/1gdl/harmonico/' + nome)
        consolidado = historico.loc[historico.split.eq(split)].set_index('id').loc[separado.id]
        conferir(len(consolidado) == len(separado), f'Tamanho divergente em {nome}')
        for antigo, novo in mapa.items():
            conferir(np.allclose(separado[antigo], consolidado[novo], rtol=1e-9, atol=1e-13), f'Alvo divergente em {nome}: {antigo}')
        familias_historicas.append(set(separado.caso_origem if 'caso_origem' in separado else separado.id))
    conferir(len(set.intersection(*familias_historicas)) == 28, 'Conferir origens do estudo harmônico.')
    conferir(np.allclose(historico.wn, np.sqrt(historico.k / historico.m)), 'wn inconsistente no harmônico.')
    conferir(np.allclose(historico.c, 2 * historico.zeta * np.sqrt(historico.k * historico.m)), 'c inconsistente no harmônico.')
    conferir(np.allclose(historico.u_teor_m, historico.dst / np.sqrt((1-historico.r**2)**2 + (2*historico.zeta*historico.r)**2)), 'Amplitude permanente inconsistente.')

    config = json.loads((RAIZ / 'experimentos/expansao_1gdl_v1.json').read_text(encoding='utf-8'))
    banco = ler(config['csv'])
    antigo = ler('dados/1gdl/expansao/banco_1gdl_excitacoes.csv')
    conferir(len(banco) == config['n_simulacoes'] and banco.id_simulacao.is_unique, 'IDs ou tamanho inválidos na expansão.')
    pd.testing.assert_frame_equal(banco.iloc[:len(antigo)].reset_index(drop=True), antigo)
    conferir(banco.grupo_origem.nunique() == 10 and banco.sistema_id.nunique() == 60, 'Famílias ou sistemas divergentes.')
    conferir(np.allclose(banco.c_N_s_m, 2*banco.zeta*np.sqrt(banco.m_kg*banco.k_N_m)), 'Amortecimento inconsistente.')
    conferir(np.allclose(banco.fn_Hz, np.sqrt(banco.k_N_m/banco.m_kg)/(2*np.pi)), 'Frequência natural inconsistente.')
    for coluna, valor in [('zeta', .02), ('tf_s', 64), ('fs_Hz', 512), ('x0_m', 0), ('v0_m_s', 0)]:
        conferir(np.allclose(banco[coluna], valor), f'Domínio divergente em {coluna}.')
    alvos = [c for c in banco if '_rms_' in c or '_pico_abs_' in c]
    alvos = [c for c in alvos if c != 'F_ruido_rms_N']
    conferir(np.isfinite(banco[alvos]).all().all() and banco[alvos].gt(0).all().all(), 'Indicadores inválidos.')
    conferir(set(banco.excitacao) == {'degrau', 'impulso', 'ruido'}, 'Excitação desconhecida.')
    ruido = banco.excitacao.eq('ruido')
    bandas = {'subressonante': (.25, .75), 'ressonante': (.75, 1.25), 'suprarressonante': (1.25, 2.5), 'larga': (.25, 2.5)}
    for banda, (inferior, superior) in bandas.items():
        bloco = banco.loc[ruido & banco.banda.eq(banda)]
        conferir(len(bloco) == 540, f'Contagem divergente em {banda}.')
        conferir(np.allclose(bloco.fmin_Hz, inferior*bloco.fn_Hz) and np.allclose(bloco.fmax_Hz, superior*bloco.fn_Hz), 'Banda inconsistente.')
    conferir(banco.loc[ruido, 'fmax_Hz'].lt(banco.loc[ruido, 'fs_Hz']/2).all(), 'Banda acima de Nyquist.')
    for tipo, coluna, esperado in [
        ('degrau', 'F_degrau_N', banco.k_N_m*banco.escala_ref_m),
        ('impulso', 'J_impulso_N_s', np.sqrt(banco.m_kg*banco.k_N_m)*banco.escala_ref_m),
        ('ruido', 'F_ruido_rms_N', banco.k_N_m*banco.escala_ref_m),
    ]:
        selecao = banco.excitacao.eq(tipo)
        conferir(np.allclose(banco.loc[selecao, coluna], esperado[selecao]), f'Intensidade inconsistente em {tipo}.')
        conferir(banco.loc[~selecao, coluna].isna().all(), f'Intensidade indevida em {tipo}.')
    conferir(banco.loc[~ruido, ['fmin_Hz', 'fmax_Hz', 'semente_ruido']].isna().all().all(), 'Metadados de ruído em condição determinística.')
    grupos = banco.assign(banda=banco.banda.fillna('')).groupby(['grupo_origem', 'sistema_id', 'escala_ref_m', 'excitacao', 'banda'])
    contagens = grupos.size()
    conferir(len(contagens) == 1080 and contagens.value_counts().to_dict() == {3: 720, 1: 360}, 'Agregação divergente.')
    conferir(banco.loc[ruido].groupby('semente_ruido').grupo_origem.nunique().eq(1).all(), 'Sementes compartilhadas entre famílias.')
    fonte = (RAIZ / 'src/1gdl/expansao/gerar_banco_1gdl.py')
    spec = importlib.util.spec_from_file_location('gerador_verificado', fonte)
    gerador = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(gerador)
    entradas = list(gerador.casos(gerador.sistemas_do_banco(RAIZ / 'dados/1gdl/harmonico/dataset_completo_treinamento_suspensao_1dof.csv')))
    conferir(len(entradas) == 1260, 'Desenho do gerador inicial divergente.')
    for linha in banco.itertuples(index=False):
        ids_origem = set(linha.casos_rao_origem.split('|'))
        conferir(ids_origem <= familias_historicas[2], 'Origem Rao desconhecida.')
    max_erro = 0.0
    if args.recalcular:
        for linha in banco.to_dict('records'):
            recalculado = gerador.indicadores(gerador.resposta(linha))
            erro = max(abs(recalculado[c]/linha[c] - 1) for c in alvos)
            max_erro = max(max_erro, erro)
        conferir(max_erro < 1e-10, f'Indicadores não reproduzidos: erro {max_erro}')

    preliminar = ler('dados/2gdl/dataset_suspensao_completo.csv')
    matlab = ler('dados/2gdl/dataset_pronto_para_MLP.csv')
    conferir(len(preliminar) == len(matlab) == 5000, 'Tamanho de 2 GDL alterado.')
    for coluna in preliminar.select_dtypes('number'):
        conferir(np.allclose(preliminar[coluna], matlab[coluna], rtol=1e-10), f'Entrada ou alvo base de 2 GDL alterado: {coluna}')
    conferir(preliminar.Perfil_Pista.equals(matlab.Perfil_Pista), 'Perfis de 2 GDL divergentes.')

    previsoes = pd.read_csv(args.resultados / 'previsoes_teste.csv')
    particoes = pd.read_csv(args.resultados / 'particoes_por_familia.csv')
    metricas = pd.read_csv(args.resultados / 'metricas_por_categoria.csv')
    conferir(len(previsoes) == 1080 and len(particoes) == 5, 'Resultados incompletos.')
    chaves = ['grupo_origem', 'sistema_id', 'escala_ref_m', 'excitacao', 'banda']
    conferir(not previsoes.duplicated(chaves).any(), 'Condições repetidas nas previsões.')
    familias_teste = []
    for linha in particoes.itertuples(index=False):
        tr, va, te = (set(getattr(linha, c).split()) for c in ['treino', 'validacao', 'teste'])
        conferir((len(tr), len(va), len(te)) == (6, 2, 2) and not (tr & va or tr & te or va & te), 'Sobreposição entre famílias.')
        conferir(set(previsoes.loc[previsoes.rodada_teste.eq(linha.rodada), 'grupo_origem']) == te, 'Previsão atribuída à rodada errada.')
        familias_teste.extend(te)
    conferir(len(familias_teste) == len(set(familias_teste)) == 10, 'Família avaliada mais de uma vez.')
    for linha in metricas.itertuples(index=False):
        sub = previsoes if linha.categoria == 'geral' else previsoes.loc[previsoes.categoria.eq(linha.categoria)]
        real, predito = sub[linha.alvo], sub['prev_' + linha.alvo]
        mape = (100 * (predito/real - 1).abs()).mean()
        conferir(len(sub) == linha.n and np.isclose(mape, linha.mape_pct, rtol=1e-9), 'MAPE não reproduzido a partir das previsões.')
    proveniencia = json.loads((args.resultados / 'proveniencia.json').read_text(encoding='utf-8'))
    conferir(proveniencia['sha256'] == config['csv_sha256'], 'Banco diferente na execução arquivada.')
    conferir(proveniencia['script_sha256'] == hashlib.sha256((RAIZ / 'src/1gdl/mlp/treinar_expansao_1gdl.py').read_bytes()).hexdigest(), 'Script atual difere do executado na revisão.')

    links_quebrados = []
    for caminho in RAIZ.rglob('*.md'):
        if '.git' in caminho.parts or 'gerados' in caminho.parts:
            continue
        for link in re.findall(r'\]\(([^)]+)\)', caminho.read_text(encoding='utf-8')):
            link = link.split('#')[0]
            if not link or '://' in link or link.startswith('mailto:'):
                continue
            if not (caminho.parent / link).exists():
                links_quebrados.append(f'{caminho.relative_to(RAIZ)} -> {link}')
    conferir(not links_quebrados, '\n'.join(links_quebrados))
    relatorio = {'estado': 'verificacoes_automatizadas_aprovadas', 'arquivos_csv': len(manifest['arquivos']),
        'scripts_python_sintaxe': total_codigo, 'harmonico_linhas': 1228, 'origens_compartilhadas_harmonico': 28,
        'expansao_simulacoes': len(banco), 'expansao_condicoes': len(contagens), 'expansao_sistemas': 60,
        'expansao_familias': 10, 'recalculo_completo': args.recalcular, 'max_erro_relativo_recalculo': max_erro if args.recalcular else None,
        'amostragem_Hz': 512, 'duracao_s': 64, 'fn_Hz_min': banco.fn_Hz.min(), 'fn_Hz_max': banco.fn_Hz.max(),
        'previsoes_teste_verificadas': len(previsoes), 'particoes_sem_sobreposicao': True,
        'metricas_recalculadas_das_previsoes': len(metricas),
        'pendencias_cientificas': ['harmonico_familias_compartilhadas', '2gdl_perfil_e_unidades_e_rms',
                                 'comparacao_experimental_pendente', 'xai_pendente']}
    args.saida.parent.mkdir(parents=True, exist_ok=True)
    args.saida.write_text(json.dumps(relatorio, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(relatorio, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
