#!/usr/bin/env bash
set -e

if [ "$(basename $PWD)" != brk.nvim ]; then
    echo "Run from project root" >&2
    exit 1
fi

# Clone the test runner
if [ ! -e "tests/tsst.nvim" ]; then
    git clone https://github.com/kafva/tsst.nvim.git tests/tsst.nvim
fi

# Run tests
if [ $# = 0 ]; then
    tests/tsst.nvim/tsst tests/*_test.lua || :
    git checkout tests/files 2> /dev/null
else
    tests/tsst.nvim/tsst $@
fi
