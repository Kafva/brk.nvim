local util = require('util')
local config = require('config')

M = {}

---@param breakpoint Breakpoint
---@return string
local function breakpoint_tostring(breakpoint)
    return "breakpoint set " ..
           " --file " .. breakpoint.file ..
           " --line " .. tostring(breakpoint.lnum) ..
           "\n"
end

---@param breakpoints Breakpoint[]
function M.write_breakpoints(breakpoints)
    local content = ""
    for _,breakpoint in pairs(breakpoints) do
        content = content .. breakpoint_tostring(breakpoint)
    end

    -- Overwrite the lldb file with the new set of breakpoints
    util.writefile(config.lldb_file, 'w', content)
end


---@return Breakpoint[] @A table of Breakpoint objects
function M.read_breakpoints()
    local breakpoints = {}
    local content = util.readfile(config.lldb_file)
    for i,line in pairs(vim.split(content, '\n')) do
        local file = line:match(" --file ([^ ]+)")
        -- Skip all lines tht do not have a --file
        if file then
            file = file:gsub('"', '')
            local _, lnum = pcall(tonumber, line:match(" --line ([^ ]+)"))
            if not lnum then
                vim.notify("Failed to parse --line argument at line " ..
                      tostring(i) .. " in " .. config.lldb_file,
                      vim.log.levels.ERROR)
            else
                table.insert(breakpoints, { file = file, lnum = lnum })
            end
        end
    end

    return breakpoints
end


return M
