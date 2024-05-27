local M = {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
        "hrsh7th/cmp-nvim-lsp",
        "saadparwaiz1/cmp_luasnip",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "hrsh7th/cmp-cmdline",
        "hrsh7th/vim-vsnip",
        "hrsh7th/cmp-nvim-lsp-signature-help",
        "hrsh7th/cmp-nvim-lsp-document-symbol",
        "saecki/Crates.nvim",
        "kristijanhusak/vim-dadbod-completion",
    },
}

M.config = function()
    local cmp = require("cmp")

    local luasnip = require("luasnip")
    local icons = require("config.icons")

    local source_names = {
        nvim_lsp = "(LSP)",
        path = "(Path)",
        vsnip = "(Snippet)",
        luasnip = "(Snippet)",
        buffer = "(Buffer)",
        crates = "(Crates)",
        ["vim-dadbod-completion"] = "(DB)",
        nvim_lsp_signature_help = "(Snippet)",
        ["cmp-nvim-lsp-document-symbol"] = "(Document)",
        codeium = "(Codeium)"
    }


    local scroll_up = function(fallback)
        if cmp.visible() then
            cmp.select_prev_item()
        elseif luasnip.jumpable(-1) then
            luasnip.jump(-1)
        else
            fallback()
        end
    end

    local scroll_down = function(fallback)
        if cmp.visible() then
            cmp.select_next_item()
        elseif luasnip.expandable() then
            luasnip.expand()
        elseif luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
        else
            fallback()
        end
    end

    local duplicates = {
        buffer = 0,
        path = 0,
        nvim_lsp = 1,
        luasnip = 1,
    }

    local compare = require("cmp.config.compare")
    cmp.setup({
        preselect = cmp.PreselectMode.None,
        formatting = {
            fields = { "kind", "abbr", "menu" },
            format = function(entry, vim_item)
                local max_width = 50
                if max_width ~= 0 and #vim_item.abbr > max_width then
                    vim_item.abbr = string.sub(vim_item.abbr, 1, max_width - 1) .. "…"
                end

                vim_item.kind = icons.kind[vim_item.kind]
                vim_item.menu = source_names[entry.source.name]
                vim_item.dup = duplicates[entry.source.name] or 0
                return vim_item
            end,
        },
        sorting = {
            priority_weight = 2,
            comparators = {
                compare.score,
                compare.recently_used,
                compare.offset,
                compare.exact,
                compare.kind,
                compare.sort_text,
                compare.length,
                compare.order,
            },
        },
        snippet = {
            expand = function(args)
                luasnip.lsp_expand(args.body)
            end,
        },
        confirm_opts = {
            behavior = cmp.ConfirmBehavior.Replace,
            select = false,
        },
        duplicates_default = 0,
        completion = {
            ---@usage The minimum length of a word to complete on.
            keyword_length = 1,
        },
        experimental = {
            ghost_text = true, -- NOTE: This is temporarily broken seems like a bug with nvim 0.9 and nvim-cmp..
            native_menu = false,
        },
        window = {
            completion = cmp.config.window.bordered(),
            documentation = cmp.config.window.bordered(),
        },
        sources = {
            { name = "nvim_lsp" },
            { name = "crates" },
            { name = "vim-dadbod-completion" },
            { name = "path" },
            { name = "luasnip" },
            { name = "nvim_lua" },
            { name = "buffer" },
            { name = "treesitter" },
            { name = "nvim_lsp_signature_help" },
            { name = "nvim_lsp_document_symbol" },
            { name = "codeium" }
        },
        mapping = {
            ["<C-d>"] = cmp.mapping.scroll_docs(-4),
            ["<C-f>"] = cmp.mapping.scroll_docs(4),
            ["<Down>"] = cmp.mapping.select_next_item(),
            ["<Up>"] = cmp.mapping.select_prev_item(),
            -- ["<C-Space>"] = cmp.mapping(cmp.mapping.complete(), { "i", "c" }),
            -- ["<C-y>"] = cmp.config.disable,
            ["<C-e>"] = cmp.mapping({
                i = cmp.mapping.abort(),
                c = cmp.mapping.close(),
            }),

            -- ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
            -- ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
            ['<C-y>'] = cmp.mapping.confirm({ select = true }),
            ["<C-Space>"] = cmp.mapping.complete(),
            -- ["<CR>"] = cmp.mapping.confirm({ select = true }),
            ['<C-n>'] = cmp.mapping(scroll_down, {
                "i",
                "s",
                "c",
            }),
            ["<C-p>"] = cmp.mapping(scroll_up, {
                "i",
                "s",
                "c",
            }),
        },
    })

    -- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
    cmp.setup.cmdline({ "/", "?" }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
            { name = "buffer" },
        },
    })

    -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
    cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
            { name = "path" },
        }, {
            { name = "cmdline" },
        }),
    })
end

return M
