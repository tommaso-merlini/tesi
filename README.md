## FFTW

installare fftw:

```bash
./install-fftw.sh
```

compilare fftw:

```bash
./compile-fftw.sh \
  --source ./fftw3-pr408 \
  --prefix ./fftw3-rvv \
  --precision double \
  --arch riscv \
  --vector \
  --openmp
```

Flag disponibili:
  `--source`: directory dei sorgenti FFTW contenente `bootstrap.sh`
  `--prefix`: il path dove si vuole compilare fftw
  `--precision`: single|double 
  `--arch`: riscv|arm|x86 (default: riscv; stessi alias del benchmark)
  `--vector`: switch senza valore, abilita i backend SIMD per l’architettura scelta
  `--openmp`: (disabilitato di default) 

Con `--vector`, RISC-V usa RVV (`--enable-rvv`), ARM usa SVE (`--enable-sve`) e x86 abilita SSE2, AVX, AVX2 e AVX-512. Le flag del compilatore sono le stesse riportate nella tabella del benchmark.
Senza `--vector`, i backend SIMD sono disabilitati esplicitamente, ma `-O3` può ancora vettorizzare automaticamente il codice.
`--arch` non seleziona un cross-compilatore; il compilatore si può indicare tramite `GCC`.
I sorgenti FFTW devono supportare il backend scelto (per RVV viene usata la versione scaricata da `install-fftw.sh`).

## Compilare più varianti di FFTW

Lo script `compile-fftw-all.sh` compila tutte le combinazioni di precisione e backend vettoriali per le architetture indicate.

```bash
./compile-fftw-all.sh \
  --riscv /percorso/sorgenti-fftw-riscv \
  --arm /percorso/sorgenti-fftw-arm \
  --x86 /percorso/sorgenti-fftw-x86 \
  --output ./fftw-builds
```

Per ogni architettura indicata produce quattro installazioni: `ARCH-single-vector`,
`ARCH-single-novector`, `ARCH-double-vector`, `ARCH-double-novector`.
I log si trovano in `fftw-builds/logs/`. `--output` è facoltativo (default: `fftw-builds` accanto allo script).

## Compilare il Benchmark

Compila il benchmark linkando fftw:

```bash
./compile-bench-threads.sh \
  --source ./bench-threads.c \
  --output ./bench-threads-rvv \
  --fftw-prefix ./fftw3-rvv  \
  --compiler gcc \
  --arch riscv \
  --vector
```

Flag disponibili:
  `--source`: file sorgente del benchmark (default: `bench-threads.c` nella cartella dello script)
  `--output`: nome o percorso dell'eseguibile (default: `bench-threads` nella cartella dello script)
  `--fftw-prefix`: il path di  fftw
  `--compiler`: gcc|llvm
  `--precision`: single|double (default: double; single definisce `BENCH_SINGLE`)
  `--arch`: riscv|arm|x86 (default: riscv; tutte architetture a 64 bit)
  `--vector`: switch senza valore che aggiunge le opzioni vettoriali (disabilitato di default)

I percorsi relativi passati a `--source` e `--output` sono riferiti alla directory corrente.
Se si sceglie un nome diverso per l'eseguibile, passarlo agli script di scaling con `--benchmark`, ad esempio `--benchmark ./bench-threads-rvv`.

Lo script unico sostituisce anche `compile-bench-threads-arm.sh` e `compile-bench-threads-x86.sh`.

| Architettura | Flag aggiunte con `--vector` |
| --- | --- |
| `riscv` | `-march=rv64gcv -mabi=lp64d` |
| `arm` | `-march=armv8-a+sve` |
| `x86` | `-march=x86-64-v4` |

Sono accettati anche gli alias `riscv64`, `aarch64`, `arm64`, `x86_64` e `amd64`.
Senza `--vector` non vengono aggiunte opzioni specifiche di architettura: questo non disabilita l'eventuale vettorizzazione predefinita del compilatore o della libreria FFTW.
Le opzioni vettoriali riprendono quelle dei tre script originali; il processore di destinazione deve supportarle.
`--arch` non seleziona un compilatore cross: usare `GCC` o `CLANG` per indicare il compilatore adatto.
Con `--arch riscv --vector`, il prefisso FFTW predefinito resta `./fftw3-rvv` nella cartella dello script; negli altri casi viene usata FFTW di sistema, salvo `--fftw-prefix` esplicito.
Le opzioni riguardano la compilazione del benchmark; la libreria FFTW deve essere compilata separatamente per la destinazione scelta.

## Eseguire il benchmark

## Scaling del numero di thread

Esegue il benchmark variando il numero di thread e mantenendo fissa la dimensione della trasformata:

```bash
./scale-threads.sh \
  --threads 1,2,4,8 \
  --size 64 \
  --transforms c2c,r2c \
  --ranks 1,2,3 \
  --iterations 100
```

Flag disponibili:
  `--threads`: lista dei thread (di default usa le potenze di due fino al numero di CPU disponibili)
  `--size`: dimensione `N` fissa (default: 64)
  `--transforms`: c2c,r2c,c2r,r2r (di default tutte)
  `--ranks`: 1,2,3 (di default tutti)
  `--iterations`: numero di esecuzioni da mediare (default: 100)
  `--benchmark`: path dell'eseguibile del benchmark (default: `./bench-threads`)

## Scaling della dimensione

Esegue il benchmark variando la dimensione della trasformata e mantenendo fisso il numero di thread:

