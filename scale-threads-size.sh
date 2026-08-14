#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
script_name="${BENCH_SCRIPT_NAME:-$0}"
scale_mode="${BENCH_SCALE_MODE:-both}"
benchmark="$project_dir/bench-threads"
iterations=100
transforms_value="c2c,r2c,c2r,r2r"
ranks_value="1,2,3"
threads_value=""
sizes_value=""
fixed_size=64
fixed_thread=1
dry_run=false

usage() {
	case "$scale_mode" in
		both)
			cat <<EOF
Usage: $script_name [options]

Scale both thread count and transform size (the Cartesian product).

  --threads LIST       Thread counts (default: powers of two up to all CPUs)
  --sizes LIST         Per-dimension sizes (default: 16,32,64)
  --transforms LIST    Any of c2c,r2c,c2r,r2r (default: all)
  --ranks LIST         Transform ranks from 1,2,3 (default: all)
  --iterations N       Executions averaged per case (default: 100)
  --benchmark PATH     Benchmark executable (default: $benchmark)
  --dry-run            Print commands without running them
  -h, --help           Show this help

LIST values may be comma- or space-separated.

Example:
  $script_name --threads 1,2,4,8 --sizes 32,64,128 --transforms c2c,r2c
EOF
			;;
		threads)
			cat <<EOF
Usage: $script_name [options]

Scale thread count while keeping the transform size fixed.

  --threads LIST       Thread counts (default: powers of two up to all CPUs)
  --size N             Fixed per-dimension size (default: 64)
  --transforms LIST    Any of c2c,r2c,c2r,r2r (default: all)
  --ranks LIST         Transform ranks from 1,2,3 (default: all)
  --iterations N       Executions averaged per case (default: 100)
  --benchmark PATH     Benchmark executable (default: $benchmark)
  --dry-run            Print commands without running them
  -h, --help           Show this help

LIST values may be comma- or space-separated.

Example:
  $script_name --size 128 --threads 1,2,4,8 --transforms c2c,c2r
EOF
			;;
		size)
			cat <<EOF
Usage: $script_name [options]

Scale transform size while keeping the thread count fixed.

  --sizes LIST         Per-dimension sizes (default: 16,32,64)
  --thread N           Fixed thread count (default: 1)
  --transforms LIST    Any of c2c,r2c,c2r,r2r (default: all)
  --ranks LIST         Transform ranks from 1,2,3 (default: all)
  --iterations N       Executions averaged per case (default: 100)
  --benchmark PATH     Benchmark executable (default: $benchmark)
  --dry-run            Print commands without running them
  -h, --help           Show this help

LIST values may be comma- or space-separated.

Example:
  $script_name --thread 4 --sizes 16,32,64,128 --transforms r2c,r2r
EOF
			;;
		*)
			echo "invalid BENCH_SCALE_MODE: $scale_mode" >&2
			exit 1
			;;
	esac
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
		--threads)
			need_value "$@"
			if [[ "$scale_mode" == "size" ]]; then
				echo "use --thread (singular) for the fixed thread count" >&2
				exit 1
			fi
			threads_value="$2"
			shift 2
			;;
		--sizes)
			need_value "$@"
			if [[ "$scale_mode" == "threads" ]]; then
				echo "use --size (singular) for the fixed transform size" >&2
				exit 1
			fi
			sizes_value="$2"
			shift 2
			;;
		--size)
			need_value "$@"
			[[ "$scale_mode" == "threads" ]] || {
				echo "--size is only valid when scaling threads" >&2
				exit 1
			}
			fixed_size="$2"
			shift 2
			;;
		--thread)
			need_value "$@"
			[[ "$scale_mode" == "size" ]] || {
				echo "--thread is only valid when scaling size" >&2
				exit 1
			}
			fixed_thread="$2"
			shift 2
			;;
		--transforms)
			need_value "$@"
			transforms_value="$2"
			shift 2
			;;
		--ranks)
			need_value "$@"
			ranks_value="$2"
			shift 2
			;;
		--iterations)
			need_value "$@"
			iterations="$2"
			shift 2
			;;
		--benchmark)
			need_value "$@"
			benchmark="$2"
			shift 2
			;;
		--dry-run)
			dry_run=true
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

is_positive_integer() {
	[[ "$1" =~ ^[1-9][0-9]*$ ]]
}

split_list() {
	local value="$1"
	local -n destination="$2"
	value="${value//,/ }"
	read -r -a destination <<< "$value"
	((${#destination[@]} > 0)) || {
		echo "lists must not be empty" >&2
		exit 1
	}
}

default_thread_counts() {
	local cpu_count next
	cpu_count="$(getconf _NPROCESSORS_ONLN 2>/dev/null || true)"
	if ! is_positive_integer "$cpu_count"; then
		cpu_count=1
	fi

	threads=(1)
	next=2
	while ((next <= cpu_count)); do
		threads+=("$next")
		next=$((next * 2))
	done
	if ((${threads[${#threads[@]} - 1]} != cpu_count)); then
		threads+=("$cpu_count")
	fi
}

transforms=()
ranks=()
threads=()
sizes=()
split_list "$transforms_value" transforms
split_list "$ranks_value" ranks

case "$scale_mode" in
	both)
		if [[ -n "$threads_value" ]]; then
			split_list "$threads_value" threads
		else
			default_thread_counts
		fi
		split_list "${sizes_value:-16,32,64}" sizes
		;;
	threads)
		if [[ -n "$threads_value" ]]; then
			split_list "$threads_value" threads
		else
			default_thread_counts
		fi
		sizes=("$fixed_size")
		;;
	size)
		threads=("$fixed_thread")
		split_list "${sizes_value:-16,32,64}" sizes
		;;
	*)
		echo "invalid BENCH_SCALE_MODE: $scale_mode" >&2
		exit 1
		;;
esac

for transform in "${transforms[@]}"; do
	case "$transform" in
		c2c|r2c|c2r|r2r) ;;
		*) echo "invalid transform: $transform" >&2; exit 1 ;;
	esac
done

for rank in "${ranks[@]}"; do
	if ! is_positive_integer "$rank" || ((rank > 3)); then
		echo "invalid rank: $rank (expected 1, 2, or 3)" >&2
		exit 1
	fi
done

for thread in "${threads[@]}"; do
	is_positive_integer "$thread" || {
		echo "invalid thread count: $thread" >&2
		exit 1
	}
done

for size in "${sizes[@]}"; do
	is_positive_integer "$size" || {
		echo "invalid size: $size" >&2
		exit 1
	}
done

is_positive_integer "$iterations" || {
	echo "invalid iteration count: $iterations" >&2
	exit 1
}

if [[ "$dry_run" == false && ! -x "$benchmark" ]]; then
	echo "benchmark is not executable: $benchmark" >&2
	echo "build it with $project_dir/compile-bench-threads.sh or use --benchmark PATH" >&2
	exit 1
fi

printf '# benchmark=%s iterations=%s transforms=%s ranks=%s\n' \
	"$benchmark" "$iterations" "${transforms[*]}" "${ranks[*]}"

for transform in "${transforms[@]}"; do
	for rank in "${ranks[@]}"; do
		for size in "${sizes[@]}"; do
			for thread in "${threads[@]}"; do
				command=("$benchmark" "$thread" "$transform" "$rank" "$size" "$iterations")
				if [[ "$dry_run" == true ]]; then
					printf '%q ' "${command[@]}"
					printf '\n'
				else
					"${command[@]}"
				fi
			done
		done
	done
done
