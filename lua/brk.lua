local config = require 'config'
local cdbg = require 'cdbg'
local godbg = require 'godbg'
local scriptdbg = require 'scriptdbg'

local M = {}

---@param filetype string
function M.load_breakpoints(filetype)
    if vim.tbl_contains(config.filetypes_c, filetype) then
        cdbg.load_breakpoints()

    elseif vim.tbl_contains(config.filetypes_go, filetype) then
        godbg.load_breakpoints()

    elseif vim.tbl_contains(config.filetypes_script, filetype) then
        scriptdbg.load_breakpoints()

    else
        vim.notify("Cannot load breakpoints for unregistered filetype '" .. filetype .. "'",
                   vim.log.levels.ERROR)
    end
end

function M.delete_all_breakpoints()
    if vim.tbl_contains(config.filetypes_c, vim.bo.filetype) then
        cdbg.delete_all_breakpoints()

    elseif vim.tbl_contains(config.filetypes_go, vim.bo.filetype) then
        godbg.delete_all_breakpoints()

    elseif vim.tbl_contains(config.filetypes_script, vim.bo.filetype) then
        scriptdbg.delete_all_breakpoints()

    else
        vim.notify("Cannot delete breakpoints for unregistered filetype '" .. vim.bo.filetype .. "'",
                   vim.log.levels.ERROR)
    end
end

function M.toggle_breakpoint()
    local lnum = vim.fn.line('.')

    if vim.tbl_contains(config.filetypes_c, vim.bo.filetype) then
        cdbg.toggle_breakpoint(vim.bo.filetype, lnum)

    elseif vim.tbl_contains(config.filetypes_go, vim.bo.filetype) then
        godbg.toggle_breakpoint(vim.bo.filetype, lnum)

    elseif vim.tbl_contains(config.filetypes_script, vim.bo.filetype) then
        scriptdbg.toggle_breakpoint(vim.bo.filetype, lnum)

    else
        vim.notify("No breakpoint support for filetype: '" .. vim.bo.filetype .. "'",
                   vim.log.levels.WARN)
    end
end

---@param user_opts BrkOptions?
function M.setup(user_opts)
    config.setup(user_opts)

    -- Load breakpoints for each FileType event
    vim.api.nvim_create_autocmd("Filetype", {
        pattern = vim.tbl_flatten{config.filetypes_c,
                                  config.filetypes_go,
                                  config.filetypes_script},
        callback = function (ev)
            M.load_breakpoints(ev.match)
        end
    })
end

return M
