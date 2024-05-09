local config = require('config')

local M = {}

function M.toggle_breakpoint()
    local buf = vim.api.nvim_get_current_buf()
    local lnum = vim.fn.line('.')
    vim.fn.sign_place(0, "", "BrkBreakpoint", buf, { lnum = lnum, priority = 90 })
end

---@param user_opts BrkOptions?
function M.setup(user_opts)
    config.setup(user_opts)

end




return M
