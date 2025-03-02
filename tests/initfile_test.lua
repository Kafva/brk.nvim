require('brk').setup {}

M = {}

local tsst = require 'tsst'
local initfile = require 'brk.formats.initfile'
local util = require 'brk.util'
local config = require 'brk.config'
local popover = require 'brk.popover'

---@param group string
---@param lnum number
---@return boolean
local function sign_exists(group, lnum)
    local buf = vim.api.nvim_get_current_buf()
    local bufsigns =
        vim.fn.sign_getplaced(buf, { group = group, lnum = tostring(lnum) })
    return #bufsigns > 0 and #bufsigns[1].signs > 0
end

M.before_each = function()
    -- Delete all breakpoints and initfiles from prior runs
    for _, dbg in pairs(DebuggerType) do
        initfile.delete_all_breakpoints(dbg)
        tsst.rm_f(config.default_opts.initfile_paths[dbg])
    end

    -- Close all open files
    repeat
        vim.cmd [[bd!]]
    until vim.fn.expand '%' == ''

    -- Restore files
    vim.system({ 'git', 'checkout', 'tests/files' }):wait()
end

M.testcases = {}

table.insert(M.testcases, {
    desc = 'Toggle a lldb breakpoint',
    fn = function()
        vim.cmd [[edit tests/files/c/main.c]]

        -- Add breakpoint
        initfile.toggle_breakpoint(DebuggerType.LLDB, 9)

        local content = util.readfile '.lldbinit'
        local expected = 'breakpoint set --file tests/files/c/main.c --line 9\n'
        tsst.assert_eql(expected, content)
        assert(sign_exists('brk', 9), 'no sign placed at line 9')

        -- Remove breakpoint
        initfile.toggle_breakpoint(DebuggerType.LLDB, 9)

        content = util.readfile '.lldbinit'
        tsst.assert_eql('', content)
        assert(not sign_exists('brk', 9), 'sign still placed at line 9')
    end,
})

table.insert(M.testcases, {
    desc = 'Toggle a gdb breakpoint',
    fn = function()
        vim.cmd [[edit tests/files/c/main.c]]

        -- Add breakpoint
        initfile.toggle_breakpoint(DebuggerType.GDB, 7)

        local content = util.readfile '.gdbinit'
        local expected = 'break tests/files/c/main.c:7\n' .. 'run\n'
        tsst.assert_eql(expected, content)
        assert(sign_exists('brk', 7), 'no sign placed at line 7')

        -- Remove breakpoint
        initfile.toggle_breakpoint(DebuggerType.GDB, 7)

        content = util.readfile '.gdbinit'
        tsst.assert_eql('', content)
        assert(not sign_exists('brk', 7), 'sign still placed at line 7')
    end,
})

table.insert(M.testcases, {
    desc = 'Toggle a delve breakpoint',
    fn = function()
        vim.cmd [[edit tests/files/go/main.go]]

        -- Add breakpoint
        initfile.toggle_breakpoint(DebuggerType.DELVE, 22)

        local content = util.readfile '.dlvinit'
        local expected = 'break testsfilesgomaingo22 ./tests/files/go/main.go:22\n'
            .. 'continue\n'
        tsst.assert_eql(expected, content)
        assert(sign_exists('brk', 22), 'no sign placed at line 22')

        -- Remove breakpoint
        initfile.toggle_breakpoint(DebuggerType.DELVE, 22)

        content = util.readfile '.dlvinit'
        tsst.assert_eql('', content)
        assert(not sign_exists('brk', 22), 'sign still placed at line 22')
    end,
})

