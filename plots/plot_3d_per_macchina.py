"""Esegui con: python3 plots/plot_3d_per_macchina.py (richiede matplotlib)."""

from pathlib import Path
import os
import re

os.environ.setdefault("MPLCONFIGDIR", "/tmp/fftw-matplotlib")
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt

ROOT = Path(__file__).resolve().parent.parent

# Percorsi dei risultati e dimensione per asse, modificabili qui.
MACCHINE = {
    "sg2044": ROOT / "results-newer/fftw-riscv-sg2044-domain-20260913-190703",
    "sg2042": ROOT / "results-newer/fftw-riscv-sg2042-domain-20260914-140127",
    "arm": ROOT / "results-newer/fftw-arm-domain-20260912-233523",
    "x86": ROOT / "results-newer/fftw-x86-domain-20260912-233540",
}
N = 256
OUTPUT = ROOT / "plots" / "plots-3d-per-macchina"


def read(percorso, precisione, modo):
    cartella = percorso / f"{precisione}-{modo}/3d/size_{N}"
    pattern = rf"c2c 3d {N}x{N}x{N} avg_seconds=(\S+) iterations=\d+ threads=(\d+)"
    punti = []
    for file in cartella.glob("threads_*/result.txt"):
        testo = file.read_text().strip()
        match = re.fullmatch(pattern, testo)
        threads = int(file.parent.name.split("_")[1])
        if match:
            secondi, threads = match.groups()
            punti.append((int(threads), float(secondi)))
        else:
            print(f"  Risultato assente o non valido: {file}")
            punti.append((threads, float("nan")))
    return sorted(punti)


def main():
    OUTPUT.mkdir(exist_ok=True)
    for macchina, percorso in MACCHINE.items():
        fig, ax = plt.subplots(figsize=(9, 6))
        ticks = set()
        for modo, colore in [("vector", "tab:blue"), ("novector", "tab:orange")]:
            for precisione, stile, marker in [
                ("single", "-", "o"),
                ("double", "--", "s"),
            ]:
                label = f"{modo} {precisione}"
                punti = read(percorso, precisione, modo)
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

        ax.set_title(f"{macchina.upper()} - c2c - 3D - N = {N:,}")
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
        destinazione = OUTPUT / f"{macchina}_c2c_3d_N{N}.png"
        fig.savefig(destinazione, dpi=180)
        plt.close(fig)
        print(destinazione)


if __name__ == "__main__":
    main()
