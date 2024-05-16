local util = require('util')
local config = require('config')
---@type uv
local uv = vim.uv

---@class Breakpoint
---@field file string
---@field lnum number

M = {}

---@type Breakpoint[]
local breakpoints = {}

---@param initfile_format DebuggerType
---@param breakpoint Breakpoint
---@return string
local function breakpoint_tostring(initfile_format, breakpoint)
    if initfile_format == "gdb" then
        return "break " ..
                breakpoint.file .. ":" .. tostring(breakpoint.lnum) ..
               "\n"
    elseif initfile_format == "lldb" then
        return "breakpoint set" ..
               " --file " .. breakpoint.file ..
               " --line " .. tostring(breakpoint.lnum) ..
               "\n"
    else
        error("Unknown debugger format: " .. initfile_format)
    end
end

--- Update the breakpoints listed in the init file for the debugger
---@param initfile_format DebuggerType
local function write_breakpoints_to_file(initfile_format)
    local content = ""
    for _,breakpoint in pairs(breakpoints) do
        content = content .. breakpoint_tostring(initfile_format, breakpoint)
    end

    if #content > 0 and config.auto_start then
        content = content .. "run\n"
    end

    -- Overwrite the lldb file with the new set of breakpoints
    util.writefile(config.initfile_paths[initfile_format], 'w', content)
end

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

---@param b1 Breakpoint
---@param b2 Breakpoint
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

-- Returns nil if the line is not a breakpoint
---@param initfile_format DebuggerType
---@param initfile_linenr number
---@param line string
---@return Breakpoint|nil
local function breakpoint_from_line(initfile_format, initfile_linenr, line)
    local lnum, file
    if initfile_format == "gdb" then
        file = line:match("break ([^:]+):")
        if file == nil then
            return nil
        end
        lnum = line:match(":(%d+)")

    elseif initfile_format == "lldb" then
        file = line:match(" --file ([^ ]+)")
        if file == nil then
            return nil
        end
        lnum = line:match(" --line ([^ ]+)")
    else
        error("Unknown debugger file format: '" .. initfile_format .. "'")
        return
    end

    file = file:gsub('"', '')
    _, lnum = pcall(tonumber, lnum)
    if not lnum then
        vim.notify("Failed to parse line " ..
              tostring(initfile_linenr) .. " in " ..
              config.initfile_paths[initfile_format],
              vim.log.levels.ERROR)
        return nil
    end

    return { file = file, lnum = lnum }
end

---@param filetype string
---@return DebuggerType
function M.get_debugger_type(filetype)
    if filetype == 'go' then
        return DebuggerType.DELVE
    end

    for debugger_type,initfile_path in pairs(config.initfile_paths) do
        if vim.fn.filereadable(initfile_path) == 1 then
            return debugger_type
        end
    end

    return config.preferred_debugger_format
end

---@param initfile_format DebuggerType
function M.load_breakpoints(initfile_format)
    local initfile_path = config.initfile_paths[initfile_format]
    local ok, _ = uv.fs_access(initfile_path, 'r')
    if not ok then
        return
    end

    local content = util.readfile(initfile_path)
    for i,line in pairs(vim.split(content, '\n')) do
        local breakpoint = breakpoint_from_line(initfile_format, i, line)
        if breakpoint then
            table.insert(breakpoints, breakpoint)
        end
    end

    reload_breakpoint_signs()
end

---@param initfile_format DebuggerType
function M.delete_all_breakpoints(initfile_format)
    vim.fn.sign_unplace('brk')
    breakpoints = {}

    write_breakpoints_to_file(initfile_format)
    reload_breakpoint_signs()
end

---@param initfile_format DebuggerType
---@param lnum number
function M.toggle_breakpoint(initfile_format, lnum)
    local buf = vim.api.nvim_get_current_buf()
    ---@type table
    local bufsigns = vim.fn.sign_getplaced(buf, {group='brk',
                                                 lnum = tostring(lnum)})
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

    write_breakpoints_to_file(initfile_format)
end

return M
