-- Setup with default config
require 'brk'.setup()

local assert = require 'luassert.assert'
local initfile = require "brk.formats.initfile"
local util = require "brk.util"
local test_util = require "tests.test_util"

--- Tests are not ran in parallel
describe("Initfile breakpoints:", function()
    before_each(function()
        initfile.delete_all_breakpoints('lldb')
        initfile.delete_all_breakpoints('gdb')
        initfile.delete_all_breakpoints('delve')

        test_util.rm_f('./.lldbinit')
        test_util.rm_f('./.gdbinit')
        test_util.rm_f('./.dlvinit')
        vim.system({"git", "checkout", "tests/files"})
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
        assert.equals("break testsfilesgomaingo22 ./tests/files/go/main.go:22\n" .. "continue\n", content)
        assert(test_util.sign_exists('brk', 22), 'no sign placed at line 22')

        -- Remove breakpoint
        initfile.toggle_breakpoint(DebuggerType.DELVE, 22)

        content = util.readfile('.dlvinit')
        assert.equals("", content)
        assert(not test_util.sign_exists('brk', 22), 'sign still placed at line 22')
    end)

    it("Toggle a conditional lldb breakpoint", function()
        vim.cmd[[edit tests/files/c/main.c]]

        -- Add breakpoint
        initfile.toggle_breakpoint_conditional(DebuggerType.LLDB, 6, 'i == 2')

        local content = util.readfile('.lldbinit')
        assert.equals("breakpoint set --file tests/files/c/main.c --line 6 " ..
                      "--condition i == 2\n" ..
                      "run\n", content)
        assert(test_util.sign_exists('brk', 6), 'no sign placed at line 6')

        -- Remove breakpoint
        initfile.toggle_breakpoint(DebuggerType.LLDB, 6)

        content = util.readfile('.lldbinit')
        assert.equals("", content)
        assert(not test_util.sign_exists('brk', 6), 'sign still placed at line 6')
    end)

    it("Toggle a conditional gdb breakpoint", function()
        vim.cmd[[edit tests/files/c/main.c]]

        -- Add breakpoint
        initfile.toggle_breakpoint_conditional(DebuggerType.GDB, 6, 'i == 3')

        local content = util.readfile('.gdbinit')
        assert.equals("break tests/files/c/main.c:6 if i == 3\n" .. 
                      "run\n", content)
        assert(test_util.sign_exists('brk', 6), 'no sign placed at line 6')

        -- Remove breakpoint
        initfile.toggle_breakpoint(DebuggerType.GDB, 6)

        content = util.readfile('.gdbinit')
        assert.equals("", content)
        assert(not test_util.sign_exists('brk', 6), 'sign still placed at line 6')
    end)

    it("Toggle a conditional delve breakpoint", function()
        vim.cmd[[edit tests/files/go/main.go]]

        -- Add breakpoint
        initfile.toggle_breakpoint_conditional(DebuggerType.DELVE, 22, 'true')

        local content = util.readfile('.dlvinit')
        assert.equals("break testsfilesgomaingo22 ./tests/files/go/main.go:22\n" ..
                      "cond testsfilesgomaingo22 true\n" ..
                      "continue\n", content)
        assert(test_util.sign_exists('brk', 22), 'no sign placed at line 22')

        -- Remove breakpoint
        initfile.toggle_breakpoint(DebuggerType.DELVE, 22)

        content = util.readfile('.dlvinit')
        assert.equals("", content)
        assert(not test_util.sign_exists('brk', 22), 'sign still placed at line 22')
    end)

    it("Breakpoints are moved when sign placement changes", function()
        vim.cmd[[edit tests/files/go/main.go]]

        -- Add breakpoint
        initfile.toggle_breakpoint(DebuggerType.DELVE, 22)

        local content = util.readfile('.dlvinit')
        assert.equals("break testsfilesgomaingo22 ./tests/files/go/main.go:22\n" .. "continue\n", content)
        assert(test_util.sign_exists('brk', 22), 'no sign placed at line 22')

        -- Insert some more content before line 22
        vim.api.nvim_buf_set_lines(0, 21, 21, false, { "// line1",
                                                       "// line2",
                                                       "// line3",
                                                       "// line4" })
        vim.cmd[[write]]

        -- Breakpoint should now be at line 26
        content = util.readfile('.dlvinit')
        assert.equals("break testsfilesgomaingo26 ./tests/files/go/main.go:26\n" .. "continue\n", content)
        assert(test_util.sign_exists('brk', 26), 'no sign placed at line 26')
    end)

    it("Breakpoints are moved when sign placement changes in two buffers", function()
        vim.cmd[[edit tests/files/go/main.go]]
        vim.cmd[[edit tests/files/go/util.go]]

        -- Add breakpoints
        vim.cmd[[b tests/files/go/main.go]]
        initfile.toggle_breakpoint(DebuggerType.DELVE, 22)
        vim.cmd[[b tests/files/go/util.go]]
        initfile.toggle_breakpoint(DebuggerType.DELVE, 13)


        local content = util.readfile('.dlvinit')
        assert.equals("break testsfilesgomaingo22 ./tests/files/go/main.go:22\n" ..
                      "break testsfilesgoutilgo13 ./tests/files/go/util.go:13\n" ..
                      "continue\n", content)

        vim.cmd[[b tests/files/go/main.go]]
        assert(test_util.sign_exists('brk', 22), 'no sign placed at line 22')
        vim.cmd[[b tests/files/go/util.go]]
        assert(test_util.sign_exists('brk', 13), 'no sign placed at line 13')

        -- Insert some more content before line 22
        vim.cmd[[b tests/files/go/main.go]]
        vim.api.nvim_buf_set_lines(0, 21, 21, false, { "// line1",
                                                       "// line2",
                                                       "// line3",
                                                       "// line4" })
        -- Insert some more content before line 13
        vim.cmd[[b tests/files/go/util.go]]
        vim.api.nvim_buf_set_lines(0, 12, 12, false, { "// line1",
                                                       "// line2",
                                                       "// line3",
                                                       "// line4" })
        vim.cmd[[wa]]

        -- Breakpoint should now be at lines 26 and 17
        content = util.readfile('.dlvinit')
        assert.equals("break testsfilesgomaingo26 ./tests/files/go/main.go:26\n" ..
                      "break testsfilesgoutilgo17 ./tests/files/go/util.go:17\n" ..
                      "continue\n", content)

        vim.cmd[[b tests/files/go/main.go]]
        assert(test_util.sign_exists('brk', 26), 'no sign placed at line 26')
        vim.cmd[[b tests/files/go/util.go]]
        assert(test_util.sign_exists('brk', 17), 'no sign placed at line 17')
    end)
end)
