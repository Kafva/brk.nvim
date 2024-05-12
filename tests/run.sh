#!/usr/bin/env bash
set -e

if [ "$(basename $PWD)" != brk.nvim ]; then
    echo "Run from project root" >&2
    exit 1
fi

mkdir -p ".testenv/config/nvim"
mkdir -p ".testenv/data/nvim"
mkdir -p ".testenv/state/nvim"
mkdir -p ".testenv/run/nvim"
mkdir -p ".testenv/cache/nvim"
PLUGINS=".testenv/data/nvim/site/pack/plugins/start"

if [ ! -e "$PLUGINS/plenary.nvim" ]; then
    git clone --depth=1 https://github.com/nvim-lua/plenary.nvim.git "$PLUGINS/plenary.nvim"
fi

(cd "$PLUGINS/plenary.nvim" && git pull --quiet)

export XDG_CONFIG_HOME=".testenv/config"
export XDG_DATA_HOME=".testenv/data"
export XDG_STATE_HOME=".testenv/state"
export XDG_RUNTIME_DIR=".testenv/run"
export XDG_CACHE_HOME=".testenv/cache"

nvim --headless -u ./tests/minimal_init.lua \
  -c "RunTests ${1-tests}"
