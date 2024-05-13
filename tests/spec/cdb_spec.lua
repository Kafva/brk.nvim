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

---@param group string
---@param lnum number
---@return boolean
local function sign_exists(group, lnum)
    local buf = vim.api.nvim_get_current_buf()
    local bufsigns = vim.fn.sign_getplaced(buf, { group = group, lnum = tostring(lnum) })
    return #bufsigns > 0 and #bufsigns[1].signs > 0
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
        assert(sign_exists('brk', 9), 'no sign placed at line 9')

        -- Remove breakpoint
        cdb.toggle_breakpoint('lldb', './.lldbinit', nil, 9)

        content = util.readfile('.lldbinit')
        assert.equals("", content)
        assert(not sign_exists('brk', 9), 'sign still placed at line 9')
    end)

    it("Toggle a breakpoint in gdbinit", function()
        -- Add breakpoint
        cdb.toggle_breakpoint('gdb', './.gdbinit', nil, 7)

        local content = util.readfile('.gdbinit')
        assert.equals("break ../files/main.c:7\n", content)
        assert(sign_exists('brk', 7), 'no sign placed at line 7')

        -- Remove breakpoint
        cdb.toggle_breakpoint('gdb', './.gdbinit', nil, 7)

        content = util.readfile('.gdbinit')
        assert.equals("", content)
        assert(not sign_exists('brk', 7), 'sign still placed at line 7')
    end)
end)
