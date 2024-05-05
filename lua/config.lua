local M = {}

---@type BrkOptions
M.default_opts = {
    enabled = true,
    default_bindings = true,
    breakpoint_sign = '󰝥 ',
    breakpoint_color = 'Red',
    lldb_file = "./.lldbinit",
    gdb_file = "./.gdbinit",
}

---@param opts BrkOptions?
function M.setup(user_opts)
    local opts = vim.tbl_deep_extend("force", M.default_opts, user_opts or {})

    if not opts.enabled then
        return
    end

    vim.fn.sign_define('BrkBreakpoint', {text=opts.breakpoint_sign,
                                         numhl='',
                                         linehl='',
                                         texthl=opts.breakpoint_color})
    if opts and opts.default_mappings then
        vim.keymap.set('n', '<F9>', function() require('brk').toggle_breakpoint() end)
    end

    -- Expose configuration variables
    for k,v in pairs(opts) do
        M[k] = v
    end
end

return M
