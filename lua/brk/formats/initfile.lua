local util = require 'brk.util'
local config = require 'brk.config'
local popover = require 'brk.popover'

---@type uv
local uv = vim.uv

M = {}

---@type Breakpoint[]
local breakpoints = {}

-- Automatically save the current buffer before changing breakpoint placements
local function save_buffer()
    local ok, err = pcall(function() vim.cmd("silent write") end)
    if not ok then
        vim.notify("Error saving buffer: " .. tostring(err))
        return false
    end
    return true
end

-- A non-ambiguous filepath is needed for delve
-- gdb does not like leading './'
---@param debugger_type DebuggerType
---@param file string
local function get_filepath(debugger_type, file)
    if debugger_type == DebuggerType.DELVE then
        return (vim.startswith(file, "/") or
                vim.startswith(file, "./")) and file or "./" .. file
    else
        return file
    end
end

---@param debugger_type DebuggerType
---@param symbol string
---@return string
local function symbol_breakpoint_tostring(debugger_type, symbol)
    if debugger_type == DebuggerType.GDB then
        return "break " .. symbol .. "\n"
    elseif debugger_type == DebuggerType.LLDB then
        return "breakpoint set -n " .. symbol .. "\n"

    elseif debugger_type == DebuggerType.DELVE then
        return "break " .. symbol .. "\n"

    else
        error("Unknown debugger type: " .. debugger_type)
    end
end

---@param debugger_type DebuggerType
---@param breakpoint Breakpoint
---@return string
local function breakpoint_tostring(debugger_type, breakpoint)
    if breakpoint.symbol ~= nil then
        return symbol_breakpoint_tostring(debugger_type, breakpoint.symbol)
    end

    local filepath = get_filepath(debugger_type, breakpoint.file)

    if debugger_type == DebuggerType.GDB then
        local condition = breakpoint.condition ~= nil and
                            " if " .. breakpoint.condition or
                            ""
        return "break " ..
                filepath .. ":" .. tostring(breakpoint.lnum) ..
                condition ..
               "\n"
    elseif debugger_type == DebuggerType.LLDB then
        local condition = breakpoint.condition ~= nil and
                            " --condition '" .. breakpoint.condition .. "'" or
                            ""

        return "breakpoint set" ..
               " --file " .. filepath ..
               " --line " .. tostring(breakpoint.lnum) ..
               condition ..
               "\n"
    elseif debugger_type == DebuggerType.DELVE then
        local breakpoint_name = breakpoint.file:gsub('[^a-zA-Z0-9]', '') ..
                                               tostring(breakpoint.lnum)
        local condition = breakpoint.condition ~= nil and
                            "cond " .. breakpoint_name .. " " ..
                            breakpoint.condition .. "\n" or
                            ""
        return "break " ..
               breakpoint_name .. " " ..
               filepath .. ":" .. tostring(breakpoint.lnum) ..
               "\n" ..
               condition

    else
        error("Unknown debugger type: " .. debugger_type)
    end
end

--- Update the breakpoints listed in the init file for the debugger
---@param debugger_type DebuggerType
local function write_breakpoints_to_file(debugger_type)
    local initfile_path = config.initfile_paths[debugger_type]
    local content = ""
    for _,breakpoint in pairs(breakpoints) do
        content = content .. breakpoint_tostring(debugger_type, breakpoint)
    end

    local ok, _ = uv.fs_access(initfile_path, 'r')

    if #content == 0 and not ok then
        -- Do not create an empty init file unless an initfile already exists
        return
    end

    if #content > 0 and config.auto_start then
        if debugger_type == "delve" then
            content = content .. "continue\n"
        else
            content = content .. "run\n"
        end
    end

    -- Overwrite the lldb file with the new set of breakpoints
    util.writefile(initfile_path, 'w', content)
end

