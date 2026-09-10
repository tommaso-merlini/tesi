#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Experiment settings: shared by every executable. Edit these arrays together
# when defining a new experiment; each run records the exact commands used.
common_flags=(--transforms c2c,r2c,c2r,r2r --ranks 1,2,3 --iterations 100)
threads_flags=(--threads 1,2,4,8 --size 64)
size_flags=(--thread 4 --sizes 16,32,64)
threads_size_flags=(--threads 1,2,4,8 --sizes 16,32,64)

benchmarks_dir=""
output="$project_dir/benchmark-results/$(date +%Y%m%d-%H%M%S)"
dry_run=false
usage() {
  cat <<HELP
Usage: $0 --benchmarks DIR [--output DIR] [--dry-run]
  --benchmarks DIR Directory of benchmark executables (non-recursive)
  --output DIR     New results directory (default: benchmark-results/TIMESTAMP)
  --dry-run        Print the three suite commands per executable; run nothing
  -h, --help       Show help
Edit common_flags, threads_flags, size_flags and threads_size_flags at the top
of this script to change the experiment. All executables use the same settings.
Each executable gets threads/size/threads-size .txt, .err and .command files.
summary.tsv records success/failure and exit codes. Suites run sequentially;
failures are recorded and remaining suites continue. Exit status is nonzero
if any suite failed. Existing output directories are rejected.
Use a directory of binaries runnable on this machine, with their FFTW libraries.
HELP
}
while (($#)); do
  case "$1" in
    --benchmarks|--output)
      (($# >= 2)) && [[ -n "$2" && "$2" != --* ]] || { echo "Missing value for $1" >&2; exit 1; }
      if [[ "$1" == --benchmarks ]]; then benchmarks_dir="$2"; else output="$2"; fi
      shift 2 ;;
    --dry-run) dry_run=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done
[[ -n "$benchmarks_dir" && -d "$benchmarks_dir" ]] || { echo "Provide an existing --benchmarks directory" >&2; exit 1; }
benchmarks_dir="$(cd "$benchmarks_dir" && pwd)"
output="$(realpath -m -- "$output")"
[[ ! -e "$output" && ! -L "$output" ]] || { echo "Output already exists: $output" >&2; exit 1; }
benchmarks=()
for candidate in "$benchmarks_dir"/*; do
  [[ -f "$candidate" && -x "$candidate" ]] || continue
  benchmarks+=("$candidate")
done
((${#benchmarks[@]})) || { echo "No executables found in $benchmarks_dir" >&2; exit 1; }
for script in scale-threads.sh scale-size.sh scale-threads-size.sh; do
  [[ -x "$project_dir/$script" ]] || { echo "Missing executable script: $script" >&2; exit 1; }
done
# Validate experiment parameters before executing any benchmark.
for suite in threads size threads-size; do
  case "$suite" in
    threads) flags=("${threads_flags[@]}") ;;
    size) flags=("${size_flags[@]}") ;;
    threads-size) flags=("${threads_size_flags[@]}") ;;
  esac
  env -u BENCH_SCALE_MODE -u BENCH_SCRIPT_NAME bash "$project_dir/scale-$suite.sh" \
    --benchmark "${benchmarks[0]}" "${common_flags[@]}" "${flags[@]}" --dry-run > /dev/null
done
if [[ "$dry_run" == false ]]; then
  mkdir -p -- "$(dirname -- "$output")"
  mkdir -- "$output"
  printf 'executable\tsuite\tstatus\texit_code\n' > "$output/summary.tsv"
fi
failed=0
for benchmark in "${benchmarks[@]}"; do
  name="${benchmark##*/}"
  [[ "$dry_run" == true ]] || mkdir -- "$output/$name"
  for suite in threads size threads-size; do
    case "$suite" in
      threads) flags=("${threads_flags[@]}") ;;
      size) flags=("${size_flags[@]}") ;;
      threads-size) flags=("${threads_size_flags[@]}") ;;
    esac
    command=(env -u BENCH_SCALE_MODE -u BENCH_SCRIPT_NAME bash "$project_dir/scale-$suite.sh"
      --benchmark "$benchmark" "${common_flags[@]}" "${flags[@]}")
    if [[ "$dry_run" == true ]]; then
      printf '%q ' "${command[@]}"; printf '\n'
      continue
    fi
    base="$output/$name/$suite"
    { printf '%q ' "${command[@]}"; printf '\n'; } > "$base.command"
    echo "Running $name: $suite"
    code=0
    "${command[@]}" > "$base.txt" 2> "$base.err" || code=$?
    status=ok
    if ((code != 0)); then
      status=failed
      failed=$((failed + 1))
      echo "Failed: $name / $suite (exit $code); see $base.err" >&2
    fi
    printf '%s\t%s\t%s\t%d\n' "$name" "$suite" "$status" "$code" >> "$output/summary.tsv"
  done
done
if [[ "$dry_run" == false ]]; then
  echo "Results: $output; failed suites: $failed"
fi
((failed == 0))
