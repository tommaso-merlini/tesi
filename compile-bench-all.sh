#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fftw_builds=""
source_file="$project_dir/bench-threads.c"
output="$project_dir/benchmark-builds"
family=gcc
dry_run=false

usage() {
  cat <<HELP
Usage: $0 --fftw-builds DIR [options]
  --fftw-builds DIR Folder containing ARCH-single|double-vector|novector installations
  --source FILE     Benchmark source (default: bench-threads.c)
  --output DIR      Executable directory (default: benchmark-builds beside script)
  --compiler gcc|llvm (default: gcc)
  --dry-run         Print commands without writing files
  -h, --help        Show help
Uses GCC_RISCV/GCC_ARM/GCC_X86 or CLANG_RISCV/CLANG_ARM/CLANG_X86,
falling back to GCC/CLANG and then gcc/clang. Requires matching compilers.
Custom sources must support BENCH_SINGLE for single-precision builds.
HELP
}

while (($#)); do
  case "$1" in
    --fftw-builds|--source|--output|--compiler)
      (($# >= 2)) && [[ -n "$2" && "$2" != --* ]] || { echo "Missing value for $1" >&2; exit 1; }
      case "$1" in
        --fftw-builds) fftw_builds="$2" ;;
        --source) source_file="$2" ;;
        --output) output="$2" ;;
        --compiler) family="$2" ;;
      esac
      shift 2 ;;
    --dry-run) dry_run=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

[[ -n "$fftw_builds" && -d "$fftw_builds" ]] || { echo "Provide an existing --fftw-builds directory" >&2; exit 1; }
[[ -f "$source_file" ]] || { echo "Source not found: $source_file" >&2; exit 1; }

case "$family" in
  gcc) compiler_env=GCC; default_compiler=gcc ;;
  llvm) compiler_env=CLANG; default_compiler=clang ;;
  *) echo "--compiler must be gcc or llvm" >&2; exit 1 ;;
esac

fftw_builds="$(cd "$fftw_builds" && pwd)"
source_file="$(realpath -- "$source_file")"
output="$(realpath -m -- "$output")"
source_name="$(basename -- "${source_file%.*}")"
builds=()
compilers=()

for build in "$fftw_builds"/*; do
  [[ -d "$build" ]] || continue
  name="${build##*/}"
  [[ "$name" =~ ^(riscv|arm|x86)-(single|double)-(vector|novector)$ ]] || continue
  arch="${BASH_REMATCH[1]}"
  precision="${BASH_REMATCH[2]}"
  [[ -f "$build/include/fftw3.h" ]] || { echo "Missing header in $build" >&2; exit 1; }
  lib=fftw3
  [[ "$precision" != single ]] || lib=fftw3f
  found=false
  for libdir in "$build/lib" "$build/lib64"; do
    if compgen -G "$libdir/lib$lib.*" >/dev/null && {
      compgen -G "$libdir/lib${lib}_threads.*" >/dev/null || compgen -G "$libdir/lib${lib}_omp.*" >/dev/null;
    }; then found=true; break; fi
  done
  [[ "$found" == true ]] || { echo "Missing $lib and threads/omp libraries in $build; rebuild FFTW with thread support" >&2; exit 1; }
  destination="$output/$source_name-$name"
  [[ ! -e "$destination" && ! -L "$destination" ]] || { echo "Output already exists: $destination" >&2; exit 1; }
  override="${compiler_env}_${arch^^}"
  compiler="${!override:-${!compiler_env:-$default_compiler}}"
  if [[ "$dry_run" == false ]]; then
    target="$("$compiler" -dumpmachine)"
    case "$arch:$target" in
      riscv:riscv64*|arm:aarch64*|arm:arm64*|x86:x86_64*) ;;
      *) echo "Compiler $compiler targets $target, not $arch; set $override" >&2; exit 1 ;;
    esac
  fi
  builds+=("$build")
  compilers+=("$compiler")
done

((${#builds[@]})) || { echo "No ARCH-PRECISION-MODE installations found in $fftw_builds" >&2; exit 1; }
[[ "$dry_run" == true ]] || mkdir -p -- "$output/logs"

for i in "${!builds[@]}"; do
  build="${builds[$i]}"
  name="${build##*/}"
  IFS=- read -r arch precision mode <<< "$name"
  command=(bash "$project_dir/compile-bench-threads.sh" --source "$source_file"
    --output "$output/$source_name-$name" --fftw-prefix "$build"
    --compiler "$family" --arch "$arch" --precision "$precision")
  [[ "$mode" != vector ]] || command+=(--vector)
  if [[ "$dry_run" == true ]]; then
    printf '%s=%q ' "$compiler_env" "${compilers[$i]}"
    printf '%q ' "${command[@]}"
    printf '\n'
  else
    log="$output/logs/$source_name-$name.log"
    echo "Building $source_name-$name"
    if ! env "$compiler_env=${compilers[$i]}" "${command[@]}" > "$log" 2>&1; then
      echo "Build failed: $name. See $log" >&2; exit 1
    fi
  fi
done