---@param debugger_type DebuggerType
local function reload_breakpoint_signs(debugger_type)
    local buf = vim.api.nvim_get_current_buf()

    -- Unplace all signs in the current buffer first
    vim.fn.sign_unplace('brk', {buffer = buf})

    for _,breakpoint in pairs(breakpoints) do
        if breakpoint.file == nil then
            goto continue
        end
        local file = breakpoint.file
        local lnum = breakpoint.lnum
        ---@diagnostic disable-next-line: param-type-mismatch
        if get_filepath(debugger_type, vim.fn.expand'%') == file then
            local sign_name = breakpoint.condition ~= nil and
                                "BrkConditionalBreakpoint" or
                                "BrkBreakpoint"
            vim.notify("Placing sign at " .. file .. ":" .. tostring(lnum),
                       vim.log.levels.TRACE)
            vim.fn.sign_place(0, "brk", sign_name, buf, {
                lnum = lnum,
                priority = config.breakpoint_sign_priority
            })
        end
        ::continue::
    end
end

--- XXX Does not consider the 'name' or the 'condition' field.
--- This makes conditional and regular breakpoints on the same line equal.
---@param b1 Breakpoint
---@param b2 Breakpoint
local function breakpoint_eq(b1, b2)
    return b1.file == b2.file and
           b1.lnum == b2.lnum and
           b1.symbol == b2.symbol
end

---@param predicate Breakpoint
---@return Breakpoint?
local function find_breakpoint(predicate)
    for _, breakpoint in pairs(breakpoints) do
        if breakpoint_eq(breakpoint, predicate) then
            return breakpoint
        end
    end
    return nil
end

-- Returns nil if the line is not a breakpoint
---@param debugger_type DebuggerType
---@param initfile_linenr number
---@param line string
---@return Breakpoint|nil
local function breakpoint_from_line(debugger_type, initfile_linenr, line)
    local lnum, file, name, symbol, condition
    if debugger_type == "gdb" then
        file = line:match("break%s+([^:]+):")
        if file == nil then
            -- Parse as a symbol breakpoint
            symbol = line:match("break%s+([^:]+)")
            if symbol == nil then
                return nil
            end
        end
        lnum = line:match(":(%d+)")
        condition = line:match(" if (.+)")

    elseif debugger_type == "lldb" then
        file = line:match(" --file ([^ ]+)")
        if file == nil then
            -- Parse as a symbol breakpoint
            symbol = line:match(" -n ([^ ]+)")
            if symbol == nil then
                return nil
            end
        end
        lnum = line:match(" --line ([^ ]+)")
        condition = line:match(" --condition (.+)")

    elseif debugger_type == "delve" then
        file = line:match("break%s+[a-zA-Z0-9]+%s+([^:]+):")
        name = line:match("break%s+([a-zA-Z0-9]+)")

        if file == nil then
            -- Parse as a symbol breakpoint
            symbol = line:match("break%s+([a-zA-Z0-9]+)")
            if symbol == nil then
                -- Parse as a conditional line
                name = line:match("cond%s+([a-zA-Z0-9]+)")
                condition = line:match("cond%s+[a-zA-Z0-9]+%s+(.*)")
                if name == nil then
                    return nil
                end
            end
        else
            -- Parse as a line based breakpoint
            lnum = line:match(":(%d+)")
        end

    else
        error("Unknown debugger file format: '" .. debugger_type .. "'")
        return
    end

    if file then
        file = file:gsub('"', '')
    end

    if lnum then
        _, lnum = pcall(tonumber, lnum)
        if not lnum then
            vim.notify("Failed to parse line " ..
                  tostring(initfile_linenr) .. " in " ..
                  config.initfile_paths[debugger_type],
                  vim.log.levels.ERROR)
            return nil
        end
    end

    return { file = file,
             lnum = lnum,
             name = name,
             symbol = symbol,
             condition = condition }
end

