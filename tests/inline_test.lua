require 'brk'.setup {}

local M = {}

local config = require 'brk.config'
local inline = require 'brk.formats.inline'
local t = require 'tests.init'

M.testcases = {}

M.before_each = function()
    inline.delete_all_breakpoints()
end

table.insert(M.testcases, { desc = "Toggle a Python breakpoint",
                 fn = function()
    local lnum = 12
    vim.cmd[[edit tests/files/py/main.py]]
    local original_content = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, true)[1]

    -- Add breakpoint
    inline.toggle_breakpoint('python', lnum)
    local current_line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, true)[1]
    t.assert_eq(config.inline_cmds['python'], vim.trim(current_line))

    -- Remove breakpoint (on line above initial target line)
    inline.toggle_breakpoint('python', lnum)
    current_line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, true)[1]
    t.assert_eq(original_content, current_line)
end})


return M
