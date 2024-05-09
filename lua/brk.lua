local config = require 'config'
local lldb = require 'parsers.lldb'

local M = {}

function M.toggle_breakpoint()
    local buf = vim.api.nvim_get_current_buf()
    local lnum = vim.fn.line('.')

    ---@type table
    local bufsigns = vim.fn.sign_getplaced(buf, {group='brk', lnum = lnum})

    if #bufsigns > 0 and #bufsigns[1].signs > 0 then
        for _, sign in ipairs(bufsigns[1].signs) do
            vim.fn.sign_unplace('brk', {id = sign.id})
        end
    else
        vim.fn.sign_place(0, "brk", "BrkBreakpoint", buf, {
            lnum = lnum,
            priority = config.breakpoint_sign_priority})
    end
end


function M.delete_all_breakpoints()
    vim.fn.sign_unplace('brk')
end

function M.load_breakpoints(filetype)
    local buf = vim.api.nvim_get_current_buf()
    local breakpoints = {}

    if filetype == 'c' or
       filetype == 'cpp' or
       filetype == 'rust' or
       filetype == 'objc' then
         breakpoints = lldb.read_breakpoints()
    end

     for _,breakpoint in pairs(breakpoints) do
         local file = breakpoint.file
         local lnum = breakpoint.lnum
         if vim.fn.expand'%' == file then
             vim.fn.sign_place(0, "brk", "BrkBreakpoint", buf, {
                 lnum = lnum,
                 priority = config.breakpoint_sign_priority
             })
         end
     end

end

---@param user_opts BrkOptions?
function M.setup(user_opts)
    config.setup(user_opts)

    -- We want to parse the breakpoints file whenever a new buffer is opened
    vim.api.nvim_create_autocmd("Filetype", {
        pattern = config.filetypes,
        callback = function (ev)
            M.load_breakpoints(ev.match)
        end
    })
end

return M
