"""Expande o banco harmônico com excitações de força em um oscilador de 1 GDL."""

import argparse
import csv
from pathlib import Path

import numpy as np


DURACAO_S = 64
FS_HZ = 512
AMOSTRAS = DURACAO_S * FS_HZ
AMOSTRAGEM = 20261023
ESCALAS_M = (0.002, 0.005, 0.010)
BANDAS = {
    "subressonante": (0.25, 0.75),
    "ressonante": (0.75, 1.25),
    "suprarressonante": (1.25, 2.50),
    "larga": (0.25, 2.50),
}


def sistemas_do_banco(caminho):
    sistemas = {}
    with caminho.open(encoding="utf-8-sig", newline="") as arquivo:
        for linha in csv.DictReader(arquivo):
            if linha["split"] == "teste_cego_rao":
                parametros = tuple(float(linha[chave]) for chave in ("m", "k", "zeta"))
                chave = tuple(round(p, 10) for p in parametros)
                sistema = sistemas.setdefault(chave, [parametros, []])
                sistema[1].append(linha["id"])
    if not sistemas:
        raise ValueError("O CSV deve conter o split teste_cego_rao e as colunas id, m, k e zeta.")
    return list(sistemas.values())


def casos(sistemas):
    rng = np.random.default_rng(AMOSTRAGEM)
    for grupo, ((m0, k0, zeta), origens) in enumerate(sistemas, 1):
        fatores = [(1.0, 1.0), *rng.uniform(0.85, 1.15, size=(2, 2))]
        for variante, (fm, fk) in enumerate(fatores):
            m, k = m0 * fm, k0 * fk
            wn = np.sqrt(k / m)
            fn = wn / (2 * np.pi)
            for escala_id, escala in enumerate(ESCALAS_M, 1):
                base = {
                    "grupo_origem": f"G{grupo:02d}",
                    "sistema_id": f"G{grupo:02d}-V{variante}",
                    "casos_rao_origem": "|".join(origens),
                    "m_kg": m, "k_N_m": k, "c_N_s_m": 2 * zeta * m * wn,
                    "zeta": zeta, "fn_Hz": fn, "escala_ref_m": escala,
                    "tf_s": DURACAO_S, "fs_Hz": FS_HZ, "x0_m": 0.0, "v0_m_s": 0.0,
                }
                prefixo = f"{base['sistema_id']}-A{escala_id}"
                for tipo, banda, repeticao in [
                    ("degrau", "", 0), ("impulso", "", 0),
                    *(( "ruido", faixa, rep) for faixa in BANDAS for rep in range(1, 4)),
                ]:
                    limites = BANDAS.get(banda)
                    semente = AMOSTRAGEM + grupo * 10 + repeticao if limites else None
                    yield {
                        "id_simulacao": "-".join(filter(None, (prefixo, tipo, banda, str(repeticao) if repeticao else ""))),
                        **base, "excitacao": tipo, "banda": banda,
                        "semente_ruido": semente,
                        "fmin_Hz": fn * limites[0] if limites else None,
                        "fmax_Hz": fn * limites[1] if limites else None,
                        "F_degrau_N": k * escala if tipo == "degrau" else None,
                        "J_impulso_N_s": m * wn * escala if tipo == "impulso" else None,
                        "F_ruido_rms_N": k * escala if tipo == "ruido" else None,
                    }


