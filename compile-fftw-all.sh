#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
output="$project_dir/fftw-builds"
openmp=false
dry_run=false
declare -A sources=()

usage() {
  cat <<HELP
Usage: $0 [--riscv DIR] [--arm DIR] [--x86 DIR] [options]
  --riscv DIR   RISC-V FFTW source tree containing bootstrap.sh
  --arm DIR     ARM FFTW source tree containing bootstrap.sh
  --x86 DIR     x86 FFTW source tree containing bootstrap.sh
  --output DIR  Installation root (default: $project_dir/fftw-builds)
  --openmp      Enable OpenMP for every build (default: off)
  --dry-run     Print the build commands without creating files
  -h, --help    Show this help

Provide at least one architecture. Each produces single/double x vector/novector.
Installations: OUTPUT/ARCH-PRECISION-MODE; logs: OUTPUT/logs/NAME.log.
Existing installation directories are rejected. Sources are copied for isolation.
Uses compile-fftw.sh unchanged, including its compiler and vector settings.
GCC_RISCV, GCC_ARM and GCC_X86 override GCC for individual architectures.
These overrides do not configure cross-compilation: use a suitable build environment.
HELP
}

while (($#)); do
  case "$1" in
    --riscv|--arm|--x86|--output)
      (($# >= 2)) && [[ -n "$2" && "$2" != --* ]] || {
        echo "Missing value for $1" >&2; exit 1;
      }
      if [[ "$1" == --output ]]; then output="$2"; else sources["${1#--}"]="$2"; fi
      shift 2
      ;;
    --openmp) openmp=true; shift ;;
    --dry-run) dry_run=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
done

((${#sources[@]})) || { echo "Provide --riscv, --arm or --x86" >&2; exit 1; }
output="$(realpath -m -- "$output")"
for arch in riscv arm x86; do
  [[ -v sources[$arch] ]] || continue
  source_dir="$(cd "${sources[$arch]}" && pwd)"
  [[ -f "$source_dir/bootstrap.sh" ]] || { echo "Missing bootstrap.sh: $source_dir" >&2; exit 1; }
  sources[$arch]="$source_dir"
  if [[ "$dry_run" == false ]]; then
    compiler_var="GCC_${arch^^}"
    compiler="${!compiler_var:-${GCC:-gcc}}"
    target="$("$compiler" -dumpmachine)"
    case "$arch:$target" in
      riscv:riscv64*|arm:aarch64*|arm:arm64*|x86:x86_64*) ;;
      *) echo "Compiler $compiler targets $target, not $arch; set $compiler_var" >&2; exit 1 ;;
    esac
  fi
  # Avoid recursively copying generated installations into later builds.
  [[ "$output/" != "$source_dir/"* ]] || { echo "Output must be outside source tree: $source_dir" >&2; exit 1; }
  for precision in single double; do
    for mode in vector novector; do
      destination="$output/$arch-$precision-$mode"
      [[ ! -e "$destination" && ! -L "$destination" ]] || { echo "Output already exists: $destination" >&2; exit 1; }
    done
  done
done

work_dir=""
cleanup() { if [[ -n "$work_dir" ]]; then rm -rf -- "$work_dir"; fi; }
trap cleanup EXIT
if [[ "$dry_run" == false ]]; then
  mkdir -p -- "$output/logs"
  work_dir="$(mktemp -d)"
fi

for arch in riscv arm x86; do
  [[ -v sources[$arch] ]] || continue
  compiler_var="GCC_${arch^^}"
  compiler="${!compiler_var:-${GCC:-gcc}}"
  for precision in single double; do
    for mode in vector novector; do
      name="$arch-$precision-$mode"
      build_source="${sources[$arch]}"
      if [[ "$dry_run" == false ]]; then
        build_source="$work_dir/$name"
        mkdir -p -- "$build_source"
        cp -a -- "${sources[$arch]}/." "$build_source/"
      fi
      command=(bash "$project_dir/compile-fftw.sh" --source "$build_source"
        --prefix "$output/$name" --arch "$arch" --precision "$precision")
      [[ "$mode" != vector ]] || command+=(--vector)
      [[ "$openmp" == false ]] || command+=(--openmp)
      if [[ "$dry_run" == true ]]; then
        printf 'GCC=%q ' "$compiler"
        printf '%q ' "${command[@]}"
        printf '\n'
        continue
      fi
      echo "Building $name (log: $output/logs/$name.log)"
      # Clean inherited objects only in the private copy.
      if ! (
        if [[ -f "$build_source/Makefile" ]]; then make -C "$build_source" distclean; fi
        GCC="$compiler" "${command[@]}"
      ) > "$output/logs/$name.log" 2>&1; then
        echo "Build failed: $name. See $output/logs/$name.log" >&2
        exit 1
      fi
      echo "Installed $output/$name"
    done
  done
done
