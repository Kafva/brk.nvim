M = {}

local util = require 'brk.util'

---@param lines table<string>
---@param ft string
---@param width number
---@param height number
---@return number
local function open_popover(lines, ft, width, height)
    local goto_breakpoint = require('brk.popover').goto_breakpoint
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
    vim.api.nvim_set_option_value('modifiable', false, { buf = buf })
    vim.api.nvim_set_option_value('filetype', ft, { buf = buf })
    vim.keymap.set('n', 'q',     "<cmd>q<cr>", { silent = true, buffer = buf })
    vim.keymap.set('n', '<esc>', "<cmd>q<cr>", { silent = true, buffer = buf })
    vim.keymap.set('n', '<enter>', goto_breakpoint, { silent = true, buffer = buf })

    return buf
end

function M.goto_breakpoint()
    local line = vim.api.nvim_get_current_line()
    local splits = vim.split(line, ' ', {trimempty = true})
    if #splits < 2 then
        vim.notify("No location under cursor", vim.log.levels.WARN)
        return
    end
    local sign = vim.trim(splits[1])
    if sign ~= '[X]' and sign ~= '[C]' then
        vim.notify("Cannot jump to " .. sign .. " breakpoint", vim.log.levels.WARN)
        return
    end
    local bufpath = vim.split(splits[2], ':')[1]
    local linenr = vim.split(splits[2], ':')[2]

    if bufpath == nil or linenr == nil then
        vim.notify("No location under cursor", vim.log.levels.WARN)
        return
    end

    -- Quit out of the popover and move to the selected location
    vim.cmd("q")

    util.openfile(bufpath)
    vim.cmd(tostring(linenr))
end

---@param breakpoints Breakpoint[]
---@param header string
function M.open_breakpoints_popover(breakpoints, header)
    local content = header
    if #breakpoints == 0 then
        content = content .. "  No breakpoints registered"
    else
        -- Sorted by breakpoint type
        for _,b in pairs(breakpoints) do
            if b.condition == nil and b.file ~= nil then
                local location = b.file .. ":" .. tostring(b.lnum)
                content = content ..  "  [X] " .. location .. "\n"
            end
        end
        for _,b in pairs(breakpoints) do
            if b.condition ~= nil then
                local location = b.file .. ":" .. tostring(b.lnum)
                content = content .. "  [C] " .. location .. " " .. b.condition .. "\n"
            end
        end
        for _,b in pairs(breakpoints) do
            if b.symbol ~= nil then
                content = content .. "  [S] " .. b.symbol .. "\n"
            end
        end
    end

    local lines = vim.split(content, '\n')
    local popover_buf = open_popover(lines, 'lua', 60, 30)
end

return M
