#!/usr/bin/env bash
set -euxo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$ROOT/fftw3-pr408"

if [[ ! -d "$SRC/.git" ]]; then
  git clone --filter=blob:none --no-checkout https://github.com/FFTW/fftw3.git "$SRC"
fi

git -C "$SRC" fetch --depth 1 origin pull/408/head
git -C "$SRC" checkout --detach FETCH_HEAD
