local M = {}

---@enum DebuggerType
DebuggerType = {
    GDB = 'gdb',
    LLDB = 'lldb',
    DELVE = 'delve',
    JDB = 'jdb',
    GHCI = 'ghci',
}

---@type BrkOptions
M.default_opts = {
    default_bindings = true,
    trace = false,
    auto_start = {
        ['c'] = true,
        ['cpp'] = true,
        ['objc'] = true,
        ['rust'] = true,
        ['zig'] = true,
        ['go'] = true,
        ['swift'] = false,
        ['kotlin'] = true,
        ['java'] = true,
        ['haskell'] = false,
    },
    breakpoint_sign_priority = 90,
    breakpoint_sign = '󰝥 ',
    conditional_breakpoint_sign = '󰝥 ',
    breakpoint_color = 'Error',
    conditional_breakpoint_color = 'Comment',

    preferred_debugger_format = DebuggerType.LLDB,
    initfile_paths = {
        [DebuggerType.LLDB] = './.lldbinit',
        [DebuggerType.GDB] = './.gdbinit',
        [DebuggerType.DELVE] = './.dlvinit',
        [DebuggerType.JDB] = './.jdbrc',
        [DebuggerType.GHCI] = './.ghci-init',
    },
    initfile_filetypes = {
        'c',
        'cpp',
        'objc',
        'rust',
        'zig',
        'swift',
        'go',
        'java',
        'kotlin',
        'haskell',
    },
    initfile_supported = {
        ['c'] = { DebuggerType.LLDB, DebuggerType.GDB },
        ['objc'] = { DebuggerType.LLDB, DebuggerType.GDB },
        ['cpp'] = { DebuggerType.LLDB, DebuggerType.GDB },
        ['rust'] = { DebuggerType.LLDB, DebuggerType.GDB },
        ['zig'] = { DebuggerType.LLDB, DebuggerType.GDB },
        ['swift'] = { DebuggerType.LLDB, DebuggerType.GDB },
        ['go'] = { DebuggerType.DELVE },
        ['java'] = { DebuggerType.JDB },
        ['kotlin'] = { DebuggerType.JDB },
        ['haskell'] = { DebuggerType.GHCI },
    },
    inline_filetypes = {
        'python',
        'ruby',
        'lua',
        'javascript',
        'typescript',
        -- 'go'
    },
    inline_cmds = {
        lua = "require'debugger'() -- Set DBG_REMOTEPORT=8777 for remote debugging",
        python = "__import__('pdb').set_trace()",
        ruby = "require 'debug'; debugger",
        javascript = 'debugger',
        typescript = 'debugger',
        -- go = "runtime.Breakpoint()"
    },
    autocmd_pattern = {
        '*.c',
        '*.cpp',
        '*.cc',
        '*.h',
        '*.hh',
        '*.hpp',
        '*.m',
        '*.rs',
        '*.zig',
        '*.swift',
        '*.go',
        '*.java',
        '*.kt',
        '*.hs',
        '*.py',
        '*.rb',
        '*.lua',
    },
}

---@param user_opts BrkOptions?
function M.setup(user_opts)
    local opts = vim.tbl_deep_extend('force', M.default_opts, user_opts or {})

    -- stylua: ignore start
    vim.fn.sign_define('BrkBreakpoint', {text=opts.breakpoint_sign,
                                         numhl='',
                                         linehl='',
                                         texthl=opts.breakpoint_color})
    vim.fn.sign_define('BrkConditionalBreakpoint',
                                        {text=opts.conditional_breakpoint_sign,
                                         numhl='',
                                         linehl='',
                                         texthl=opts.conditional_breakpoint_color})
    if opts and opts.default_bindings then
        vim.keymap.set({'n', 'i'}, '<F9>', require'brk'.toggle_breakpoint, {
            desc = "Toggle breakpoint"
        })
        vim.keymap.set('n', 'db', require'brk'.toggle_breakpoint, {
            desc = "Toggle breakpoint"
        })
        vim.keymap.set('n', 'dc', require'brk'.toggle_conditional_breakpoint, {
            desc = "Toggle conditional breakpoint"
        })
        vim.keymap.set('n', 'ds', require'brk'.toggle_symbol_breakpoint, {
            desc = "Toggle symbol breakpoint"
        })
        vim.keymap.set('n', 'dl', require'brk'.list_breakpoints, {
            desc = "List breakpoints"
        })
        vim.keymap.set('n', 'dC', require'brk'.delete_all_breakpoints, {
            desc = "Delete all breakpoints"
        })
    end
    -- stylua: ignore end

    vim.api.nvim_create_user_command('BrkReload', function()
        require('brk').load_breakpoints(vim.bo.filetype)
    end, {})

    -- Expose configuration variables
    for k, v in pairs(opts) do
        M[k] = v
    end

    M['filetypes'] = vim.iter({
        opts.initfile_filetypes,
        opts.inline_filetypes,
    })
        :flatten()
        :totable()
end

return M
