local M = {}

---@param group string
---@param lnum number
---@return boolean
function M.sign_exists(group, lnum)
    local buf = vim.api.nvim_get_current_buf()
    local bufsigns =
        vim.fn.sign_getplaced(buf, { group = group, lnum = tostring(lnum) })
    return #bufsigns > 0 and #bufsigns[1].signs > 0
end

function M.before_each()
    -- Close all open files
    repeat
        vim.cmd([[bd!]])
    until vim.fn.expand('%') == ''

    -- Restore files
    vim.system({ 'git', 'checkout', 'tests/files' }):wait()

    vim.o.expandtab = true
    vim.o.tabstop = 4

    -- Setup with trace logging
    require('brk').setup({
        default_bindings = false,
        trace = true,
    })
end

return M
