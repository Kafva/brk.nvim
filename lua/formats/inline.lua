local config = require 'config'

local M = {}

function M.load_breakpoints()
    -- No config file to load
end

function M.update_breakpoints()
    -- No config file to update
end

function M.delete_all_breakpoints()
    local cmdstr = config.inline_cmds[vim.bo.filetype]
    if cmdstr then
        local cmd = ":g/" .. cmdstr .. "/d "
        vim.cmd(cmd)
    end
end

-- If no breakpoint exists on the current line, place one and move the current
-- content down one row.
-- If a breakpoint exists on the current line, delete the current line.
---@param filetype string
---@param lnum number
function M.toggle_breakpoint(filetype, lnum)
    ---@type table
    local lines = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)

    if #lines == 0 then
        return
    end

    ---@type string
    local content = lines[1]

    if vim.trim(content) == config.inline_cmds[filetype] then
        -- Remove breakpoint marker
        vim.api.nvim_buf_set_text(0, lnum - 1, 0, lnum, 0, {''})
        return
    end

    -- Add breakpoint marker above current line
    local indent = string.rep(' ', vim.fn.indent(lnum))
    local cmdstr = indent .. config.inline_cmds[filetype]
    local new_lines = {cmdstr, ''}

    vim.api.nvim_buf_set_text(0, lnum - 1, 0, lnum - 1, 0, new_lines)

    -- Move cursor back up to the line with the breakpoint
    vim.cmd "normal! k"
end


return M
