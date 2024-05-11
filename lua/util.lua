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

function M.script_breakpoint_insert(filetype)
    local line = vim.fn.line('.')
    vim.api.nvim_buf_set_lines(0, line, line, false, {M.script_breakpoint(filetype)})
end

function M.script_breakpoint_delete(filetype)
    local bufnr = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local new_lines = {}
    local breakpoint = M.script_breakpoint(filetype)
    if breakpoint == nil then
        vim.notify('No breakpoints configured for filetype ' .. filetype,
                    vim.log.levels.WARN)
        return
    end

    for _, line in ipairs(lines) do
        if not line:find(breakpoint) then
            table.insert(new_lines, line)
        end
    end

    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)
end

---@param filetype string
---@return string|nil
function M.script_breakpoint(filetype)
    if filetype == 'lua' then
        return 'require"debugger"() -- Set DBG_REMOTEPORT=8777 for remote debugging'
    elseif filetype == 'python' then
        return "__import__('pdb').set_trace()"
    elseif filetype == 'ruby' then
        return 'require "debug"; debugger"'
    end
    return nil
end

return M
