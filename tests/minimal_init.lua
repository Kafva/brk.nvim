vim.api.nvim_create_user_command("RunTests", function(opts)
    local target = opts.fargs[1]
    vim.schedule(function()
        -- Tests are ran from 'brk.nvim/tests/.env'
        local harness = require('plenary.test_harness')
        if vim.fn.isdirectory(target) == 1 then
            harness.test_directory(target)
        elseif vim.fn.filereadable(target) == 1 then
            harness.test_file(target)
        else
            error("Invalid path to tests")
        end
    end)
end, { nargs = 1 })
