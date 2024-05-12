local config = require 'config'
local cdb = require 'formats.cdb'
local delve = require 'formats.delve'
local script = require 'formats.script'

local M = {}

---@param filetype string
function M.load_breakpoints(filetype)
    if vim.tbl_contains(config.cdb_filetypes, filetype) then
        cdb.load_breakpoints()

    elseif vim.tbl_contains(config.delve_filetypes, filetype) then
        delve.load_breakpoints()

    elseif vim.tbl_contains(config.script_filetypes, filetype) then
        script.load_breakpoints()

    else
        vim.notify("Cannot load breakpoints for unregistered filetype '" .. filetype .. "'",
                   vim.log.levels.ERROR)
    end
end

function M.delete_all_breakpoints()
    if vim.tbl_contains(config.cdb_filetypes, vim.bo.filetype) then
        cdb.delete_all_breakpoints()

    elseif vim.tbl_contains(config.delve_filetypes, vim.bo.filetype) then
        delve.delete_all_breakpoints()

    elseif vim.tbl_contains(config.script_filetypes, vim.bo.filetype) then
        script.delete_all_breakpoints()

    else
        vim.notify("Cannot delete breakpoints for unregistered filetype '" .. vim.bo.filetype .. "'",
                   vim.log.levels.ERROR)
    end
end

function M.toggle_breakpoint(lnum)
    ---@diagnostic disable-next-line: redefined-local
    local lnum = lnum or vim.fn.line('.')
    local filetype = vim.bo.filetype

    if vim.tbl_contains(config.cdb_filetypes, filetype) then
        cdb.toggle_breakpoint(filetype, lnum)

    elseif vim.tbl_contains(config.delve_filetypes, filetype) then
        delve.toggle_breakpoint(filetype, lnum)

    elseif vim.tbl_contains(config.script_filetypes, filetype) then
        script.toggle_breakpoint(filetype, lnum)

    else
        vim.notify("No breakpoint support for filetype: '" .. filetype .. "'",
                   vim.log.levels.WARN)
    end
end

---@param user_opts BrkOptions?
function M.setup(user_opts)
    config.setup(user_opts)

    -- Load breakpoints for each FileType event
    vim.api.nvim_create_autocmd("Filetype", {
        pattern = vim.tbl_flatten{config.cdb_filetypes,
                                  config.delve_filetypes,
                                  config.script_filetypes},
        callback = function (ev)
            M.load_breakpoints(ev.match)
        end
    })
end

return M
