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
