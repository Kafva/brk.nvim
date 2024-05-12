---@type uv
local uv = vim.uv

local M = {}

---@type BrkOptions
M.default_opts = {
    enabled = true,
    default_bindings = true,
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
    delve_filetypes = {
        'go',
    },
    script_filetypes = {
        'python',
        'ruby',
        'lua'
    },
    script_cmds = {
        lua = "require'debugger'() -- Set DBG_REMOTEPORT=8777 for remote debugging",
        python = "__import__('pdb').set_trace()",
        ruby = "require 'debug'; debugger",
    }
}

---@param user_opts BrkOptions?
function M.setup(user_opts)
    local opts = vim.tbl_deep_extend("force", M.default_opts, user_opts or {})

    if not opts.enabled then
        return
    end

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
