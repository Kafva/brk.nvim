local config = require 'config'
local initfile = require 'formats.initfile'
local inline = require 'formats.inline'

local M = {}

---@param filetype string
function M.load_breakpoints(filetype)
    if vim.tbl_contains(config.initfile_filetypes, filetype) then
        local debugger_type = initfile.get_debugger_type(filetype)
        initfile.load_breakpoints(debugger_type)

    elseif vim.tbl_contains(config.inline_filetypes, filetype) then
        inline.load_breakpoints()

    else
        vim.notify("Cannot load breakpoints for unregistered filetype '" .. filetype .. "'",
                   vim.log.levels.ERROR)
    end
end

function M.delete_all_breakpoints()
    if vim.tbl_contains(config.initfile_filetypes, vim.bo.filetype) then
        local debugger_type = initfile.get_debugger_type(vim.bo.filetype)
        initfile.delete_all_breakpoints(debugger_type)

    elseif vim.tbl_contains(config.inline_filetypes, vim.bo.filetype) then
        inline.delete_all_breakpoints()

    else
        vim.notify("Cannot delete breakpoints for unregistered filetype '" .. vim.bo.filetype .. "'",
                   vim.log.levels.ERROR)
    end
end

function M.toggle_breakpoint(user_lnum)
    local lnum = user_lnum or vim.fn.line('.')
    local filetype = vim.bo.filetype

    if vim.tbl_contains(config.initfile_filetypes, filetype) then
        local debugger_type = initfile.get_debugger_type(filetype)
        initfile.toggle_breakpoint(debugger_type, lnum)

    elseif vim.tbl_contains(config.inline_filetypes, filetype) then
        inline.toggle_breakpoint(filetype, lnum)

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
        pattern = vim.tbl_flatten{config.initfile_filetypes,
                                  config.inline_filetypes},
        callback = function (ev)
            M.load_breakpoints(ev.match)
        end
    })
end

return M
