#!/usr/bin/env bash
set -e

BRK_NVIM="$PWD"
if [ $# = 0 ]; then
    TESTS=(tests/*_test.lua)
else
    TESTS=$@
fi

if [ "$(basename $BRK_NVIM)" != brk.nvim ]; then
    echo "Run from project root" >&2
    exit 1
fi

rm -rf .testenv
mkdir -p .testenv/{state,run,data,config,cache}/nvim

export XDG_CONFIG_HOME=".testenv/config"
export XDG_DATA_HOME=".testenv/data"
export XDG_STATE_HOME=".testenv/state"
export XDG_RUNTIME_DIR=".testenv/run"
export XDG_CACHE_HOME=".testenv/cache"
export HOME="$XDG_CONFIG_HOME"

if [ -n "$DEBUG" ]; then
    curl -sOL https://raw.githubusercontent.com/kafva/debugger.lua/master/debugger.lua
    nvim --headless --noplugin -u ./tests/init.lua -c "RunTests ${TESTS[*]}"
else
    nvim -es --headless --noplugin -u ./tests/init.lua -c "RunTests ${TESTS[*]}"
fi

