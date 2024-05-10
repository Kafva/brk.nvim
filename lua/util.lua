---@type uv
local uv = vim.uv

M = {}

---@param filepath string
---@return string
function M.readfile(filepath)
    local content
    local fd, err
    fd, err = uv.fs_open(filepath, 'r', 0022)

    if not fd then
        vim.notify(err or ('Failed to open ' .. filepath), vim.log.levels.ERROR)
        return ""
    end

    content, err = uv.fs_read(fd, 8192)

    if not content then
        vim.notify(err or ('Failed to read ' .. filepath), vim.log.levels.ERROR)
        return ""
    end

    _, err = uv.fs_close(fd)
    if err then
        vim.notify(err, vim.log.levels.ERROR)
        return ""
    end

    return content
end

---@param filepath string
---@param content string
function M.writefile(filepath, mode, content)
    local fd, err
    fd, err = uv.fs_open(filepath, mode, 0022)
    if not fd then
        vim.notify(err or ('Failed to open ' .. filepath), vim.log.levels.ERROR)
        return
    end

    _, err = uv.fs_write(fd, content)

    if err then
        vim.notify(err, vim.log.levels.ERROR)
        return
    end

    _, err = uv.fs_close(fd)
    if err then
        vim.notify(err, vim.log.levels.ERROR)
        return
    end
end

return M
