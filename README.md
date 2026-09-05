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
  --vector rvv \
  --openmp
```

Flag disponibili:
  `--source`: il path del tarball fftw
  `--prefix`: il path dove si vuole compilare fftw
  `--precision`: single|double 
  `--vector`: rvv|norvv
  `--openmp`: (disabilitato di default) 

## Compilare il Benchmark

Compila il benchmark linkando fftw:

```bash
./compile-bench-threads.sh \
  --fftw-prefix ./fftw3-rvv  \
  --compiler gcc \
  --vector rvv  
```

Flag disponibili:
  `--fftw-prefix`: il path di  fftw
  `--compiler`: gcc|llvm
  `--vector`: rvv|norvv

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