```bash
./scale-size.sh \
  --thread 4 \
  --sizes 16,32,64,128 \
  --transforms r2c,r2r \
  --ranks 1,2,3 \
  --iterations 100
```

Flag disponibili:
  `--thread`: numero di thread fisso (default: 1)
  `--sizes`: lista delle dimensioni `N` (default: 16,32,64)
  `--transforms`: c2c,r2c,c2r,r2r (di default tutte)
  `--ranks`: 1,2,3 (di default tutti)
  `--iterations`: numero di esecuzioni da mediare (default: 100)
  `--benchmark`: path dell'eseguibile del benchmark (default: `./bench-threads`)

## Scaling di thread e dimensione

Esegue il prodotto cartesiano tra i numeri di thread e le dimensioni indicate:

```bash
./scale-threads-size.sh \
  --threads 1,2,4,8 \
  --sizes 16,32,64,128 \
  --transforms c2c,r2c,c2r,r2r \
  --ranks 1,2,3 \
  --iterations 100
```

Flag disponibili:
  `--threads`: lista dei thread (di default usa le potenze di due fino al numero di CPU disponibili)
  `--sizes`: lista delle dimensioni `N` (default: 16,32,64)
  `--transforms`: c2c,r2c,c2r,r2r (di default tutte)
  `--ranks`: 1,2,3 (di default tutti)
  `--iterations`: numero di esecuzioni da mediare (default: 100)
  `--benchmark`: path dell'eseguibile del benchmark (default: `./bench-threads`)

## Compilare il benchmark con tutte le build FFTW

```bash
./compile-bench-all.sh \
  --fftw-builds ./fftw-builds \
  --source ./bench-threads.c \
  --output ./benchmark-builds
```

`--fftw-builds` è obbligatorio. Lo script cerca le sottocartelle immediate chiamate
`ARCH-PRECISION-MODE`, ad esempio `x86-single-vector`, prodotte da `compile-fftw-all.sh`.
Ignora le altre cartelle, come `logs`, e genera un eseguibile per ogni installazione trovata:
`benchmark-builds/bench-threads-x86-single-vector`, ecc. I log sono in `benchmark-builds/logs/`.

- `--source`: sorgente da compilare (default: `bench-threads.c` accanto allo script).
- `--output`: cartella degli eseguibili (default: `benchmark-builds` accanto allo script).
- `--compiler gcc|llvm`: famiglia del compilatore (default: gcc).
- `--dry-run`: mostra i comandi senza compilare o creare file.

Architettura, precisione e switch `--vector` vengono ricavati dai nomi delle installazioni.
`bench-threads.c` e `bench-threads-2.c` supportano entrambe le precisioni tramite
`bench-precision.h`: single usa dati float e API `fftwf_*`, double usa dati double e API `fftw_*`.
I sorgenti personalizzati devono supportare `BENCH_SINGLE`; non basta collegare una libreria single a codice che usa l'API double.

Per ogni architettura si può indicare `GCC_RISCV`, `GCC_ARM`, `GCC_X86` (o le corrispondenti
`CLANG_*` con `--compiler llvm`). Il target del compilatore viene verificato prima di compilare;
servono toolchain e librerie di sistema adatte alle destinazioni richieste.
Le build FFTW devono contenere la libreria della precisione scelta e il backend `threads` oppure `omp`.
Lo script preferisce `threads`; se trova soltanto `omp`, aggiunge `-fopenmp` al collegamento.
`compile-fftw.sh` ora abilita anche `--enable-threads`; eventuali vecchie installazioni senza
backend di threading vanno ricompilate in una nuova cartella.
Le destinazioni già esistenti vengono rifiutate e lo script si ferma al primo errore.

## Eseguire le tre prove su tutti i benchmark compilati

```bash
./run-bench-all.sh \
  --benchmarks ./benchmark-builds \
  --output ./benchmark-results/prova-01
```

Lo script esegue in sequenza `scale-threads.sh`, `scale-size.sh` e
`scale-threads-size.sh` per ogni file eseguibile nella cartella indicata, senza
scendere nelle sottocartelle (ad esempio ignora `logs/`). La cartella deve contenere
benchmark eseguibili sulla macchina corrente, con le rispettive librerie FFTW disponibili.

I parametri sono fissati nelle quattro variabili all'inizio di `run-bench-all.sh`,
così tutti gli eseguibili ricevono le stesse prove:

| Variabile | Parametri iniziali |
| --- | --- |
| `common_flags` | Trasformate c2c,r2c,c2r,r2r; dimensioni 1D,2D,3D; 100 iterazioni |
| `threads_flags` | Thread 1,2,4,8; N=64 |
| `size_flags` | 4 thread; N=16,32,64 |
| `threads_size_flags` | Thread 1,2,4,8 × N=16,32,64 |

Modificare queste variabili per cambiare l'esperimento. Le impostazioni di warmup e
pianificazione restano quelle del sorgente compilato.

Per controllare i comandi senza eseguire i benchmark:

```bash
./run-bench-all.sh --benchmarks ./benchmark-builds --dry-run
```

`--output` è facoltativo: il default è `benchmark-results/DATA-ORA` accanto allo script.
La destinazione deve essere nuova per evitare di sovrascrivere risultati.
Ogni eseguibile ha una sottocartella con `threads.txt`, `size.txt`, `threads-size.txt`,
i corrispondenti file `.err` (errori) e `.command` (comandi esatti).
`summary.tsv` riporta stato ed exit code di tutte le prove. Se una prova fallisce,
lo script continua con le successive e termina con stato nonzero; i risultati della
prova fallita possono essere parziali.
