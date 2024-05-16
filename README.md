# brk.nvim
Plugin for basic management of debugger breakpoints in Neovim. The plugin
defines a breakpoint mapping (`<F9>` by default) and automatically updates
`.lldbinit` / `.gdbinit` with matching breakpoints.

* [lldb/gdb](https://lldb.llvm.org/use/map.html) for C, C++, Rust etc.

The `<F9>` mapping is also setup to insert inline breakpoints for debuggers in the following languages:

* [delve](https://github.com/go-delve/delve/blob/master/Documentation/cli/getting_started.md) for Go
* [pdb](https://docs.python.org/3/library/pdb.html) for Python
* [debugger.lua](https://github.com/kafva/debugger.lua) for Lua
* [ruby/debug](https://github.com/ruby/debug) for Ruby

```lua
-- Basic configuration, see lua/config.lua for more options
require 'brk'.setup {
    default_bindings = true,
    auto_start = true, -- Insert 'run' command at the end of .lldb/gdbinit automatically
    breakpoint_sign = '󰝥 ',
    breakpoint_color = 'Error',

    preferred_initfile_format = "lldb", -- Preferred format when inserting breakpoints,
                              -- automatically overriden if .gdbinit exists in the current directory
    initfile_path = "./.lldbinit",
}
```

For more advanced debugger integrations, consider [nvim-dap](https://github.com/mfussenegger/nvim-dap).
