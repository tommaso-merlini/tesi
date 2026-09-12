# Tempi per architettura

Quattro combinazioni, ciascuna con la stessa struttura. Ogni immagine contiene c2c, c2r, r2c e r2r, con ARM, RISC-V e x86 nello stesso pannello. Assi lineari, valori X misurati e tempi in ns, µs, ms o s.

## double_vector

| Esperimento | 1D | 2D | 3D |
|---|---|---|---|
| Size | [1D](double_vector/size/1d.png) | [2D](double_vector/size/2d.png) | [3D](double_vector/size/3d.png) |
| Threads | [1D](double_vector/threads/1d.png) | [2D](double_vector/threads/2d.png) | [3D](double_vector/threads/3d.png) |
| Threads size · N=16 | [1D](double_vector/threadssize/1d/16.png) | [2D](double_vector/threadssize/2d/16.png) | [3D](double_vector/threadssize/3d/16.png) |
| Threads size · N=64 | [1D](double_vector/threadssize/1d/64.png) | [2D](double_vector/threadssize/2d/64.png) | [3D](double_vector/threadssize/3d/64.png) |

## double_novector

| Esperimento | 1D | 2D | 3D |
|---|---|---|---|
| Size | [1D](double_novector/size/1d.png) | [2D](double_novector/size/2d.png) | [3D](double_novector/size/3d.png) |
| Threads | [1D](double_novector/threads/1d.png) | [2D](double_novector/threads/2d.png) | [3D](double_novector/threads/3d.png) |
| Threads size · N=16 | [1D](double_novector/threadssize/1d/16.png) | [2D](double_novector/threadssize/2d/16.png) | [3D](double_novector/threadssize/3d/16.png) |
| Threads size · N=64 | [1D](double_novector/threadssize/1d/64.png) | [2D](double_novector/threadssize/2d/64.png) | [3D](double_novector/threadssize/3d/64.png) |

## single_vector

| Esperimento | 1D | 2D | 3D |
|---|---|---|---|
| Size | [1D](single_vector/size/1d.png) | [2D](single_vector/size/2d.png) | [3D](single_vector/size/3d.png) |
| Threads | [1D](single_vector/threads/1d.png) | [2D](single_vector/threads/2d.png) | [3D](single_vector/threads/3d.png) |
| Threads size · N=16 | [1D](single_vector/threadssize/1d/16.png) | [2D](single_vector/threadssize/2d/16.png) | [3D](single_vector/threadssize/3d/16.png) |
| Threads size · N=64 | [1D](single_vector/threadssize/1d/64.png) | [2D](single_vector/threadssize/2d/64.png) | [3D](single_vector/threadssize/3d/64.png) |

## single_novector

| Esperimento | 1D | 2D | 3D |
|---|---|---|---|
| Size | [1D](single_novector/size/1d.png) | [2D](single_novector/size/2d.png) | [3D](single_novector/size/3d.png) |
| Threads | [1D](single_novector/threads/1d.png) | [2D](single_novector/threads/2d.png) | [3D](single_novector/threads/3d.png) |
| Threads size · N=16 | [1D](single_novector/threadssize/1d/16.png) | [2D](single_novector/threadssize/2d/16.png) | [3D](single_novector/threadssize/3d/16.png) |
| Threads size · N=64 | [1D](single_novector/threadssize/1d/64.png) | [2D](single_novector/threadssize/2d/64.png) | [3D](single_novector/threadssize/3d/64.png) |

- **Size:** varia N per asse; thread fissi diversi: ARM 72, RISC-V 64, x86 144.
- **Threads:** varia il numero di thread; N=64 per asse.
- **Threads size:** un file per size, in `threadssize/<rango>d/<size>.png`; N disponibili: 16 e 64.

Confrontare i punti condivisi tra sistemi. I tempi sono medie di 100 iterazioni, senza intervalli di confidenza.

Per rigenerare i grafici:

```bash
python3 analisi_dati/plot.py
```
