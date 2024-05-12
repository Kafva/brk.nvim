#!/usr/bin/env bash
set -e

BRK_NVIM="$PWD"
TESTS="$(realpath ${1:-"$BRK_NVIM/tests/spec"})"

if [ "$(basename $BRK_NVIM)" != brk.nvim ]; then
    echo "Run from project root" >&2
    exit 1
fi

mkdir -p tests/.env
cd tests/.env
rm -f .{lldb,gdb}init*

PLUGINS="data/nvim/site/pack/plugins/start"

mkdir -p "$PLUGINS"
mkdir -p "state/nvim"
mkdir -p "run/nvim"
mkdir -p "cache/nvim"
mkdir -p "config/nvim"

if [ ! -e "$PLUGINS/plenary.nvim" ]; then
    git clone --depth=1 https://github.com/nvim-lua/plenary.nvim.git "$PLUGINS/plenary.nvim"
fi

if [ ! -e "$PLUGINS/brk.nvim" ]; then
    ln -s "$BRK_NVIM" "$PLUGINS/brk.nvim"
fi

export XDG_CONFIG_HOME="./config"
export XDG_DATA_HOME="./data"
export XDG_STATE_HOME="./state"
export XDG_RUNTIME_DIR="./run"
export XDG_CACHE_HOME="./cache"

nvim --headless -u $BRK_NVIM/tests/minimal_init.lua -c "RunTests $TESTS"
