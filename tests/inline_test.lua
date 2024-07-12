require('brk').setup {}

local M = {}

local config = require 'brk.config'
local popover = require 'brk.popover'
local inline = require 'brk.formats.inline'
local t = require 'tests.init'

M.testcases = {}

M.before_each = function()
    inline.delete_all_breakpoints()

    -- Close all open files
    repeat
        vim.cmd [[bd!]]
    until vim.fn.expand '%' == ''

    vim.system({ 'git', 'checkout', 'tests/files' }):wait()
end

table.insert(M.testcases, {
    desc = 'Toggle a Python breakpoint',
    fn = function()
        local lnum = 12
        vim.cmd [[edit tests/files/py/main.py]]
        local original_content =
            vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, true)[1]

        -- Add breakpoint
        inline.toggle_breakpoint('python', lnum)
        local current_line =
            vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, true)[1]
        t.assert_eq(vim.trim(current_line), config.inline_cmds['python'])

        -- Remove breakpoint (on line above initial target line)
        inline.toggle_breakpoint('python', lnum)
        current_line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, true)[1]
        t.assert_eq(current_line, original_content)
    end,
})

table.insert(M.testcases, {
    desc = 'Popover navigation to another open buffer',
    fn = function()
        local main_lnum = 12
        local util_lnum = 10
        local current_line = ''
        vim.cmd [[edit tests/files/py/main.py]]
        vim.cmd [[edit tests/files/py/util.py]]

        -- Add a breakpoint in both files
        vim.cmd [[b tests/files/py/main.py]]
        vim.api.nvim_win_set_cursor(0, { main_lnum, 0 })
        inline.toggle_breakpoint('python', vim.fn.line '.')

        current_line =
            vim.api.nvim_buf_get_lines(0, main_lnum - 1, main_lnum, true)[1]
        t.assert_eq(vim.trim(current_line), config.inline_cmds['python'])

        vim.cmd [[b tests/files/py/util.py]]
        vim.api.nvim_win_set_cursor(0, { util_lnum, 0 })
        inline.toggle_breakpoint('python', util_lnum)

        current_line =
            vim.api.nvim_buf_get_lines(0, util_lnum - 1, util_lnum, true)[1]
        t.assert_eq(vim.trim(current_line), config.inline_cmds['python'])

        inline.list_breakpoints 'python'

        -- Select the first entry after a short delay
        vim.api.nvim_win_set_cursor(0, { 2, 0 })
        popover.goto_breakpoint()

        t.assert_eq(vim.fn.expand '%', 'tests/files/py/main.py')
        t.assert_eq(vim.fn.line '.', 12)
    end,
})

return M
