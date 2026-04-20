-- npm package name completion for package.json via blink.compat.
return {
    "David-Kunz/cmp-npm",
    dependencies = { "nvim-lua/plenary.nvim" },
    ft = { "json" },
    config = function()
        require("cmp-npm").setup({})
    end,
}
