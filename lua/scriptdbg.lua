local M = {}

function M.load_breakpoints()
end

function M.delete_all_breakpoints()
end

function M.toggle_breakpoint(filetype, lnum)
    -- if line ~= 1 then
    --     line = vim.fn.line('.') - 1
    -- end

    -- local current_line = vim.api.nvim_get_current_line()
    -- local match, _ = current_line:find(config.cmds_script[filetype])
    -- if match then
    --     vim.api.nvim_buf_set_text(0, line, 0, line + 1, 0, {''})
    --     return
    -- end

    -- local cmdstr = config.cmds_script[filetype]
    -- vim.api.nvim_buf_set_text(0, line, line, false, {cmdstr})
    -- vim.cmd 'normal! k'
end


return M
