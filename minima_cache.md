# Dimensione minima che supera la cache L3

calcolo del **minimo N pari** per cui gli array di input e output del benchmark non entrano interamente nella cache L3
## Capacità considerate

| Architettura | Processore / sistema | Cache L3 considerata | Byte |
|---|---|---:|---:|
| RISC-V | SOPHON SG2044 | 64 MiB | 67.108.864 |
| ARM | NVIDIA Grace CPU Superchip, due CPU | 228 MiB complessivi | 239.075.328 |
| x86 | Intel Xeon Platinum 8458P, un processore | 82,5 MiB | 86.507.520 |

## Formule della memoria

- N: dimensione del problema.
- d: rango.
- s: byte per numero reale, 8 per double e 4 per single.
- Un numero complesso occupa 2s byte.
- C: capacità della cache in byte.

| Trasformata | Input | Output | Memoria totale M(N) |
|---|---|---|---|
| c2c | Nᵈ complessi | Nᵈ complessi | 4sNᵈ |
| r2c | Nᵈ reali | Nᵈ⁻¹(N/2 + 1) complessi | 2s(Nᵈ + Nᵈ⁻¹) |
| c2r | Nᵈ⁻¹(N/2 + 1) complessi | Nᵈ reali | 2s(Nᵈ + Nᵈ⁻¹) |
| r2r | Nᵈ reali | Nᵈ reali | 2sNᵈ |

---

## RISC-V

Capacità: **67.108.864 byte**.

| Precisione | Trasformata | N minimo pari 1D | N minimo pari 2D | N minimo pari 3D |
|---|---|---:|---:|---:|
| double | c2c | 2.097.154 | 1.450 | 130 |
| double | r2c / c2r | 4.194.304 | 2.048 | 162 |
| double | r2r | 4.194.306 | 2.050 | 162 |
| single | c2c | 4.194.306 | 2.050 | 162 |
| single | r2c / c2r | 8.388.608 | 2.896 | 204 |
| single | r2r | 8.388.610 | 2.898 | 204 |

## ARM

Capacità: **239.075.328 byte**.

| Precisione | Trasformata | N minimo pari 1D | N minimo pari 2D | N minimo pari 3D |
|---|---|---:|---:|---:|
| double | c2c | 7.471.106 | 2.734 | 196 |
| double | r2c / c2r | 14.942.208 | 3.866 | 246 |
| double | r2r | 14.942.210 | 3.866 | 248 |
| single | c2c | 14.942.210 | 3.866 | 248 |
| single | r2c / c2r | 29.884.416 | 5.468 | 310 |
| single | r2r | 29.884.418 | 5.468 | 312 |

## x86

Capacità: **86.507.520 byte**.

| Precisione | Trasformata | N minimo pari 1D | N minimo pari 2D | N minimo pari 3D |
|---|---|---:|---:|---:|
| double | c2c | 2.703.362 | 1.646 | 140 |
| double | r2c / c2r | 5.406.720 | 2.326 | 176 |
| double | r2r | 5.406.722 | 2.326 | 176 |
| single | c2c | 5.406.722 | 2.326 | 176 |
| single | r2c / c2r | 10.813.440 | 3.288 | 222 |
| single | r2r | 10.813.442 | 3.290 | 222 |
