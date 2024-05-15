---@type uv
local uv = vim.uv

local M = {}


---@class BrkOptions
---@field default_bindings? boolean
---@field auto_start? boolean Create a debugger init file that automatically
---starts a process on entry.
---@field cdb_file_format? string
---@field cdb_file? string
---@field breakpoint_sign? string
---@field breakpoint_color? string
---@field cdb_filetypes? string[]
---@field delve_filetypes? string[]
---@field inline_filetypes? string[]
---@field inline_cmds? table<string, string>

---@type BrkOptions
M.default_opts = {
    default_bindings = true,
    auto_start = true,
    breakpoint_sign = '󰝥 ',
    breakpoint_sign_priority = 90,
    breakpoint_color = 'Error',

    cdb_file_format = "lldb",
    cdb_file = "./.lldbinit",
    cdb_filetypes = {
        'c',
        'cpp',
        'objc',
        'rust',
    },
    inline_filetypes = {
        'python',
        'ruby',
        'lua',
        'go'
    },
    inline_cmds = {
        lua = "require'debugger'() -- Set DBG_REMOTEPORT=8777 for remote debugging",
        python = "__import__('pdb').set_trace()",
        ruby = "require 'debug'; debugger",
        go = "runtime.Breakpoint()"
    }
}

---@param user_opts BrkOptions?
function M.setup(user_opts)
    local opts = vim.tbl_deep_extend("force", M.default_opts, user_opts or {})

    -- Use gdb if explicitly configured or if .gdbinit exists
    local ok, _ = uv.fs_access("./.gdbinit", 'r')
    if ok or opts.cdb_file_format == "gdb" then
        opts.cdb_file_format = "gdb"
        if opts.cdb_file == "./.lldbinit" then
            opts.cdb_file = "./.gdbinit"
        end
    end

    vim.fn.sign_define('BrkBreakpoint', {text=opts.breakpoint_sign,
                                         numhl='',
                                         linehl='',
                                         texthl=opts.breakpoint_color})
    if opts and opts.default_bindings then
        vim.keymap.set({"n", "i"}, "<F9>", require'brk'.toggle_breakpoint, {})
    end

    vim.api.nvim_create_user_command("BrkClear", require'brk'.delete_all_breakpoints, {})
    vim.api.nvim_create_user_command("BrkReload", function()
       require'brk'.load_breakpoints(vim.bo.filetype)
    end, {})

    -- Expose configuration variables
    for k,v in pairs(opts) do
        M[k] = v
    end
end

return M