-- Delve breakpoints are parsed from two lines.
-- Combine all breakpoints that exist with the same name into one,
-- one of them has the lnum, the other has the conditional.
local function combine_delve_breakpoints()
    local combined_breakpoints = {}
    for _,breakpoint in pairs(breakpoints) do
        if breakpoint == nil or breakpoint.name == nil then
            goto continue
        end
        local old_value = combined_breakpoints[breakpoint.name]
        if old_value ~= nil then
            combined_breakpoints[breakpoint.name].lnum = old_value.lnum or breakpoint.lnum
            combined_breakpoints[breakpoint.name].condition = old_value.condition or breakpoint.condition
        else
            combined_breakpoints[breakpoint.name] = breakpoint
        end
        ::continue::
    end
    breakpoints = {}
    for _,v in pairs(combined_breakpoints) do
        table.insert(breakpoints, v)
    end
end

---@param breakpoint Breakpoint
local function add_breakpoint(breakpoint)
    if find_breakpoint(breakpoint) ~= nil then
        vim.notify("Breakpoint already registered: " ..
                   breakpoint.file .. ":" .. tostring(breakpoint.lnum),
                   vim.log.levels.ERROR)
        return
    end

    if breakpoint.file ~= nil then
        -- Add breakpoint sign at current line
        local sign_name = breakpoint.condition ~= nil and
                            "BrkConditionalBreakpoint" or
                            "BrkBreakpoint"
        local buf = vim.api.nvim_get_current_buf()
        vim.fn.sign_place(0, "brk", sign_name, buf, {
            lnum = breakpoint.lnum,
            priority = config.breakpoint_sign_priority})
    end

    -- Add breakpoint to breakpoints list
    table.insert(breakpoints, breakpoint)
end

---@param breakpoint Breakpoint
---@param bufsigns? table
local function delete_breakpoint(breakpoint, bufsigns)
    if find_breakpoint(breakpoint) == nil then
        vim.notify("Breakpoint not registered: " ..
                   breakpoint.file .. ":" .. tostring(breakpoint.lnum),
                   vim.log.levels.ERROR)
        return
    end

    if bufsigns ~= nil then
        -- Remove breakpoint sign at current line
        for _, sign in ipairs(bufsigns[1].signs) do
            vim.fn.sign_unplace('brk', {id = sign.id})
        end
    end

    -- Remove breakpoint from breakpoints list
    breakpoints = vim.tbl_filter(function(b)
        return not breakpoint_eq(b, breakpoint)
    end, breakpoints)
end

---@param filetype string
---@return DebuggerType
function M.get_debugger_type(filetype)
    if filetype == 'go' then
        return DebuggerType.DELVE
    end

    for debugger_type,initfile_path in pairs(config.initfile_paths) do
        if vim.fn.filereadable(initfile_path) == 1 then
            return debugger_type
        end
    end

    return config.preferred_debugger_format
end

---@param debugger_type DebuggerType
function M.load_breakpoints(debugger_type)
    local initfile_path = config.initfile_paths[debugger_type]
    local ok, _ = uv.fs_access(initfile_path, 'r')
    -- Always reset before reloading
    breakpoints = {}

    if ok then
        local content = util.readfile(initfile_path)
        for i,line in pairs(vim.split(content, '\n')) do
            local breakpoint = breakpoint_from_line(debugger_type, i, line)
            if breakpoint then
                table.insert(breakpoints, breakpoint)
            end
        end
    end

    if debugger_type == DebuggerType.DELVE then
        combine_delve_breakpoints()
    end

    reload_breakpoint_signs(debugger_type)
end

---@param debugger_type DebuggerType
function M.update_breakpoints(debugger_type)
    local buf = vim.api.nvim_get_current_buf()
    ---@diagnostic disable-next-line: param-type-mismatch
    local file = get_filepath(debugger_type, vim.fn.expand'%')

    -- Determine where signs are currently placed
    local bufsigns = vim.fn.sign_getplaced(buf, { group = 'brk' })

    if #bufsigns == 0 then
        return
    end

    -- Filter out all breakpoints for the current file
    breakpoints = vim.tbl_filter(function (b)
        return file ~= b.file
    end, breakpoints)

    -- Reinsert breakpoints to match sign positions (which may have changed)
    for _,sign in pairs(bufsigns[1].signs) do
        local breakpoint = { file = file, lnum = sign.lnum }
        table.insert(breakpoints, breakpoint)
    end

    write_breakpoints_to_file(debugger_type)
    reload_breakpoint_signs(debugger_type)
