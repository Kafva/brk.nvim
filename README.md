# brk.nvim
Plugin for managing debugger breakpoints.

## Supported debuggers

* [lldb/gdb](https://lldb.llvm.org/use/map.html) for C, C++, Rust etc.
* [delve](https://github.com/go-delve/delve/blob/master/Documentation/cli/getting_started.md) for Go
* [pdb](https://docs.python.org/3/library/pdb.html) for Python
* [debugger.lua](https://github.com/kafva/debugger.lua) for Lua
* [ruby/debug](https://github.com/ruby/debug) for Ruby


## Tips
```bash
# Delve does not autoload initfiles in the same way as gdb/lldb you need to
# explicitly provide one, brk.nvim uses .dlvinit by default
(cd tests/files/go &&
    echo "break main.main" > .dlvinit &&
    echo "continue" >> .dlvinit &&
    dlv debug --init .dlvinit)

# There is also an inline alternative for Go:
#   runtime.Breakpoint()
```
