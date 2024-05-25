local config = require 'brk.config'
local initfile = require 'brk.formats.initfile'
local inline = require 'brk.formats.inline'

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

---@param filetype string
function M.update_breakpoints(filetype)
    if vim.tbl_contains(config.initfile_filetypes, filetype) then
        local debugger_type = initfile.get_debugger_type(filetype)
        initfile.update_breakpoints(debugger_type)

    elseif vim.tbl_contains(config.inline_filetypes, filetype) then
        inline.update_breakpoints()
    else
        vim.notify("Cannot update breakpoints for unregistered filetype '" .. filetype .. "'",
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

---@param user_lnum number
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

---@param user_lnum number
---@param user_condition string?
function M.toggle_breakpoint_conditional(user_lnum, user_condition)
    local lnum = user_lnum or vim.fn.line('.')
    local filetype = vim.bo.filetype

    if vim.tbl_contains(config.initfile_filetypes, filetype) then
        local debugger_type = initfile.get_debugger_type(filetype)
        initfile.toggle_breakpoint_conditional(debugger_type, lnum, user_condition)

    else
        vim.notify("No conditional breakpoint support for filetype: '" .. filetype .. "'",
                   vim.log.levels.WARN)
    end
end

---@param user_opts BrkOptions?
function M.setup(user_opts)
    config.setup(user_opts)

    -- Load breakpoints for each FileType event
    vim.api.nvim_create_autocmd("Filetype", {
        pattern = config.filetypes,
        callback = function (ev)
            M.load_breakpoints(ev.match)
        end
    })

    -- Update breakpoint locations whenever a file is updated
    vim.api.nvim_create_autocmd("BufWritePost", {
        pattern = {'*'},
        callback = function ()
            if vim.tbl_contains(config.filetypes, vim.bo.filetype) then
                M.update_breakpoints(vim.bo.filetype)
            end
        end
    })
end

return M
