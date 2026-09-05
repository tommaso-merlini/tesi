#!/usr/bin/env bash
set -euo pipefail

source_dir=""
prefix=""
precision=""
vector_mode=""
openmp=false

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
    --vector)
      need_value "$@"
      vector_mode="$2"
      shift 2
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

if [[ -z "$source_dir" || -z "$prefix" || -z "$precision" || -z "$vector_mode" ]]; then
  echo "--source, --prefix, --precision and --vector are required" >&2
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
)

case "$vector_mode" in
  rvv)
    cflags+=(-march=rv64gcv -mabi=lp64d)
    configure_flags+=(--enable-rvv)
    ;;
  norvv)
    configure_flags+=(--disable-rvv)
    ;;
  *)
    echo "--vector must be rvv or norvv" >&2
    exit 1
    ;;
esac

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
