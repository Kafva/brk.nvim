local util = require('util')
local config = require('config')
---@type uv
local uv = vim.uv


M = {}

---@param file string
---@param line number
function M.write_breakpoints(file, line)
    local content = "breakpoint set " ..
                            " --file " .. file ..
                            " --line " .. tostring(line) ..
                            "\n"
    util.writefile(config.lldb_file, content)
end

function M.read_breakpoints()
end


return M
