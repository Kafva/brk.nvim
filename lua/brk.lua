local config = require 'config'
local fmt_c = require 'formats.c'
local fmt_delve = require 'formats.delve'
local fmt_script = require 'formats.script'

local M = {}

---@param filetype string
function M.load_breakpoints(filetype)
    if vim.tbl_contains(config.filetypes_c, filetype) then
        fmt_c.load_breakpoints()

    elseif vim.tbl_contains(config.filetypes_delve, filetype) then
        fmt_delve.load_breakpoints()

    elseif vim.tbl_contains(config.filetypes_script, filetype) then
        fmt_script.load_breakpoints()

    else
        vim.notify("Cannot load breakpoints for unregistered filetype '" .. filetype .. "'",
                   vim.log.levels.ERROR)
    end
end

function M.delete_all_breakpoints()
    if vim.tbl_contains(config.filetypes_c, vim.bo.filetype) then
        fmt_c.delete_all_breakpoints()

    elseif vim.tbl_contains(config.filetypes_delve, vim.bo.filetype) then
        fmt_delve.delete_all_breakpoints()

    elseif vim.tbl_contains(config.filetypes_script, vim.bo.filetype) then
        fmt_script.delete_all_breakpoints()

    else
        vim.notify("Cannot delete breakpoints for unregistered filetype '" .. vim.bo.filetype .. "'",
                   vim.log.levels.ERROR)
    end
end

function M.toggle_breakpoint()
    local lnum = vim.fn.line('.')

    if vim.tbl_contains(config.filetypes_c, vim.bo.filetype) then
        fmt_c.toggle_breakpoint(vim.bo.filetype, lnum)

    elseif vim.tbl_contains(config.filetypes_delve, vim.bo.filetype) then
        fmt_delve.toggle_breakpoint(vim.bo.filetype, lnum)

    elseif vim.tbl_contains(config.filetypes_script, vim.bo.filetype) then
        fmt_script.toggle_breakpoint(vim.bo.filetype, lnum)

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
