M = {}

---@param filepath string
---@return string
function M.readfile(filepath)
    local f = io.open(filepath, 'r')

    if not f then
        return ""
    end

    local content = f:read("*a")

    f:close()
    return content
end

---@param filepath string
---@param content string
---@return boolean
function M.writefile(filepath, content)
    local f = io.open(filepath, 'w')

    if not f then
        return false
    end

    local _, error_message = f:write(content)
    if error_message ~= nil then
        vim.notify("Failed to write to file: " .. error_message, vim.log.levels.ERROR)
    end

    f:close()
    return error_message ~= nil
end


return M
