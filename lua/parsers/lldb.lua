local util = require('util')
local config = require('config')

M = {}

---@param file string
---@param line number
function M.write_breakpoints(file, line)
    local content = "breakpoint set " ..
                            " --file " .. file ..
                            " --line " .. tostring(line) ..
                            "\n"
    util.writefile(config.lldb_file, 'a', content)
end


---@return Breakpoint[] @A table of Breakpoint objects
function M.read_breakpoints()
    local breakpoints = {}
    local content = util.readfile(config.lldb_file)
    for i,line in pairs(vim.split(content, '\n')) do
        local file = (line:match(" --file ([^ ]+)") or ""):gsub('"', '')
        -- Skip all lines tht do not have a --file
        if file then
            local _, lnum = pcall(tonumber, line:match(" --line ([^ ]+)"))
            if not lnum then
                error("Failed to parse breakpoint line number at " ..
                      tostring(i) .. " in " .. config.lldb_file)
            end
            table.insert(breakpoints, { file = file, lnum = lnum })
        end
    end

    return breakpoints
end


return M
