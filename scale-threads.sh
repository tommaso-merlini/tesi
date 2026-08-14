#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BENCH_SCRIPT_NAME="$0" BENCH_SCALE_MODE=threads \
	exec "$project_dir/scale-threads-size.sh" "$@"
