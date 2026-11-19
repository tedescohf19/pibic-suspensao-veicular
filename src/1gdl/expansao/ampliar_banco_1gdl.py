import csv
from collections import Counter
from pathlib import Path
import sys

import numpy as np

import argparse
sys.path.insert(0, str(Path(__file__).resolve().parent))
from gerar_banco_1gdl import BANDAS, casos, indicadores, resposta, sistemas_do_banco

parser = argparse.ArgumentParser(description="Preserva os 1.260 casos e gera as variantes V3 a V5.")
parser.add_argument('harmonico', type=Path)
parser.add_argument('banco_1260', type=Path)
parser.add_argument('saida', type=Path)
args = parser.parse_args()
base, origem, destino = args.harmonico, args.banco_1260, args.saida
if destino.resolve() in {base.resolve(), origem.resolve()}:
    parser.error('A saída deve ser diferente das fontes.')
destino.parent.mkdir(parents=True, exist_ok=True)
with origem.open(encoding="utf-8", newline="") as stream:
    reader = csv.DictReader(stream)
    campos = reader.fieldnames
    antigos = list(reader)

nominais = [c for c in casos(sistemas_do_banco(base)) if c["sistema_id"].endswith("-V0")]
rng = np.random.default_rng(20261112)
novos = []
for grupo in sorted({c["grupo_origem"] for c in nominais}):
    modelos = [c for c in nominais if c["grupo_origem"] == grupo]
    numero_grupo = int(grupo[1:])
    for variante, (fator_m, fator_k) in enumerate(rng.uniform(.85, 1.15, size=(3, 2)), start=3):
        for original in modelos:
            m = original["m_kg"] * fator_m
            k = original["k_N_m"] * fator_k
            wn = np.sqrt(k / m)
            fn = wn / (2 * np.pi)
            escala = original["escala_ref_m"]
            novo = {
                **original,
                "id_simulacao": original["id_simulacao"].replace(f"{grupo}-V0-", f"{grupo}-V{variante}-", 1),
                "sistema_id": f"{grupo}-V{variante}",
                "m_kg": m,
                "k_N_m": k,
                "c_N_s_m": 2 * original["zeta"] * m * wn,
                "fn_Hz": fn,
            }
            tipo = novo["excitacao"]
            if tipo == "degrau":
                novo["F_degrau_N"] = k * escala
            elif tipo == "impulso":
                novo["J_impulso_N_s"] = m * wn * escala
            else:
                inferior, superior = BANDAS[novo["banda"]]
                repeticao = int(original["id_simulacao"].rsplit("-", 1)[-1])
                novo.update(fmin_Hz=fn * inferior, fmax_Hz=fn * superior, F_ruido_rms_N=k * escala,
                            semente_ruido=20262000 + numero_grupo * 100 + variante * 10 + repeticao)
            metricas = indicadores(resposta(novo))
            assert np.isfinite(list(metricas.values())).all()
            novos.append({**novo, **metricas})

assert len(antigos) == len(novos) == 1260
with destino.open("w", encoding="utf-8", newline="") as stream:
    writer = csv.DictWriter(stream, fieldnames=campos)
    writer.writeheader()
    writer.writerows(antigos)
    writer.writerows(novos)

with destino.open(encoding="utf-8", newline="") as stream:
    linhas = list(csv.DictReader(stream))
assert linhas[:1260] == antigos
assert len({r["id_simulacao"] for r in linhas}) == len(linhas) == 2520
assert len({(float(r["m_kg"]), float(r["k_N_m"])) for r in linhas}) == 60
assert len({r["grupo_origem"] for r in linhas}) == 10
contagem = Counter((r["excitacao"], r["banda"]) for r in linhas)
assert contagem[("degrau", "")] == contagem[("impulso", "")] == 180
assert all(contagem[("ruido", faixa)] == 540 for faixa in BANDAS)
print(f"{len(linhas)} casos, 60 sistemas, 10 famílias. Casos originais preservados.")
print(contagem)
