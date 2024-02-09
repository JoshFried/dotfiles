return {
    -- real nice way to navigate common files that i hop between but seem to use telescope more tbh
    {
        "theprimeagen/harpoon",
        branch = "harpoon2",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            require("harpoon"):setup()
        end,
        keys = {
            { "<leader>af", function() require("harpoon"):list():append() end,  desc = "harpoon file", },
            {
                "<leader>ff",
                function()
                    local harpoon = require("harpoon")
                    harpoon.ui:toggle_quick_menu(harpoon:list())
                end,
                desc = "harpoon quick menu",
            },
            { "<leader>fn", function() require("harpoon"):list():next() end,    desc = "Harpoon next buffer" },
            { "<leader>fp", function() require("harpoon"):list():prev() end,    desc = "Harpoon prev buffer" },
            { "<leader>f1", function() require("harpoon"):list():select(1) end, desc = "harpoon to file 1", },
            { "<leader>f2", function() require("harpoon"):list():select(2) end, desc = "harpoon to file 2", },
            { "<leader>f3", function() require("harpoon"):list():select(3) end, desc = "harpoon to file 3", },
            { "<leader>f4", function() require("harpoon"):list():select(4) end, desc = "harpoon to file 4", },
            { "<leader>f5", function() require("harpoon"):list():select(5) end, desc = "harpoon to file 5", },
        },
    },
}
