-- Setup with default config
require 'brk'.setup()

local assert = require 'luassert.assert'
local initfile = require "formats.initfile"
local util = require "util"
local test_util = require "tests.test_util"

--- Tests are not ran in parallel
describe("lldb/gdb breakpoints:", function()
    before_each(function()
        initfile.delete_all_breakpoints('lldb')
        initfile.delete_all_breakpoints('gdb')
        initfile.delete_all_breakpoints('delve')

        test_util.rm_f('./.lldbinit')
        test_util.rm_f('./.gdbinit')
        test_util.rm_f('./.dlvinit')
    end)

    after_each(function()
        test_util.rm_f('./.lldbinit')
        test_util.rm_f('./.gdbinit')
        test_util.rm_f('./.dlvinit')
    end)

    it("Toggle a lldb breakpoint", function()
        vim.cmd[[edit tests/files/c/main.c]]

        -- Add breakpoint
        initfile.toggle_breakpoint(DebuggerType.LLDB, 9)

        local content = util.readfile('.lldbinit')
        assert.equals("breakpoint set --file tests/files/c/main.c --line 9\n" .. "run\n", content)
        assert(test_util.sign_exists('brk', 9), 'no sign placed at line 9')

        -- Remove breakpoint
        initfile.toggle_breakpoint(DebuggerType.LLDB, 9)

        content = util.readfile('.lldbinit')
        assert.equals("", content)
        assert(not test_util.sign_exists('brk', 9), 'sign still placed at line 9')
    end)

    it("Toggle a gdb breakpoint", function()
        vim.cmd[[edit tests/files/c/main.c]]

        -- Add breakpoint
        initfile.toggle_breakpoint(DebuggerType.GDB, 7)

        local content = util.readfile('.gdbinit')
        assert.equals("break tests/files/c/main.c:7\n" .. "run\n", content)
        assert(test_util.sign_exists('brk', 7), 'no sign placed at line 7')

        -- Remove breakpoint
        initfile.toggle_breakpoint(DebuggerType.GDB, 7)

        content = util.readfile('.gdbinit')
        assert.equals("", content)
        assert(not test_util.sign_exists('brk', 7), 'sign still placed at line 7')
    end)

    it("Toggle a delve breakpoint", function()
        vim.cmd[[edit tests/files/go/main.go]]

        -- Add breakpoint
        initfile.toggle_breakpoint(DebuggerType.DELVE, 22)

        local content = util.readfile('.dlvinit')
        assert.equals("break testsfilesgomaingo22 tests/files/go/main.go:22\n" .. "continue\n", content)
        assert(test_util.sign_exists('brk', 22), 'no sign placed at line 22')

        -- Remove breakpoint
        initfile.toggle_breakpoint(DebuggerType.DELVE, 22)

        content = util.readfile('.dlvinit')
        assert.equals("", content)
        assert(not test_util.sign_exists('brk', 22), 'sign still placed at line 22')
    end)
end)
