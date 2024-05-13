
local M = {}

---@type uv
local uv = vim.uv

function M.rm_f(filepath)
    local _, err, errno = uv.fs_unlink(filepath)
    if errno ~= nil and errno ~= "ENOENT" then
        error(err)
    end
end

---@param group string
---@param lnum number
---@return boolean
function M.sign_exists(group, lnum)
    local buf = vim.api.nvim_get_current_buf()
    local bufsigns = vim.fn.sign_getplaced(buf, { group = group, lnum = tostring(lnum) })
    return #bufsigns > 0 and #bufsigns[1].signs > 0
end

return M
