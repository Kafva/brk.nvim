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

---@param debugger_type DebuggerType
---@param breakpoint Breakpoint
---@return string
local function breakpoint_tostring(debugger_type, breakpoint)
    if debugger_type == "gdb" then
        return "break " ..
                breakpoint.file .. ":" .. tostring(breakpoint.lnum) ..
               "\n"
    elseif debugger_type == "lldb" then
        return "breakpoint set" ..
               " --file " .. breakpoint.file ..
               " --line " .. tostring(breakpoint.lnum) ..
               "\n"
    elseif debugger_type == "delve" then
        local breakpoint_name = breakpoint.file:gsub('[^a-zA-Z0-9]', '') ..
                                               tostring(breakpoint.lnum)
        return "break " ..
               breakpoint_name .. " " ..
               breakpoint.file .. ":" .. tostring(breakpoint.lnum) ..
               "\n"
    else
        error("Unknown debugger type: " .. debugger_type)
    end
end

--- Update the breakpoints listed in the init file for the debugger
---@param debugger_type DebuggerType
local function write_breakpoints_to_file(debugger_type)
    local content = ""
    for _,breakpoint in pairs(breakpoints) do
        content = content .. breakpoint_tostring(debugger_type, breakpoint)
    end

    if #content > 0 and config.auto_start then
        if debugger_type == "delve" then
            content = content .. "continue\n"
        else
            content = content .. "run\n"
        end
    end

    -- Overwrite the lldb file with the new set of breakpoints
    util.writefile(config.initfile_paths[debugger_type], 'w', content)
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
---@param debugger_type DebuggerType
---@param initfile_linenr number
---@param line string
---@return Breakpoint|nil
local function breakpoint_from_line(debugger_type, initfile_linenr, line)
    local lnum, file
    if debugger_type == "gdb" then
        file = line:match("break ([^:]+):")
        if file == nil then
            return nil
        end
        lnum = line:match(":(%d+)")

    elseif debugger_type == "lldb" then
        file = line:match(" --file ([^ ]+)")
        if file == nil then
            return nil
        end
        lnum = line:match(" --line ([^ ]+)")

    elseif debugger_type == "delve" then
        -- TODO
        return nil
    else
        error("Unknown debugger file format: '" .. debugger_type .. "'")
        return
    end

    file = file:gsub('"', '')
    _, lnum = pcall(tonumber, lnum)
    if not lnum then
        vim.notify("Failed to parse line " ..
              tostring(initfile_linenr) .. " in " ..
              config.initfile_paths[debugger_type],
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

---@param debugger_type DebuggerType
function M.load_breakpoints(debugger_type)
    local initfile_path = config.initfile_paths[debugger_type]
    local ok, _ = uv.fs_access(initfile_path, 'r')
    if ok then
        local content = util.readfile(initfile_path)
        for i,line in pairs(vim.split(content, '\n')) do
            local breakpoint = breakpoint_from_line(debugger_type, i, line)
            if breakpoint then
                table.insert(breakpoints, breakpoint)
            end
        end
    else
        breakpoints = {}
    end

    reload_breakpoint_signs()
end

---@param debugger_type DebuggerType
function M.delete_all_breakpoints(debugger_type)
    vim.fn.sign_unplace('brk')
    breakpoints = {}

    write_breakpoints_to_file(debugger_type)
    reload_breakpoint_signs()
end

---@param debugger_type DebuggerType
---@param lnum number
function M.toggle_breakpoint(debugger_type, lnum)
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

    write_breakpoints_to_file(debugger_type)
end

return M
