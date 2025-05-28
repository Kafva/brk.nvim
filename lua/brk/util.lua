---@type uv
local uv = vim.uv

local M = {}

-- Open the selected path in a buffer, using 'b' allows us to
-- switch to the buffer even if it is 'modified'.
---@param filepath string
function M.openfile(filepath)
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        local path = vim.api.nvim_buf_get_name(buf)
        -- The `filepath` can be a relative path, if the
        -- absolute `path` ends with the entirety of the provided
        -- `filepath` we have a match.
        if vim.endswith(path, filepath) then
            vim.cmd('b ' .. filepath)
            return
        end
    end
    vim.cmd('e ' .. filepath)
end

---@param filepath string
---@return string
function M.readfile(filepath)
    local content
    local fd, err
    fd, err = uv.fs_open(filepath, 'r', 438)

    if not fd then
        vim.notify(err or ('Failed to open ' .. filepath), vim.log.levels.ERROR)
        return ''
    end

    content, err = uv.fs_read(fd, 1024 * 1024)

    if not content then
        vim.notify(err or ('Failed to read ' .. filepath), vim.log.levels.ERROR)
        return ''
    end

    _, err = uv.fs_close(fd)
    if err then
        vim.notify(err, vim.log.levels.ERROR)
        return ''
    end

    return content
end

---@param filepath string
---@param content string
function M.writefile(filepath, mode, content)
    local fd, err
    fd, err = uv.fs_open(filepath, mode, 438)
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
