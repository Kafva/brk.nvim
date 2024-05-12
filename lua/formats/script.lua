local config = require 'config'

local M = {}

function M.load_breakpoints()
end

function M.delete_all_breakpoints()
end

---@param filetype string
---@param lnum number
function M.toggle_breakpoint(filetype, lnum)
    local content = vim.api.nvim_buf_get_lines(0, lnum, lnum + 1, false)[1]

    local match, _ = content:find(config.script_cmds[filetype])
    if match then
        -- Remove breakpoint marker
        vim.api.nvim_buf_set_text(0, lnum, 0, lnum + 1, 0, {''})
        return
    end

    -- Add breakpoint marker
    local indent = string.rep(' ', vim.fn.indent(lnum))
    local cmdstr = indent .. config.script_cmds[filetype]
    vim.api.nvim_buf_set_text(0, lnum, 0, lnum + 1, #cmdstr, {cmdstr})

    -- vim.cmd 'normal! k'
end


return M
