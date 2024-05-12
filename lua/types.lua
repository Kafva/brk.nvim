---@class BrkOptions
---@field default_bindings? boolean
---@field cdb_file_format? string
---@field cdb_file? string
---@field breakpoint_sign? string
---@field breakpoint_color? string
---@field enabled? boolean
---@field cdb_filetypes? string[]
---@field delve_filetypes? string[]
---@field script_filetypes? string[]
---@field script_cmds? table<string, string>

---@class Breakpoint
---@field file string
---@field lnum number

