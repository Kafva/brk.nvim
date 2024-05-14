require 'brk'.setup()
local config = require 'config'

local assert = require 'luassert.assert'
local script = require "formats.script"

--- Tests are not ran in parallel
describe("Script breakpoints:", function()
    before_each(function()
        script.delete_all_breakpoints()
    end)

    it("Toggle a Python breakpoint", function()
        local lnum = 12
        vim.cmd[[edit tests/files/main.py]]
        local original_content = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, true)[1]

        -- Add breakpoint
        script.toggle_breakpoint('python', lnum)
        local current_line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, true)[1]
        assert.equal(config.script_cmds['python'], vim.trim(current_line))

        -- Remove breakpoint (on line above initial target line)
        script.toggle_breakpoint('python', lnum)
        current_line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, true)[1]
        assert.equal(original_content, current_line)
    end)
end)
