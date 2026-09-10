#!/usr/bin/env bash
set -euo pipefail

source_dir=""
prefix=""
precision=""
vector_enabled=false
arch="riscv"
openmp=false

usage() {
  cat <<EOF
Usage: $0 --source DIR --prefix DIR --precision single|double [options]
  --source DIR        FFTW source directory containing bootstrap.sh
  --prefix DIR        Installation directory
  --precision single|double
  --arch riscv|arm|x86 Target architecture (default: riscv, 64-bit targets)
  --vector            Enable architecture-specific SIMD (default: off)
  --openmp            Enable OpenMP (default: off)
  --no-openmp         Disable OpenMP
  -h, --help          Show this help

Vector targets: RISC-V RVV, ARM SVE, x86 AVX-512 (x86-64-v4).
Without --vector, SIMD backends are disabled; -O3 may still auto-vectorize.
Override the compiler with GCC. --arch does not select a cross-compiler.
EOF
}

need_value() {
  if (($# < 2)); then
    echo "missing value for $1" >&2
    usage >&2
    exit 1
  fi
}

while (($# > 0)); do
  case "$1" in
    --source)
      need_value "$@"
      source_dir="$2"
      shift 2
      ;;
    --prefix)
      need_value "$@"
      prefix="$2"
      shift 2
      ;;
    --precision)
      need_value "$@"
      precision="$2"
      shift 2
      ;;
    --arch)
      need_value "$@"
      arch="$2"
      shift 2
      ;;
    --vector)
      vector_enabled=true
      shift
      ;;
    --openmp)
      openmp=true
      shift
      ;;
    --no-openmp)
      openmp=false
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "$source_dir" || -z "$prefix" || -z "$precision" ]]; then
  echo "--source, --prefix and --precision are required" >&2
  usage >&2
  exit 1
fi

case "$precision" in
  single) precision_flag="--enable-single" ;;
  double) precision_flag="--disable-single" ;;
  *)
    echo "--precision must be single or double" >&2
    exit 1
    ;;
esac

cflags=(-O3)
configure_flags=(
  "--prefix=$prefix"
  "$precision_flag"
  --disable-fortran
  --disable-doc
  --enable-threads
)

case "$arch" in
  riscv|riscv64) arch="riscv" ;;
  arm|aarch64|arm64) arch="arm" ;;
  x86|x86_64|amd64) arch="x86" ;;
  *)
    echo "--arch must be riscv, arm, or x86 (64-bit targets)" >&2
    exit 1
    ;;
esac

# disabilita esplicitamente la vettorizazzione per ogni architettura
for backend in rvv sve neon sse sse2 avx avx2 avx512 avx-128-fma kcvi altivec vsx generic-simd128 generic-simd256; do
  configure_flags+=("--disable-$backend")
done

if [[ "$vector_enabled" == true ]]; then
  case "$arch" in
    riscv)
      cflags+=(-march=rv64gcv -mabi=lp64d)
      configure_flags+=(--enable-rvv)
      ;;
    arm)
      cflags+=(-march=armv8-a+sve)
      configure_flags+=(--enable-sve --enable-armv8-cntvct-el0)
      ;;
    x86)
      cflags+=(-march=x86-64-v4)
      configure_flags+=(--enable-avx --enable-avx2 --enable-avx512 --enable-avx-128-fma)
      ;;
  esac
fi

if [[ "$openmp" == true ]]; then
  cflags+=(-fopenmp)
  configure_flags+=(--enable-openmp)
else
  configure_flags+=(--disable-openmp)
fi

compiler="${GCC:-gcc}"

source_dir="$(cd "$source_dir" && pwd)"
mkdir -p "$prefix"
prefix="$(cd "$prefix" && pwd)"
configure_flags[0]="--prefix=$prefix"

cd "$source_dir"
CC="$compiler" CFLAGS="${cflags[*]}" ./bootstrap.sh "${configure_flags[@]}"
make -j"$(nproc)"
make install
