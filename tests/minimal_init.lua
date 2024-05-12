vim.cmd([[set runtimepath+=.]])

vim.api.nvim_create_user_command("RunTests", function(opts)
    local path = opts.fargs[1] or "tests"
    vim.schedule(function()
        require("plenary.test_harness").test_directory(
            path,
            { init = "./tests/minimal_init.lua" }
        )
    end)
end, { nargs = "?" })
