local config = require 'config'

---@type uv
local uv = vim.uv

M = {}

---@param filepath string
---@return string
function M.readfile(filepath)
    local content
    local fd, err
    fd, err = uv.fs_open(filepath, 'r', 438)

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

-- TODO
function M.script_breakpoint_insert(filetype)
    local line = vim.fn.line('.')
    local cmdstr = config.script_cmds[filetype]
    vim.api.nvim_buf_set_lines(0, line, line, false, {cmdstr})
end

function M.script_breakpoint_delete(filetype)
    local bufnr = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local new_lines = {}
    local cmdstr = config.script_cmds[filetype]
    if cmdstr == nil then
        vim.notify('No breakpoints configured for filetype ' .. filetype,
                    vim.log.levels.WARN)
        return
    end

    for _, line in ipairs(lines) do
        if not line:find(cmdstr) then
            table.insert(new_lines, line)
        end
    end

    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)
end

return M
