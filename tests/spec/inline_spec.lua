require 'brk'.setup()
local config = require 'config'

local assert = require 'luassert.assert'
local inline = require "formats.inline"

describe("Script breakpoints:", function()
    before_each(function()
        inline.delete_all_breakpoints()
    end)

    it("Toggle a Python breakpoint", function()
        local lnum = 12
        vim.cmd[[edit tests/files/py/main.py]]
        local original_content = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, true)[1]

        -- Add breakpoint
        inline.toggle_breakpoint('python', lnum)
        local current_line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, true)[1]
        assert.equal(config.inline_cmds['python'], vim.trim(current_line))

        -- Remove breakpoint (on line above initial target line)
        inline.toggle_breakpoint('python', lnum)
        current_line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, true)[1]
        assert.equal(original_content, current_line)
    end)
end)
