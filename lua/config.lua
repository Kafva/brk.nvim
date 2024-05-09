local M = {}

---@class BrkOptions
---@field default_bindings boolean
---@field breakpoint_sign string
---@field breakpoint_color string
---@field lldb_file string
---@field gdb_file string
---@field enabled? boolean

---@type BrkOptions
M.default_opts = {
    enabled = true,
    default_bindings = true,
    breakpoint_sign = '󰝥 ',
    breakpoint_sign_priority = 90,
    breakpoint_color = 'Error',
    filetypes = {
        'c',
        'cpp',
        'rust',
        'objc'
    },
    lldb_file = "./.lldbinit",
    gdb_file = "./.gdbinit",
}

---@param user_opts BrkOptions?
function M.setup(user_opts)
    local opts = vim.tbl_deep_extend("force", M.default_opts, user_opts or {})

    if not opts.enabled then
        return
    end

    vim.fn.sign_define('BrkBreakpoint', {text=opts.breakpoint_sign,
                                         numhl='',
                                         linehl='',
                                         texthl=opts.breakpoint_color})
    if opts and opts.default_bindings then
        vim.keymap.set({"n", "i"}, "<F9>", require'brk'.toggle_breakpoint, {})
    end

    vim.api.nvim_create_user_command("BrkClear", require'brk'.delete_all_breakpoints, {})

    -- Expose configuration variables
    for k,v in pairs(opts) do
        M[k] = v
    end
end

return M
