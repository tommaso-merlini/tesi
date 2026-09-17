"""Esegui con python3 plots/plot_confronti_3d.py (richiede matplotlib).

Percorsi e N sono definiti in plot_3d_per_macchina.py.
"""

import math

from plot_3d_per_macchina import MACCHINE, N, ROOT, read, plt

OUTPUT = ROOT / "plots" / "plots-confronti-3d"
COLORI = {
    "sg2044": "tab:blue",
    "sg2042": "tab:orange",
    "arm": "tab:green",
    "x86": "tab:red",
}


def rapporto(numeratore, denominatore):
    # Un rapporto esiste solo se entrambi i tempi sono disponibili e positivi.
    return {
        t: numeratore.get(t, math.nan) / denominatore[t]
        if denominatore.get(t, 0) > 0
        else math.nan
        for t in numeratore.keys() | denominatore.keys()
    }


def grafico(nome, titolo, ylabel, serie, guadagno=False):
    fig, ax = plt.subplots(figsize=(9, 6))
    ticks = sorted({t for _, _, _, punti in serie for t in punti})
    for macchina, variante, indice, punti in serie:
        label = f"{macchina.upper()} {variante}"
        if not any(math.isfinite(v) for v in punti.values()):
            continue
        # NaN interrompe la linea anche dove manca completamente il file.
        ax.plot(
            ticks,
            [punti.get(t, math.nan) for t in ticks],
            color=COLORI[macchina],
            linestyle=["-", "--"][indice],
            marker=["o", "s"][indice],
            label=label,
        )
    if guadagno:
        ax.axhline(1, color="gray", linestyle=":", linewidth=1)
    ax.set_title(f"{titolo} - c2c - 3D - N = {N:,}")
    ax.set_xlabel("Thread", fontsize=16)
    ax.set_ylabel(ylabel, fontsize=16)
    ax.set_ylim(bottom=0)
    ax.tick_params(axis="both", labelsize=14)
    ax.set_xscale("log", base=2)
    ax.set_xticks(ticks, labels=[str(t) for t in ticks])
    if ax.get_legend_handles_labels()[0]:
        ax.legend(ncol=2, fontsize=14)
    ax.grid(True, alpha=0.3)
    fig.tight_layout(rect=(0, 0.06, 1, 1))
    destinazione = OUTPUT / f"{nome}_N{N}.png"
    fig.savefig(destinazione, dpi=180)
    plt.close(fig)
    print(destinazione)


def main():
    OUTPUT.mkdir(exist_ok=True)
    dati = {
        (macchina, precisione, modo): dict(read(percorso, precisione, modo))
        for macchina, percorso in MACCHINE.items()
        for precisione in ["single", "double"]
        for modo in ["vector", "novector"]
    }

    tempi, vettorizzazione, precisione = [], [], []
    for macchina in MACCHINE:
        for i, p in enumerate(["single", "double"]):
            tempi.append((macchina, p, i, dati[macchina, p, "vector"]))
        vettorizzazione.append(
            (
                macchina,
                "single",
                0,
                rapporto(
                    dati[macchina, "single", "novector"],
                    dati[macchina, "single", "vector"],
                ),
            )
        )
        precisione.append(
            (
                macchina,
                "vector",
                0,
                rapporto(
                    dati[macchina, "double", "vector"],
                    dati[macchina, "single", "vector"],
                ),
            )
        )

    grafico("tempi_vector", "Confronto vector", "Tempo medio (s)", tempi)
    grafico(
        "guadagno_vector",
        "Guadagno della vettorizzazione (single)",
        "Guadagno (tempo novector / tempo vector)",
        vettorizzazione,
        True,
    )
    grafico(
        "guadagno_single",
        "Guadagno della single precision (vector)",
        "Guadagno (tempo double / tempo single)",
        precisione,
        True,
    )


if __name__ == "__main__":
    main()
