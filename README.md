# brk.nvim
Neovim plugin for basic management of debugger breakpoints. The plugin provides
an easy way to toggle breakpoints inside nvim which automatically updates the
debugger init file (`.lldbinit` etc.) with matching breakpoints.

If you want a fully integrated debugger inside nvim, this plugin is not for you,
consider [nvim-dap](https://github.com/mfussenegger/nvim-dap). The upside of
brk.nvim compared to a full dap setup is that it requires zero configuration
and works as long as you have a way to run your program under one of the
supported debuggers.

* [lldb/gdb](https://lldb.llvm.org/use/map.html) for C, C++, Rust etc.
* [delve](https://github.com/go-delve/delve/blob/master/Documentation/cli/getting_started.md) for Go

Note that delve does not autoload init files in the same way as gdb/lldb, you need to
explicitly provide one, brk.nvim uses .dlvinit by default

```bash
(cd tests/files/go && dlv debug --init .dlvinit)
```

The toggle breakpoint function is also setup to insert inline breakpoints for
debuggers in the following languages:

* [pdb](https://docs.python.org/3/library/pdb.html) for Python
* [kafva/debugger.lua](https://github.com/kafva/debugger.lua) for Lua
* [ruby/debug](https://github.com/ruby/debug) for Ruby

```lua
-- Basic configuration, see lua/config.lua for more options
require 'brk'.setup {
    -- Enable default mappings:
    --  Toggle breakpoint: <F9> or 'db'
    --  Insert/Edit/Delete conditional breakpoint: 'dc'
    --  Insert/Delete symbol breakpoint: 'ds'
    --  Show debugger initfile: 'dl'
    default_bindings = true,
    -- Insert 'run' command at the end of the init file automatically
    auto_start = true,
    breakpoint_sign = '󰝥 ',
    conditional_breakpoint_sign = '󰝥 ',
    breakpoint_color = 'Error',
    conditional_breakpoint_color = 'Comment',

    -- Preferred debugger when no init file exists
    preferred_debugger_format = "lldb",
}
```

Commands:
* `BrkClear`: Clear all breakpoints from current buffer
* `BrkReload`: Reload debugger init file

To run unit tests
```bash
./check.sh
```

## Tips

### delve
```bash
# Debug a go program in the foreground (e.g. lf) and attach to it
dlv debug --continue --headless --accept-multiclient --listen 127.0.0.1:4777
dlv connect 127.0.0.1:4777
```

### lldb
```lldbinit
# Show variables in frame
frame variable
```
