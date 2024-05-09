local config = require('config')

local M = {}

function M.toggle_breakpoint()
    local buf = vim.api.nvim_get_current_buf()
    local lnum = vim.fn.line('.')

    ---@type table
    local bufsigns = vim.fn.sign_getplaced(buf, {group='brk', lnum = lnum})

    if #bufsigns > 0 and #bufsigns[1].signs > 0 then
        for _, sign in ipairs(bufsigns[1].signs) do
            vim.fn.sign_unplace('brk', {id = sign.id})
        end
    else
        vim.fn.sign_place(0, "brk", "BrkBreakpoint", buf, { lnum = lnum, priority = 90 })
    end

end

function M.delete_all_breakpoints()
    vim.fn.sign_unplace('brk')
end

---@param user_opts BrkOptions?
function M.setup(user_opts)
    config.setup(user_opts)

    -- We want to parse the breakpoints file whenever a new buffer is opened
end

return M