def resposta(caso, refinamento=1):
    m, k, c = (float(caso[chave]) for chave in ("m_kg", "k_N_m", "c_N_s_m"))
    tipo = caso["excitacao"]
    tempo = np.arange(AMOSTRAS * refinamento + 1) / (FS_HZ * refinamento)
    alfa = c / (2 * m)
    wd = np.sqrt(k / m - alfa**2)
    x0, v0 = (float(caso[chave]) for chave in ("x0_m", "v0_m_s"))
    if tipo == "degrau":
        forca = np.full_like(tempo, float(caso["F_degrau_N"]))
        xp, vp = forca / k, np.zeros_like(tempo)
    elif tipo == "impulso":
        forca = xp = vp = np.zeros_like(tempo)
        v0 += float(caso["J_impulso_N_s"]) / m
    else:
        rng = np.random.default_rng(int(caso["semente_ruido"]))
        frequencias = np.fft.rfftfreq(AMOSTRAS, 1 / FS_HZ)
        banda = (frequencias >= float(caso["fmin_Hz"])) & (frequencias <= float(caso["fmax_Hz"]))
        if banda.sum() < 2 or banda[-1]:
            raise ValueError("A banda requer pelo menos dois bins e deve ficar abaixo de Nyquist.")
        # FFT de ruído gaussiano branco, com retenção apenas dos bins desejados.
        F = np.fft.rfft(rng.standard_normal(AMOSTRAS))
        F[~banda] = 0
        rms = np.sqrt(2 * np.sum(abs(F)**2)) / AMOSTRAS
        F *= float(caso["F_ruido_rms_N"]) / rms
        jw = 2j * np.pi * frequencias
        X = F / (k + c * jw + m * jw**2)
        n = AMOSTRAS * refinamento
        forca, xp, vp = [
            np.append(amostras, amostras[0])
            for amostras in (np.fft.irfft(espectro * refinamento, n=n) for espectro in (F, X, jw * X))
        ]

    # A resposta homogênea impõe as condições iniciais à solução particular.
    A = x0 - xp[0]
    B = (v0 - vp[0] + alfa * A) / wd
    decaimento = np.exp(-alfa * tempo)
    co, si = np.cos(wd * tempo), np.sin(wd * tempo)
    xh = decaimento * (A * co + B * si)
    x = xp + xh
    v = vp + decaimento * wd * (-A * si + B * co) - alfa * xh
    a = (forca - c * v - k * x) / m
    return tempo, forca, x, v, a


def indicadores(serie):
    tempo, _, *sinais = serie
    rotulos = ("x", "v", "a")
    unidades = ("m", "m_s", "m_s2")
    saida = {}
    for nome, unidade, sinal in zip(rotulos, unidades, sinais):
        quadrado = sinal**2
        integral = (tempo[1] - tempo[0]) * (quadrado.sum() - (quadrado[0] + quadrado[-1]) / 2)
        saida[f"{nome}_rms_{unidade}"] = float(np.sqrt(integral / tempo[-1]))
        saida[f"{nome}_pico_abs_{unidade}"] = float(np.max(abs(sinal)))
    return saida


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("csv_origem", type=Path, help="CSV harmônico original ou CSV expandido com --serie")
    parser.add_argument("saida", type=Path, help="CSV a gravar")
    parser.add_argument("--serie", help="id_simulacao para exportar uma série temporal do banco expandido")
    args = parser.parse_args()
    if args.csv_origem.resolve() == args.saida.resolve():
        parser.error("Escolha um caminho de saída diferente da origem.")

    if args.serie:
        with args.csv_origem.open(encoding="utf-8-sig", newline="") as arquivo:
            caso = next((r for r in csv.DictReader(arquivo) if r["id_simulacao"] == args.serie), None)
        if caso is None:
            parser.error("id_simulacao não encontrado.")
        np.savetxt(
            args.saida, np.column_stack(resposta(caso)), delimiter=",",
            header="t_s,F_regular_N,x_m,v_m_s,a_regular_m_s2", comments="", fmt="%.12g",
        )
        return

    sistemas = sistemas_do_banco(args.csv_origem)
    linhas = [{**caso, **indicadores(resposta(caso))} for caso in casos(sistemas)]
    with args.saida.open("w", encoding="utf-8", newline="") as arquivo:
        writer = csv.DictWriter(arquivo, fieldnames=linhas[0].keys())
        writer.writeheader()
        writer.writerows(linhas)
    print(f"{len(linhas)} simulações a partir de {len(sistemas)} sistemas de referência.")


if __name__ == "__main__":
    main()
