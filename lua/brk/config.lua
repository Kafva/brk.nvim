local M = {}

---@enum DebuggerType
DebuggerType = {
    GDB = "gdb",
    LLDB = "lldb",
    DELVE = "delve"
}


---@class BrkOptions
---@field default_bindings? boolean Enable default bindings
---@field auto_start? boolean Write an init file that automatically starts the debugger
---@field preferred_debugger_format? DebuggerType
---@field breakpoint_sign? string
---@field breakpoint_color? string
---@field initfile_paths? table<DebuggerType, string>
---@field initfile_filetypes? string[]
---@field inline_cmds? table<string, string>
---@field inline_filetypes? string[]

---@type BrkOptions
M.default_opts = {
    default_bindings = true,
    auto_start = true,
    breakpoint_sign = '󰝥 ',
    breakpoint_sign_priority = 90,
    breakpoint_color = 'Error',

    preferred_debugger_format = DebuggerType.LLDB,
    initfile_paths = {
        [DebuggerType.LLDB] = "./.lldbinit",
        [DebuggerType.GDB] = "./.gdbinit",
        [DebuggerType.DELVE] = "./.dlvinit",
    },
    initfile_filetypes = {
        'c',
        'cpp',
        'objc',
        'rust',
        'go'
    },
    inline_filetypes = {
        'python',
        'ruby',
        'lua',
        -- 'go'
    },
    inline_cmds = {
        lua = "require'debugger'() -- Set DBG_REMOTEPORT=8777 for remote debugging",
        python = "__import__('pdb').set_trace()",
        ruby = "require 'debug'; debugger",
        -- go = "runtime.Breakpoint()"
    }
}

---@param user_opts BrkOptions?
function M.setup(user_opts)
    local opts = vim.tbl_deep_extend("force", M.default_opts, user_opts or {})

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

    M['filetypes'] = vim.tbl_flatten{opts.initfile_filetypes,
                                     opts.inline_filetypes}
end

return M
