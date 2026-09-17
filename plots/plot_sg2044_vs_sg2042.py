"""Esegui con: python3 plots/plot_sg2044_vs_sg2042.py (richiede matplotlib)."""

from pathlib import Path
import os
import re

os.environ.setdefault("MPLCONFIGDIR", "/tmp/fftw-matplotlib")
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt

ROOT = Path(__file__).resolve().parent.parent

SG2044 = ROOT / "results-newer/fftw-riscv-sg2044-domain-20260913-190703"
SG2042 = (
    ROOT / "results-newer/fftw-riscv-sg2042-domain-20260914-140127"
)  # Placeholder: dati ancora assenti.
OUTPUT = ROOT / "plots" / "plots-sg2044-vs-sg2042"

CASI = [(3, 256), (2, 4096), (1, 2**24)]


def read(percorso, precisione, dimensione, n):
    cartella = percorso / f"{precisione}-novector/{dimensione}d/size_{n}"
    forma = "x".join([str(n)] * dimensione)
    pattern = (
        rf"c2c {dimensione}d {forma} avg_seconds=(\S+) iterations=\d+ threads=(\d+)"
    )
    punti = []
    for file in cartella.glob("threads_*/result.txt"):
        for riga in file.read_text().splitlines():
            match = re.fullmatch(pattern, riga.strip())
            if match:
                secondi, threads = match.groups()
                punti.append((int(threads), float(secondi)))
    return sorted(punti)


def main():
    OUTPUT.mkdir(exist_ok=True)
    for dimensione, n in CASI:
        fig, ax = plt.subplots(figsize=(9, 6))
        ticks = set()
        for chip, percorso, colore in [
            ("SG2044", SG2044, "tab:blue"),
            ("SG2042", SG2042, "tab:orange"),
        ]:
            for precisione, stile, marker in [
                ("single", "-", "o"),
                ("double", "--", "s"),
            ]:
                label = f"{chip} {precisione}"
                punti = read(percorso, precisione, dimensione, n)
                if not punti:
                    continue
                threads, secondi = zip(*punti)
                ticks.update(threads)
                ax.plot(
                    threads,
                    secondi,
                    color=colore,
                    linestyle=stile,
                    marker=marker,
                    label=label,
                )

        ax.set_title(f"c2c - {dimensione}D - novect - N = {n:,}")
        ax.set_xlabel("Thread", fontsize=16)
        ax.set_ylabel("Tempo medio (s)", fontsize=16)
        ax.set_ylim(bottom=0)
        ax.tick_params(axis="both", labelsize=14)
        ax.set_xscale("log", base=2)
        ax.set_xticks(sorted(ticks), labels=[str(t) for t in sorted(ticks)])
        if ticks:
            ax.legend(fontsize=14)
        ax.grid(True, alpha=0.3)
        fig.tight_layout(rect=(0, 0.06, 1, 1))
        destinazione = OUTPUT / f"c2c_{dimensione}d_novect_N{n}.png"
        fig.savefig(destinazione, dpi=180)
        plt.close(fig)
        print(destinazione)


if __name__ == "__main__":
    main()
