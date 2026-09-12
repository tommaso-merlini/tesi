"""Rigenera i grafici leggendo results (tutte le precisioni e modalità vettoriali)."""
from pathlib import Path
import os
import re

os.environ.setdefault('MPLCONFIGDIR', '/tmp/fftw-matplotlib')
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D
from matplotlib.ticker import FuncFormatter

ROOT = Path(__file__).resolve().parent
ARCHITETTURE = {'arm': ('ARM', '#2678b8'), 'riscv': ('RISC-V', '#e08a24'), 'x86': ('x86', '#259767')}
SEZIONI = {'size': 'size', 'threads': 'threads', 'threadssize': 'threads-size'}
COMBINAZIONI = ['double_vector', 'double_novector', 'single_vector', 'single_novector']
TRASFORMATE = ['c2c', 'c2r', 'r2c', 'r2r']


def leggi_dati():
    dati = []
    for file in (ROOT.parent / 'results').glob('*/*/*.txt'):
        arch, precisione, modo = file.parent.name.split('-')[-3:]
        for riga in file.read_text().splitlines():
            if not riga or riga.startswith('#'):
                continue
            match = re.fullmatch(
                r'(c2c|c2r|r2c|r2r) ([123])d ([0-9x]+) avg_seconds=(\S+) iterations=(\d+) threads=(\d+)', riga
            )
            if not match:
                raise ValueError(f'Riga non riconosciuta in {file}: {riga}')
            tipo, rango, forma, secondi, _, threads = match.groups()
            dati.append(dict(combinazione=f'{precisione}_{modo}', arch=arch, suite=file.stem, tipo=tipo, rango=int(rango),
                             N=int(forma.split('x')[0]), secondi=float(secondi), threads=int(threads)))
    return dati


def unita_tempo(massimo):
    for soglia, fattore, unita in [(1e-6, 1e9, 'ns'), (1e-3, 1e6, 'µs'), (1, 1e3, 'ms')]:
        if massimo < soglia:
            return fattore, unita
    return 1, 's'


def numero(valore, posizione):
    return f'{valore:.3f}'.rstrip('0').rstrip('.').replace('.', ',')


def grafico(dati, combinazione, cartella, suite, rango, size=None):
    selezione = [r for r in dati if r['suite'] == suite and r['rango'] == rango]
    if size is not None:
        selezione = [r for r in selezione if r['N'] == size]
    asse_x = 'N' if suite == 'size' else 'threads'
    figura, pannelli = plt.subplots(2, 2, figsize=(13, 9))

    for ax, tipo in zip(pannelli.flat, TRASFORMATE):
        righe = [r for r in selezione if r['tipo'] == tipo]
        fattore, unita = unita_tempo(max(r['secondi'] for r in righe))
        for arch, (nome, colore) in ARCHITETTURE.items():
            punti = sorted([r for r in righe if r['arch'] == arch], key=lambda r: r[asse_x])
            if not punti:
                raise ValueError(f'Dati mancanti: {suite}, {rango}D, {tipo}, {arch}, N={size}')
            ax.plot([r[asse_x] for r in punti], [r['secondi'] * fattore for r in punti],
                    color=colore, linestyle='-', marker='o', markersize=4, label=nome)

        ax.set_xlim(left=0)
        ax.set_ylim(bottom=0)
        valori_x = sorted({r[asse_x] for r in righe})
        ax.set_xticks(valori_x, [str(v) for v in valori_x], rotation=90)
        ax.tick_params(axis='x', labelsize=9, pad=4)
        # Sfalsa le etichette vicine senza cambiare la scala lineare.
        if asse_x == 'threads':
            for etichetta, valore in zip(ax.get_xticklabels(), valori_x):
                if valore in (2, 4):
                    etichetta.set_y(-.045 if valore == 2 else -.09)
        ax.yaxis.set_major_formatter(FuncFormatter(numero))
        ax.set_xlabel('N per asse' if suite == 'size' else 'Thread')
        ax.set_ylabel(f'Tempo medio ({unita})')
        ax.set_title(tipo, fontweight='bold')

    figura.suptitle(f'{cartella.replace("_", " ")} · {rango}D | {combinazione.replace("_", " · ")}',
                    fontsize=19, fontweight='bold', y=.99)
    note = {'size': 'N variabile · thread fissi: ARM 72, RISC-V 64, x86 144',
            'threads': 'N=64 per asse · thread variabili',
            'threads-size': f'N={size} per asse · thread variabili'}
    figura.text(.5, .94, note[suite], ha='center')
    legenda = [Line2D([0], [0], color=colore, marker='o', label=nome)
               for nome, colore in ARCHITETTURE.values()]
    figura.legend(handles=legenda, loc='upper center', bbox_to_anchor=(.5, .923),
                  ncol=len(legenda), frameon=False)
    figura.tight_layout(rect=(0, 0, 1, .86))
    destinazione = ROOT / combinazione / cartella
    if size is not None:
        destinazione = destinazione / f'{rango}d'
    destinazione.mkdir(parents=True, exist_ok=True)
    nome_file = f'{size}.png' if size is not None else f'{rango}d.png'
    figura.savefig(destinazione / nome_file, dpi=170)
    plt.close(figura)


if __name__ == '__main__':
    plt.rcParams.update({'font.size': 11, 'axes.spines.top': False, 'axes.spines.right': False,
                         'axes.grid': True, 'grid.alpha': .2})
    dati = leggi_dati()
    for combinazione in COMBINAZIONI:
        selezione = [r for r in dati if r['combinazione'] == combinazione]
        for cartella, suite in SEZIONI.items():
            for rango in (1, 2, 3):
                sizes = sorted({r['N'] for r in selezione if r['suite'] == suite and r['rango'] == rango}) if suite == 'threads-size' else [None]
                for size in sizes:
                    grafico(selezione, combinazione, cartella, suite, rango, size)
    print('Grafici aggiornati.')