table.insert(M.testcases, {
    desc = 'Toggle a jdb breakpoint',
    fn = function()
        vim.cmd [[edit tests/files/kt/java/org/myapp/Main.kt]]

        -- Add breakpoint
        initfile.toggle_breakpoint(DebuggerType.JDB, 10)

        local content = util.readfile '.jdbrc'
        local expected = '# org.myapp.Main tests/files/kt/java/org/myapp/Main.kt:10\n'
            .. 'stop in org.myapp.Main:10\n'
            .. 'repeat on\n'
            .. 'resume\n'
        tsst.assert_eql(expected, content)
        assert(sign_exists('brk', 10), 'no sign placed at line 10')

        -- Remove breakpoint
        initfile.toggle_breakpoint(DebuggerType.JDB, 10)

        content = util.readfile '.jdbrc'
        tsst.assert_eql('', content)
        assert(not sign_exists('brk', 10), 'sign still placed at line 10')
    end,
})

table.insert(M.testcases, {
    desc = 'Toggle a ghci breakpoint',
    fn = function()
        vim.cmd [[edit tests/files/hs/Main.hs]]

        -- Add breakpoint
        initfile.toggle_breakpoint(DebuggerType.GHCI, 17)

        local content = util.readfile '.ghci-init'
        local expected = '-- Main tests/files/hs/Main.hs:17\n'
            .. ':break Main 17\n'
        tsst.assert_eql(expected, content)
        assert(sign_exists('brk', 17), 'no sign placed at line 17')

        -- Remove breakpoint
        initfile.toggle_breakpoint(DebuggerType.GHCI, 17)

        content = util.readfile '.ghci-init'
        tsst.assert_eql('', content)
        assert(not sign_exists('brk', 17), 'sign still placed at line 17')
    end,
})

table.insert(M.testcases, {
    desc = 'Toggle a lldb conditional breakpoint',
    fn = function()
        vim.cmd [[edit tests/files/c/main.c]]

        -- Add breakpoint
        initfile.toggle_conditional_breakpoint(DebuggerType.LLDB, 6, 'i == 2')

        local content = util.readfile '.lldbinit'
        tsst.assert_eql(
            'breakpoint set --file tests/files/c/main.c --line 6 '
                .. "--condition 'i == 2'\n",
            content
        )
        assert(sign_exists('brk', 6), 'no sign placed at line 6')

        -- Remove breakpoint
        initfile.toggle_breakpoint(DebuggerType.LLDB, 6)

        content = util.readfile '.lldbinit'
        tsst.assert_eql(content, '')
        assert(not sign_exists('brk', 6), 'sign still placed at line 6')
    end,
})

table.insert(M.testcases, {
    desc = 'Toggle a gdb conditional breakpoint',
    fn = function()
        vim.cmd [[edit tests/files/c/main.c]]

        -- Add breakpoint
        initfile.toggle_conditional_breakpoint(DebuggerType.GDB, 6, 'i == 3')

        local content = util.readfile '.gdbinit'
        tsst.assert_eql(
            'break tests/files/c/main.c:6 if i == 3\n' .. 'run\n',
            content
        )
        assert(sign_exists('brk', 6), 'no sign placed at line 6')

        -- Remove breakpoint
        initfile.toggle_breakpoint(DebuggerType.GDB, 6)

        content = util.readfile '.gdbinit'
        tsst.assert_eql(content, '')
        assert(not sign_exists('brk', 6), 'sign still placed at line 6')
    end,
})

table.insert(M.testcases, {
    desc = 'Toggle a delve conditional breakpoint',
    fn = function()
        vim.cmd [[edit tests/files/go/main.go]]

        -- Add breakpoint
        initfile.toggle_conditional_breakpoint(DebuggerType.DELVE, 22, 'true')

        local content = util.readfile '.dlvinit'
        tsst.assert_eql(
            'break testsfilesgomaingo22 ./tests/files/go/main.go:22\n'
                .. 'cond testsfilesgomaingo22 true\n'
                .. 'continue\n',
            content
        )
        assert(sign_exists('brk', 22), 'no sign placed at line 22')

        -- Remove breakpoint
        initfile.toggle_breakpoint(DebuggerType.DELVE, 22)

        content = util.readfile '.dlvinit'
        tsst.assert_eql(content, '')
        assert(not sign_exists('brk', 22), 'sign still placed at line 22')
    end,
})

