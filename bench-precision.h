#ifndef BENCH_PRECISION_H
#define BENCH_PRECISION_H
#include <fftw3.h>
#ifdef BENCH_SINGLE
 typedef float bench_real;
 #define BENCH_FFTW(name) fftwf_ ## name
#else
 typedef double bench_real;
 #define BENCH_FFTW(name) fftw_ ## name
#endif
#endif
