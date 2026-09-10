#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
compiler_family="gcc"
precision="double"
vector_enabled=false
arch="riscv"
fftw_prefix=""
benchmark_source="$project_dir/bench-threads.c"
output="$project_dir/bench-threads"

usage() {
  cat <<EOF
Usage: $0 [options]
  --source FILE       Benchmark source file (default: $project_dir/bench-threads.c)
  --output FILE       Output executable name or path (default: $project_dir/bench-threads)
  --fftw-prefix DIR   FFTW installation directory
  --compiler gcc|llvm Compiler family (default: gcc)
  --precision single|double Precision of source and libraries (default: double)
  --arch riscv|arm|x86 Target architecture (default: riscv)
  --vector           Enable architecture-specific vector flags (default: off)
  -h, --help          Show this help

Relative source and output paths are resolved from the current directory.
Vector flags: riscv: -march=rv64gcv -mabi=lp64d; arm: -march=armv8-a+sve;
x86: -march=x86-64-v4. Without --vector, no architecture flags are added.
Select a matching compiler via GCC or CLANG when cross-compiling.
With --arch riscv --vector, the default FFTW prefix is $project_dir/fftw3-rvv.
Other configurations use system FFTW unless --fftw-prefix is provided.
EOF
}

while (($# > 0)); do
  case "$1" in
    --precision)
      (($# >= 2)) || { echo "missing value for --precision" >&2; exit 1; }
      precision="$2"
      shift 2
      ;;
    --source)
      (($# >= 2)) || { echo "missing value for --source" >&2; usage >&2; exit 1; }
      benchmark_source="$2"
      shift 2
      ;;
    --output)
      (($# >= 2)) || { echo "missing value for --output" >&2; usage >&2; exit 1; }
      output="$2"
      shift 2
      ;;
    --compiler)
      (($# >= 2)) || { echo "missing value for --compiler" >&2; usage >&2; exit 1; }
      compiler_family="$2"
      shift 2
      ;;
    --arch)
      (($# >= 2)) || { echo "missing value for --arch" >&2; usage >&2; exit 1; }
      arch="$2"
      shift 2
      ;;
    --vector)
      vector_enabled=true
      shift
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

[[ -f "$benchmark_source" ]] || {
  echo "Benchmark source not found: $benchmark_source" >&2
  exit 1
}
[[ -n "$output" ]] || {
  echo "--output must not be empty" >&2
  exit 1
}

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
case "$precision" in
  single) fftw_library="fftw3f"; compile_flags+=(-DBENCH_SINGLE) ;;
  double) fftw_library="fftw3" ;;
  *) echo "--precision must be single or double" >&2; exit 1 ;;
esac
thread_library="${fftw_library}_threads"
compile_flags+=("-I$project_dir")

case "$arch" in
  riscv|riscv64) arch="riscv" ;;
  arm|aarch64|arm64) arch="arm" ;;
  x86|x86_64|amd64) arch="x86" ;;
  *)
    echo "--arch must be riscv, arm, or x86 (64-bit targets)" >&2
    exit 1
    ;;
esac

if [[ "$vector_enabled" == true ]]; then
  case "$arch" in
    riscv)
      compile_flags+=(-march=rv64gcv -mabi=lp64d)
      if [[ -z "$fftw_prefix" ]]; then
        fftw_prefix="$project_dir/fftw3-rvv"
      fi
      ;;
    arm) compile_flags+=(-march=armv8-a+sve) ;;
    x86) compile_flags+=(-march=x86-64-v4) ;;
  esac
fi

if [[ -n "$fftw_prefix" ]]; then
  fftw_prefix="$(cd "$fftw_prefix" && pwd)"
  [[ -f "$fftw_prefix/include/fftw3.h" ]] || {
    echo "FFTW header not found: $fftw_prefix/include/fftw3.h" >&2
    exit 1
  }

  fftw_lib_dir=""
  for candidate in "$fftw_prefix/lib" "$fftw_prefix/lib64"; do
    if compgen -G "$candidate/lib${fftw_library}.*" >/dev/null; then
      for backend in threads omp; do
        if compgen -G "$candidate/lib${fftw_library}_${backend}.*" >/dev/null; then
          fftw_lib_dir="$candidate"
          thread_library="${fftw_library}_${backend}"
          [[ "$backend" != omp ]] || link_flags+=(-fopenmp)
          break 2
        fi
      done
    fi
  done

  [[ -n "$fftw_lib_dir" ]] || {
    echo "lib${fftw_library} and its threads/omp library not found under $fftw_prefix/lib{,64}" >&2
    exit 1
  }

  compile_flags+=("-I$fftw_prefix/include")
  link_flags+=("-L$fftw_lib_dir" "-Wl,-rpath,$fftw_lib_dir")
fi

"$compiler" \
  "${compile_flags[@]}" \
  "$benchmark_source" \
  -o "$output" \
  "${link_flags[@]}" \
  "-l$thread_library" \
  "-l$fftw_library" \
  -lm \
  -pthread

echo "Built $output ($compiler_family, arch=$arch, vector=$vector_enabled)"