end

---@param debugger_type DebuggerType
function M.delete_all_breakpoints(debugger_type)
    vim.fn.sign_unplace('brk')
    breakpoints = {}

    write_breakpoints_to_file(debugger_type)
    reload_breakpoint_signs(debugger_type)
end

---@param debugger_type DebuggerType
---@param lnum number
function M.toggle_breakpoint(debugger_type, lnum)
    if not save_buffer() then
        return
    end
    local buf = vim.api.nvim_get_current_buf()
    ---@type table
    local bufsigns = vim.fn.sign_getplaced(buf, {group='brk',
                                                 lnum = tostring(lnum)})
    local breakpoint = {
        ---@diagnostic disable-next-line: param-type-mismatch
        file = get_filepath(debugger_type, vim.fn.expand'%'),
        lnum = lnum
    }

    if #bufsigns > 0 and #bufsigns[1].signs > 0 then
        -- Breakpoint already exists
        delete_breakpoint(breakpoint, bufsigns)
    else
        -- Breakpoint does not exist yet
        add_breakpoint(breakpoint)
    end

    write_breakpoints_to_file(debugger_type)
end

---@param debugger_type DebuggerType
---@param lnum number
---@param user_condition string?
function M.toggle_conditional_breakpoint(debugger_type, lnum, user_condition)
    if not save_buffer() then
        return
    end
    local breakpoint = {
        ---@diagnostic disable-next-line: param-type-mismatch
        file = get_filepath(debugger_type, vim.fn.expand'%'),
        lnum = lnum
    }

    local current_breakpoint = find_breakpoint(breakpoint)
    local current_condition = current_breakpoint and current_breakpoint.condition or ''
    local condition = user_condition or vim.fn.input('Conditional: ', current_condition)
    local buf = vim.api.nvim_get_current_buf()
    local bufsigns = vim.fn.sign_getplaced(buf, {group='brk',
                                                 lnum = tostring(lnum)})

    if current_breakpoint and (condition == nil or #condition == 0) then
        -- Delete the conditional if everything from the prompt was removed
        delete_breakpoint(breakpoint, bufsigns)

    elseif condition == current_condition then
        -- No input, nothing to do
        return
    else
        if current_breakpoint ~= nil then
            delete_breakpoint(current_breakpoint, bufsigns)
        end

        breakpoint.condition = condition
        add_breakpoint(breakpoint)
    end

    write_breakpoints_to_file(debugger_type)
end

---@param debugger_type DebuggerType
---@param user_symbol string?
function M.toggle_symbol_breakpoint(debugger_type, user_symbol)
    if not save_buffer() then
        return
    end
    local symbol = user_symbol or vim.fn.input('Toggle symbol breakpoint: ')
    local breakpoint = { symbol = symbol }

    if symbol == nil or #symbol == 0 then
        return
    elseif find_breakpoint(breakpoint) ~= nil then
        delete_breakpoint(breakpoint)
        vim.notify("Symbol breakpoint deleted: '" .. symbol .. "'", vim.log.levels.INFO)
    else
        add_breakpoint(breakpoint)
        vim.notify("Symbol breakpoint added: '" .. symbol .. "'", vim.log.levels.INFO)
    end

    write_breakpoints_to_file(debugger_type)
end

function M.list_breakpoints()
    local initfile = require('brk.formats.initfile')
    local header = "  " .. initfile.get_debugger_type(vim.bo.filetype) ..  "\n"
    popover.open_breakpoints_popover(breakpoints, header)
end

return M
