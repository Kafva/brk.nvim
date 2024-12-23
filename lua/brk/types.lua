---@class Breakpoint
---@field file string
---@field lnum number
---@field name string?
---@field symbol string?
---@field condition string?

---@class BrkOptions
---@field default_bindings? boolean Enable default bindings
---@field auto_start? table<string, boolean> Determine if the initfile should append an autorun command for each filetype
---@field preferred_debugger_format? DebuggerType
---@field breakpoint_sign? string
---@field conditional_breakpoint_sign? string
---@field breakpoint_color? string
---@field conditional_breakpoint_color? string
---@field initfile_paths? table<DebuggerType, string>
---@field initfile_supported? table<string, DebuggerType[]>
---@field initfile_filetypes? string[]
---@field inline_cmds? table<string, string>
---@field inline_filetypes? string[]
---@field autocmd_pattern? string[]