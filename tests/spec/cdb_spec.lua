-- Setup with default config
require 'brk'.setup()

local assert = require 'luassert.assert'
local cdb = require "formats.cdb"
local util = require "util"

---@type uv
local uv = vim.uv

local function rm_f(filepath)
    local _, err, errno = uv.fs_unlink(filepath)
    if errno ~= nil and errno ~= "ENOENT" then
        error(err)
    end
end

--- Tests are not ran in parallel
describe("lldb/gdb breakpoints:", function()
    before_each(function()
        cdb.delete_all_breakpoints('lldb', './.lldbinit')
        cdb.delete_all_breakpoints('gdb', './.gdbinit')

        rm_f('./.lldbinit')
        rm_f('./.gdbinit')

        vim.cmd[[edit ../files/main.c]]
    end)

    it("Toggle a breakpoint in lldbinit", function()
        -- Add breakpoint
        cdb.toggle_breakpoint('lldb', './.lldbinit', nil, 9)

        local content = util.readfile('.lldbinit')
        assert.equals("breakpoint set --file ../files/main.c --line 9\n", content)

        -- Remove breakpoint
        cdb.toggle_breakpoint('lldb', './.lldbinit', nil, 9)

        content = util.readfile('.lldbinit')
        assert.equals("", content)
    end)

    it("Toggle a breakpoint in gdbinit", function()
        -- Add breakpoint
        cdb.toggle_breakpoint('gdb', './.gdbinit', nil, 7)

        local content = util.readfile('.gdbinit')
        assert.equals("break ../files/main.c:7\n", content)

        -- Remove breakpoint
        cdb.toggle_breakpoint('gdb', './.gdbinit', nil, 7)

        content = util.readfile('.gdbinit')
        assert.equals("", content)
    end)
end)
