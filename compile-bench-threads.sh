#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
compiler_family="gcc"
vector_mode="norvv"
fftw_prefix=""

usage() {
  cat <<EOF
Usage: $0 [options]

Options:
  --compiler <gcc|llvm>    Select GCC or LLVM/Clang (default: gcc)
  --vector <rvv|norvv>     Enable or disable RVV compiler flags (default: norvv)
  --fftw-prefix <path>     FFTW installation containing include/ and lib/ or lib64/
  -h, --help               Show this help

RVV mode defaults to the FFTW prefix:
  $project_dir/fftw3-rvv

The selected FFTW installation must provide double-precision libfftw3 and
libfftw3_threads. Override compiler commands with GCC or CLANG, for example:
  GCC=riscv64-linux-gnu-gcc $0 --compiler gcc --vector rvv
EOF
}

while (($# > 0)); do
  case "$1" in
    --compiler)
      (($# >= 2)) || { echo "missing value for --compiler" >&2; usage >&2; exit 1; }
      compiler_family="$2"
      shift 2
      ;;
    --vector)
      (($# >= 2)) || { echo "missing value for --vector" >&2; usage >&2; exit 1; }
      vector_mode="$2"
      shift 2
      ;;
    --fftw-prefix)
      (($# >= 2)) || { echo "missing value for --fftw-prefix" >&2; usage >&2; exit 1; }
      fftw_prefix="$2"
      shift 2
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

case "$compiler_family" in
  gcc) compiler="${GCC:-gcc}" ;;
  llvm) compiler="${CLANG:-clang}" ;;
  *)
    echo "--compiler must be gcc or llvm" >&2
    exit 1
    ;;
esac

compile_flags=(-std=c11 -O3 -Wall -Wextra -Wpedantic)
link_flags=()

case "$vector_mode" in
  rvv)
    compile_flags+=(-march=rv64gcv -mabi=lp64d)
    if [[ -z "$fftw_prefix" ]]; then
      fftw_prefix="$project_dir/fftw3-rvv"
    fi
    ;;
  norvv) ;;
  *)
    echo "--vector must be rvv or norvv" >&2
    exit 1
    ;;
esac

if [[ -n "$fftw_prefix" ]]; then
  [[ -f "$fftw_prefix/include/fftw3.h" ]] || {
    echo "FFTW header not found: $fftw_prefix/include/fftw3.h" >&2
    exit 1
  }

  fftw_lib_dir=""
  for candidate in "$fftw_prefix/lib" "$fftw_prefix/lib64"; do
    if compgen -G "$candidate/libfftw3.*" >/dev/null &&
       compgen -G "$candidate/libfftw3_threads.*" >/dev/null; then
      fftw_lib_dir="$candidate"
      break
    fi
  done

  [[ -n "$fftw_lib_dir" ]] || {
    echo "libfftw3 and libfftw3_threads not found under $fftw_prefix/lib{,64}" >&2
    exit 1
  }

  compile_flags+=("-I$fftw_prefix/include")
  link_flags+=("-L$fftw_lib_dir" "-Wl,-rpath,$fftw_lib_dir")
fi

"$compiler" \
  "${compile_flags[@]}" \
  "$project_dir/bench-threads.c" \
  -o "$project_dir/bench-threads" \
  "${link_flags[@]}" \
  -lfftw3_threads \
  -lfftw3 \
  -lm \
  -pthread

echo "Built $project_dir/bench-threads ($compiler_family, $vector_mode)"
