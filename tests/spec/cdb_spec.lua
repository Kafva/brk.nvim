-- Setup with default config
require 'brk'.setup()

local assert = require 'luassert.assert'
local cdb = require "formats.cdb"
local util = require "util"
local test_util = require "test_util"

--- Tests are not ran in parallel
describe("lldb/gdb breakpoints:", function()
    before_each(function()
        cdb.delete_all_breakpoints('lldb', './.lldbinit')
        cdb.delete_all_breakpoints('gdb', './.gdbinit')

        test_util.rm_f('./.lldbinit')
        test_util.rm_f('./.gdbinit')

        vim.cmd[[edit ../files/main.c]]
    end)

    it("Toggle a lldb breakpoint", function()
        -- Add breakpoint
        cdb.toggle_breakpoint('lldb', './.lldbinit', nil, 9)

        local content = util.readfile('.lldbinit')
        assert.equals("breakpoint set --file ../files/main.c --line 9\n", content)
        assert(test_util.sign_exists('brk', 9), 'no sign placed at line 9')

        -- Remove breakpoint
        cdb.toggle_breakpoint('lldb', './.lldbinit', nil, 9)

        content = util.readfile('.lldbinit')
        assert.equals("", content)
        assert(not test_util.sign_exists('brk', 9), 'sign still placed at line 9')
    end)

    it("Toggle a gdb breakpoint", function()
        -- Add breakpoint
        cdb.toggle_breakpoint('gdb', './.gdbinit', nil, 7)

        local content = util.readfile('.gdbinit')
        assert.equals("break ../files/main.c:7\n", content)
        assert(test_util.sign_exists('brk', 7), 'no sign placed at line 7')

        -- Remove breakpoint
        cdb.toggle_breakpoint('gdb', './.gdbinit', nil, 7)

        content = util.readfile('.gdbinit')
        assert.equals("", content)
        assert(not test_util.sign_exists('brk', 7), 'sign still placed at line 7')
    end)
end)
