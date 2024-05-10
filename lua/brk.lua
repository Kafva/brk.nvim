local config = require 'config'
local lldb = require 'parsers.lldb'

local M = {}

---@type Breakpoint[]
local breakpoints = {}

local function reload_breakpoint_signs()
    local buf = vim.api.nvim_get_current_buf()

    -- Unplace all signs in the current buffer first
    vim.fn.sign_unplace('brk', {buffer = buf})

    for _,breakpoint in pairs(breakpoints) do
        local file = breakpoint.file
        local lnum = breakpoint.lnum
        if vim.fn.expand'%' == file then
            vim.notify("Placing sign at " .. file .. ":" .. tostring(lnum),
                       vim.log.levels.DEBUG)
            vim.fn.sign_place(0, "brk", "BrkBreakpoint", buf, {
                lnum = lnum,
                priority = config.breakpoint_sign_priority
            })
        end
    end
end

--- Update the breakpoints listed in the init file for the debugger
---@param filetype string|nil
local function write_breakpoints_to_file(filetype)
    local ft = filetype or vim.bo.filetype

    if ft == 'c' or
       ft == 'cpp' or
       ft == 'rust' or
       ft == 'objc' then
        lldb.write_breakpoints(breakpoints)

    elseif vim.tbl_contains(config.filetypes, ft) then
        vim.notify("Unsupported filetype '" .. ft .. "'", vim.log.levels.ERROR)
        return
    end

    reload_breakpoint_signs()
end

local function breakpoint_eq(b1, b2)
    return b1.file == b2.file and b1.lnum == b2.lnum
end

---@param predicate Breakpoint
---@return boolean
local function breakpoint_exists(predicate)
    for _, breakpoint in pairs(breakpoints) do
        if breakpoint_eq(breakpoint, predicate) then
            return true
        end
    end
    return false
end

function M.toggle_breakpoint()
    local buf = vim.api.nvim_get_current_buf()
    local lnum = vim.fn.line('.')

    ---@type table
    local bufsigns = vim.fn.sign_getplaced(buf, {group='brk', lnum = lnum})
    local breakpoint = {file = vim.fn.expand'%', lnum = lnum}

    if #bufsigns > 0 and #bufsigns[1].signs > 0 then
        if not breakpoint_exists(breakpoint) then
            vim.notify("Breakpoint not registered: " ..
                       breakpoint.file .. ":" .. tostring(breakpoint.lnum),
                       vim.log.levels.ERROR)
            return
        end

        -- Remove breakpoint sign at current line
        for _, sign in ipairs(bufsigns[1].signs) do
            vim.fn.sign_unplace('brk', {id = sign.id})
        end

        -- Remove breakpoint from breakpoints list
        breakpoints = vim.tbl_filter(function(b)
            return not breakpoint_eq(b, breakpoint)
        end, breakpoints)
    else
        if breakpoint_exists(breakpoint) then
            vim.notify("Breakpoint already registered: " ..
                       breakpoint.file .. ":" .. tostring(breakpoint.lnum),
                       vim.log.levels.ERROR)
            return
        end

        -- Add breakpoint sign at current line
        vim.fn.sign_place(0, "brk", "BrkBreakpoint", buf, {
            lnum = lnum,
            priority = config.breakpoint_sign_priority})

        -- Add breakpoint to breakpoints list
        table.insert(breakpoints, breakpoint)
    end

    write_breakpoints_to_file()
end

function M.delete_all_breakpoints()
    vim.fn.sign_unplace('brk')
    breakpoints = {}
    write_breakpoints_to_file()
end

---@param filetype string
function M.load_breakpoints(filetype)
    breakpoints = {}

    if filetype == 'c' or
       filetype == 'cpp' or
       filetype == 'rust' or
       filetype == 'objc' then
         breakpoints = lldb.read_breakpoints()

    elseif vim.tbl_contains(config.filetypes, filetype) then
        vim.notify("Unsupported filetype '" .. filetype .. "'", vim.log.levels.ERROR)
        return
    end

    reload_breakpoint_signs()
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
end

return M