table.insert(M.testcases, {
    desc = 'Breakpoints are moved when sign placement changes due to more lines',
    fn = function()
        vim.cmd [[edit tests/files/go/main.go]]

        -- Add breakpoint
        initfile.toggle_breakpoint(DebuggerType.DELVE, 22)

        local content = util.readfile '.dlvinit'
        tsst.assert_eql(
            'break testsfilesgomaingo22 ./tests/files/go/main.go:22\n'
                .. 'continue\n',
            content
        )
        assert(sign_exists('brk', 22), 'no sign placed at line 22')

        -- Insert some more content before line 22
        vim.api.nvim_buf_set_lines(
            0,
            21,
            21,
            false,
            { '// line1', '// line2', '// line3', '// line4' }
        )
        vim.cmd [[silent write!]]

        -- Breakpoint should now be at line 26
        content = util.readfile '.dlvinit'
        local expected = 'break testsfilesgomaingo26 ./tests/files/go/main.go:26\n'
            .. 'continue\n'
        tsst.assert_eql(content, expected)
        assert(sign_exists('brk', 26), 'no sign placed at line 26')

        -- Cleanup on success
        vim.system({ 'git', 'checkout', 'tests/files' }):wait()
    end,
})

table.insert(M.testcases, {
    desc = 'Breakpoints are moved when sign placement changes due to deleted lines',
    fn = function()
        vim.cmd [[edit tests/files/go/main.go]]

        -- Add breakpoints
        vim.cmd [[b tests/files/go/main.go]]
        initfile.toggle_breakpoint(DebuggerType.DELVE, 22)

        local content = util.readfile '.dlvinit'
        tsst.assert_eql(
            'break testsfilesgomaingo22 ./tests/files/go/main.go:22\n'
                .. 'continue\n',
            content
        )

        assert(sign_exists('brk', 22), 'no sign placed at line 22')

        -- Delete line 22
        vim.api.nvim_buf_set_lines(0, 21, 22, false, {})
        vim.cmd [[silent wa!]]

        -- Breakpoint should be removed
        content = util.readfile '.dlvinit'
        tsst.assert_eql(content, '')

        -- Cleanup on success
        vim.system({ 'git', 'checkout', 'tests/files' }):wait()
    end,
})

table.insert(M.testcases, {
    desc = 'Breakpoints are moved when sign placement changes due to more lines in two buffers',
    fn = function()
        vim.cmd [[edit tests/files/go/main.go]]
        vim.cmd [[edit tests/files/go/util.go]]

        -- Add breakpoints
        vim.cmd [[b tests/files/go/main.go]]
        initfile.toggle_breakpoint(DebuggerType.DELVE, 22)
        vim.cmd [[b tests/files/go/util.go]]
        initfile.toggle_breakpoint(DebuggerType.DELVE, 13)

        local content = util.readfile '.dlvinit'
        tsst.assert_eql(
            'break testsfilesgomaingo22 ./tests/files/go/main.go:22\n'
                .. 'break testsfilesgoutilgo13 ./tests/files/go/util.go:13\n'
                .. 'continue\n',
            content
        )

        vim.cmd [[b tests/files/go/main.go]]
        assert(sign_exists('brk', 22), 'no sign placed at line 22')
        vim.cmd [[b tests/files/go/util.go]]
        assert(sign_exists('brk', 13), 'no sign placed at line 13')

        -- Insert some more content before line 22
        vim.cmd [[b tests/files/go/main.go]]
        vim.api.nvim_buf_set_lines(
            0,
            21,
            21,
            false,
            { '// line1', '// line2', '// line3', '// line4' }
        )
        -- Insert some more content before line 13
        vim.cmd [[b tests/files/go/util.go]]
        vim.api.nvim_buf_set_lines(
            0,
            12,
            12,
            false,
            { '// line1', '// line2', '// line3', '// line4' }
        )
        vim.cmd [[silent wa!]]

        -- Breakpoint should now be at lines 26 and 17
        content = util.readfile '.dlvinit'
        tsst.assert_eql(
            'break testsfilesgomaingo26 ./tests/files/go/main.go:26\n'
                .. 'break testsfilesgoutilgo17 ./tests/files/go/util.go:17\n'
                .. 'continue\n',
            content
        )

        vim.cmd [[b tests/files/go/main.go]]
        assert(sign_exists('brk', 26), 'no sign placed at line 26')
        vim.cmd [[b tests/files/go/util.go]]
        assert(sign_exists('brk', 17), 'no sign placed at line 17')

        -- Cleanup on success
        vim.system({ 'git', 'checkout', 'tests/files' }):wait()
    end,
})

