#!/usr/bin/env bash
set -euxo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$ROOT/fftw3-pr408"
PREFIX="${2:-$ROOT/fftw3-rvv}"

install() {
  if [[ ! -d "$SRC/.git" ]]; then
    git clone --filter=blob:none --no-checkout https://github.com/FFTW/fftw3.git "$SRC"
  fi

  git -C "$SRC" fetch --depth 1 origin pull/408/head
  git -C "$SRC" checkout --detach FETCH_HEAD
}

compile() {
  mkdir -p "$PREFIX"
  PREFIX="$(cd "$PREFIX" && pwd)"

  cd "$SRC"
  CFLAGS="-O3 -march=rv64gcv -mabi=lp64d" ./bootstrap.sh \
    --prefix="$PREFIX" \
    --enable-single \
    --enable-rvv \
    --disable-fortran \
    --disable-doc
  make -j"$(nproc)"
  make install
}

case "${1:-all}" in
  install) install ;;
  compile) compile ;;
  all) install; compile ;;
  *) echo "usage: $0 {install|compile|all} [prefix]" >&2; exit 1 ;;
esac
