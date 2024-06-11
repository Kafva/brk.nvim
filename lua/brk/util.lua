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

---@param lines table<string>
---@param ft string
---@param width number
---@param height number
---@return number
function M.open_popover(lines, ft, width, height)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    vim.api.nvim_open_win(buf, true, {
        relative = "cursor",
        row = 0,
        col = 0,
        height = height,
        width = width,
        style = "minimal"
    })
    vim.api.nvim_set_option_value('filetype', ft, { buf = buf })
    vim.keymap.set('n', 'q',     "<cmd>q<cr>", { silent = true, buffer = buf })
    vim.keymap.set('n', '<esc>', "<cmd>q<cr>", { silent = true, buffer = buf })
    return buf
end

-- Open the selected path in a buffer, using 'b' allows us to
-- switch to the buffer even if it is 'modified'.
---@param filepath string
function M.openfile(filepath)
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        local path = vim.api.nvim_buf_get_name(buf)
        if path == filepath then
            vim.cmd("b " .. filepath)
            return
        end
    end
    vim.cmd("e " .. filepath)
end

return M
