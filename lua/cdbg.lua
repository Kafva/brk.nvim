local util = require('util')
local config = require('config')
---@type uv
local uv = vim.uv

M = {}

---@param breakpoint Breakpoint
---@return string
local function breakpoint_tostring(breakpoint)
    if config.dbg_file_format == "gdb" then
        return "break " ..
                breakpoint.file .. ":" .. tostring(breakpoint.lnum) ..
               "\n"
    elseif config.dbg_file_format == "lldb" then
        return "breakpoint set " ..
               " --file " .. breakpoint.file ..
               " --line " .. tostring(breakpoint.lnum) ..
               "\n"
    else
        error("Unknown debugger format: " .. config.dbg_file_format)
    end
end

---@param breakpoints Breakpoint[]
function M.write_breakpoints(breakpoints)
    local content = ""
    for _,breakpoint in pairs(breakpoints) do
        content = content .. breakpoint_tostring(breakpoint)
    end

    -- Overwrite the lldb file with the new set of breakpoints
    util.writefile(config.dbg_file, 'w', content)
end

-- Returns nil if the line is not a breakpoint
---@return Breakpoint|nil
local function breakpoint_from_line(linenr, line)
    if config.dbg_file_format == "gdb" then
        local file = line:match("break ([^:]+):")
        if file == nil then
            return nil
        end
        local lnum = line:match(":(%d+)")
        return { file = file, lnum = lnum }

    elseif config.dbg_file_format == "lldb" then
        local file = line:match(" --file ([^ ]+)")
        if file == nil then
            return nil
        end

        file = file:gsub('"', '')
        local _, lnum = pcall(tonumber, line:match(" --line ([^ ]+)"))
        if not lnum then
            vim.notify("Failed to parse --line argument at line " ..
                  tostring(linenr) .. " in " .. config.dbg_file,
                  vim.log.levels.ERROR)
            return nil
        end

        return { file = file, lnum = lnum }
    else
        error("Unknown debugger file format: '" .. config.dbg_file_format .. "'")
    end
end

---@return Breakpoint[] Table of Breakpoint objects
function M.read_breakpoints()
    local breakpoints = {}

    local ok, _ = uv.fs_access(config.dbg_file, 'r')
    if not ok then
        return breakpoints
    end

    local content = util.readfile(config.dbg_file)
    for i,line in pairs(vim.split(content, '\n')) do
        local breakpoint = breakpoint_from_line(i, line)
        if breakpoint then
            table.insert(breakpoints, breakpoint)
        end
    end

    return breakpoints
end


return M
