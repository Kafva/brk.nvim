# brk.nvim
Plugin for managing debugger breakpoints.

* [lldb/gdb](https://lldb.llvm.org/use/map.html)
* [delve](https://github.com/go-delve/delve/blob/master/Documentation/cli/getting_started.md)
* [pdb](https://docs.python.org/3/library/pdb.html)
* [debugger.lua](https://github.com/kafva/debugger.lua)
* [ruby/debug](https://github.com/ruby/debug)


## Tips
```bash
# Delve does not autoload initfiles in the same way as gdb/lldb you need to
# explicitly provide one, brk.nvim uses .dlvinit by default
(cd tests/files/go && 
    echo "break main.main" > .dlvinit &&
    echo "continue" >> .dlvinit &&
    dlv debug --init .dlvinit)
```
