-- https://github.com/neovim/neovim/blob/master/contrib/gdb/neovim_gdb.vim
-- https://github.com/mfussenegger/nvim-dap
-- https://github.com/puremourning/vimspector

-- Integrated debuggers like nvim-dap can be nice but I prefer to run debugpy,
-- lldb etc. from another split/window instead of integrating it fully with my
-- editor.
--
-- This "plugin" enables breakpoint managment from within vim, the actual
-- execution of the debugger is done externally.
-- To make it possible to work with different debugger backends,
--
--
-- We want our approach to be as debugger agnostic as possible, i.e. probably
-- rely on the dap protocol

local util = require('util')

local M = {}

local cfg = {}

if vim.g.brk_loaded == nil then
    vim.fn.sign_define('BrkBreakpoint',  {text='󰝥 ', numhl='', linehl='', texthl='Error'})
    vim.keymap.set('n', '<F9>', function() require('brk').toggle_breakpoint() end)
    vim.g.brk_loaded = 1
end


local function write_breakpoints_lldb()
    local conf = "./.lldbinit"
    local content = ""
    for _,breakpoint in pairs(cfg["breakpoints"]) do
        content = content .. "breakpoint set " ..
                                " --file " .. breakpoint["file"] ..
                                " --line " .. tostring(breakpoint["line"]) ..
                                "\n"
    end
    util.writefile(conf, content)
end

function M.load_breakpoints()
    local brkcfg = util.readfile(".brk.json")
    if #brkcfg == 0 then
        return
    end
    cfg = vim.json.decode(brkcfg)
    write_breakpoints_lldb()
end

function M.toggle_breakpoint()
    local buf = vim.api.nvim_get_current_buf()
    vim.fn.sign_place(0, "", "BrkBreakpoint", buf, { lnum = vim.fn.line('.'), priority = 90 })
end


function M.setup()
    M.load_breakpoints()
end

return M
