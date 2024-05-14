#!/usr/bin/env bash
set -e

BRK_NVIM="$PWD"
TESTS="$(realpath ${1:-"$BRK_NVIM/tests/spec"})"

if [ "$(basename $BRK_NVIM)" != brk.nvim ]; then
    echo "Run from project root" >&2
    exit 1
fi

mkdir -p .testenv

PLUGINS=".testenv/data/nvim/site/pack/plugins/start"

mkdir -p "$PLUGINS"
mkdir -p ".testenv/state/nvim"
mkdir -p ".testenv/run/nvim"
mkdir -p ".testenv/cache/nvim"
mkdir -p ".testenv/config/nvim"

if [ ! -e "$PLUGINS/plenary.nvim" ]; then
    git clone --depth=1 https://github.com/nvim-lua/plenary.nvim.git "$PLUGINS/plenary.nvim"
fi

export XDG_CONFIG_HOME=".testenv/config"
export XDG_DATA_HOME=".testenv/data"
export XDG_STATE_HOME=".testenv/state"
export XDG_RUNTIME_DIR=".testenv/run"
export XDG_CACHE_HOME=".testenv/cache"

nvim --headless -u ./tests/minimal_init.lua -c "RunTests $TESTS"