table.insert(M.testcases, {
    desc = 'Toggle a lldb symbol breakpoint after adding a regular breakpoint',
    fn = function()
        vim.cmd [[edit tests/files/c/main.c]]

        -- Add regular breakpoints followed by a symbol breakpoint
        initfile.toggle_breakpoint(DebuggerType.LLDB, 10)
        initfile.toggle_symbol_breakpoint(DebuggerType.LLDB, 'printf')

        local content = util.readfile '.lldbinit'
        tsst.assert_eql(
            'breakpoint set --file tests/files/c/main.c --line 10\n'
                .. 'breakpoint set -n printf\n',
            content
        )

        -- Remove symbol breakpoint
        initfile.toggle_symbol_breakpoint(DebuggerType.LLDB, 'printf')

        content = util.readfile '.lldbinit'
        tsst.assert_eql(
            'breakpoint set --file tests/files/c/main.c --line 10\n',
            content
        )
    end,
})

table.insert(M.testcases, {
    desc = 'Popover navigation to another open buffer',
    fn = function()
        vim.cmd [[edit tests/files/go/main.go]]
        vim.cmd [[edit tests/files/go/util.go]]

        -- Add a breakpoint in both files
        vim.cmd [[b tests/files/go/main.go]]
        initfile.toggle_breakpoint(DebuggerType.DELVE, 22)
        vim.cmd [[b tests/files/go/util.go]]
        initfile.toggle_breakpoint(DebuggerType.DELVE, 13)

        initfile.list_breakpoints()

        -- Select the first entry after a short delay
        vim.api.nvim_win_set_cursor(0, { 2, 0 })
        popover.goto_breakpoint()

        tsst.assert_eql('tests/files/go/main.go', vim.fn.expand '%')
        tsst.assert_eql(22, vim.fn.line '.')
    end,
})

table.insert(M.testcases, {
    desc = 'Switching to a different filetype reloads breakpoints',
    fn = function()
        local breakpoints
        vim.cmd [[edit tests/files/hs/Main.hs]]
        vim.cmd [[edit tests/files/go/main.go]]

        -- Add a breakpoint in both files
        vim.cmd [[b tests/files/hs/Main.hs]]
        initfile.toggle_breakpoint(DebuggerType.GHCI, 19)
        vim.cmd [[b tests/files/go/main.go]]
        initfile.toggle_breakpoint(DebuggerType.DELVE, 15)

        -- Go back to the first file and verify the list of breakpoints
        vim.cmd [[b tests/files/hs/Main.hs]]
        breakpoints = initfile.get_breakpoints()
        tsst.assert_eql(1, #breakpoints)
        tsst.assert_eql('tests/files/hs/Main.hs', breakpoints[1].file)
        tsst.assert_eql(19, breakpoints[1].lnum)
        tsst.assert_eql('Main19', breakpoints[1].name)

        -- Go back to the second file and verify the list of breakpoints
        vim.cmd [[b tests/files/go/main.go]]
        breakpoints = initfile.get_breakpoints()
        tsst.assert_eql(1, #breakpoints)
        tsst.assert_eql('./tests/files/go/main.go', breakpoints[1].file)
        tsst.assert_eql(15, breakpoints[1].lnum)
        tsst.assert_eql('testsfilesgomaingo15', breakpoints[1].name)
    end,
})

return M
