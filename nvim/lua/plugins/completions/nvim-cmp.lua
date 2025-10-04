-- Define the plugin specification
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
        "saecki/Crates.nvim",
        "ray-x/cmp-treesitter",
        "hrsh7th/cmp-nvim-lsp-signature-help",
        "hrsh7th/cmp-nvim-lsp-document-symbol",
        "hrsh7th/cmp-nvim-lua"
    },
}

-- Function to get source names for completion menu
-- This allows for easy customization of how different sources are displayed
local function get_source_names()
    return {
        ["nvim_lsp:amazonq-completion"] = "(Q)",
        ["amazonq"] = "(Q)",
        ["nvim_lsp"] = "(LSP)",
        path = "(Path)",
        vsnip = "(Snippet)",
        luasnip = "(Snippet)",
        buffer = "(Buffer)",
        crates = "(Crates)",
        ["nvim_lua"] = "nvim_lua",
        ["cmp-nvim-lsp-document-symbol"] = "(Document)",
        nvim_lsp_signature_help = "(Snippet)",
        codeium = "(Codeium)",
        ["amazonq-completion"] = "(Q)"
    }
end

-- Function to handle scrolling in completion menu
-- This provides a unified way to scroll through completions and snippets
local function scroll(cmp, luasnip, direction)
    return function(fallback)
        if cmp.visible() then
            cmp[direction == 1 and "select_next_item" or "select_prev_item"]()
        elseif luasnip.expandable() then
            luasnip.expand()
        elseif luasnip.expand_or_jumpable() then
            luasnip[direction == 1 and "expand_or_jump" or "jump"](-1)
        else
            fallback()
        end
    end
end

-- Function to configure the formatting of completion items
-- This determines how items appear in the completion menu
local function get_formatting_config(icons)
    local source_names = get_source_names()
    return {
        fields = { "kind", "abbr", "menu" },
        format = function(entry, vim_item)
            -- Truncate long completion items
            local max_width = 50
            if max_width ~= 0 and #vim_item.abbr > max_width then
                vim_item.abbr = string.sub(vim_item.abbr, 1, max_width - 1) .. "…"
            end

            -- Set icons and menu text
            vim_item.kind = icons.kind[vim_item.kind]
            vim_item.menu = source_names[entry.source.name]
            -- Configure duplicate handling
            vim_item.dup = ({
                buffer = 0,
                path = 0,
                nvim_lsp = 1,
                luasnip = 1,
            })[entry.source.name] or 0
            return vim_item
        end,
    }
end

-- Function to define completion sources
-- This determines which sources are used for completion
local function get_sources()
    return {
        { name = "nvim_lsp" },
        { name = "crates" },
        { name = "path" },
        { name = "luasnip" },
        { name = "nvim_lua" },
        { name = "buffer" },
        { name = "treesitter" },
        { name = "nvim_lsp_signature_help" },
        { name = "nvim_lsp_document_symbol" },
        { name = "nvim_lsp:amazonq-completion" },
    }
end

-- Function to set up key mappings for completion
-- This defines how users can interact with the completion menu
local function get_mappings(cmp, luasnip)
    return {
        ["<C-d>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
        ["<Down>"] = cmp.mapping.select_next_item(),
        ["<Up>"] = cmp.mapping.select_prev_item(),
        ["<C-e>"] = cmp.mapping({
            i = cmp.mapping.abort(),
            c = cmp.mapping.close(),
        }),
        ['<C-y>'] = cmp.mapping.confirm({ select = true }),
        ["<C-Space>"] = cmp.mapping.complete(),
        ['<C-n>'] = cmp.mapping(scroll(cmp, luasnip, 1), { "i", "s", "c" }),
        ["<C-p>"] = cmp.mapping(scroll(cmp, luasnip, -1), { "i", "s", "c" }),
    }
end

-- Function to configure sorting of completion items
-- This determines the order in which completion items are presented
local function get_sorting_config(compare)
    return {
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
    }
end

-- Function to set up completion for search command line
-- This enables completion when searching with '/' or '?'
local function setup_search_cmdline(cmp)
    cmp.setup.cmdline({ "/", "?" }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
            { name = "buffer" },
        },
    })
end

-- Function to set up completion for Vim command line
-- This enables completion when entering Vim commands with ':'
local function setup_command_cmdline(cmp)
    cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
            { name = "path" },
        }, {
            { name = "cmdline" },
        }),
    })
end

-- Main configuration function
M.config = function()
    local ok, cmp = pcall(require, "cmp")
    if not ok then 
        vim.notify("Failed to load nvim-cmp", vim.log.levels.ERROR)
        return 
    end
    
    local luasnip_ok, luasnip = pcall(require, "luasnip")
    if not luasnip_ok then 
        vim.notify("Failed to load luasnip", vim.log.levels.ERROR)
        return 
    end
    
    local compare = require("cmp.config.compare")
    local icons = require("config.icons")

    -- Set up crates.nvim integration
    local crates_ok, crates_cmp = pcall(require, "crates.completion.cmp")
    if crates_ok then
        crates_cmp.setup()
    else
        vim.notify("Failed to load crates completion", vim.log.levels.WARN)
    end

    -- Main nvim-cmp setup
    cmp.setup({
        preselect = cmp.PreselectMode.None,
        formatting = get_formatting_config(icons),
        sorting = get_sorting_config(compare),
        snippet = {
            expand = function(args)
                luasnip.lsp_expand(args.body)
            end,
        },
        confirm_opts = {
            behavior = cmp.ConfirmBehavior.Replace,
            select = false,
        },
        duplicates_default = 1,
        completion = {
            keyword_length = 1,
        },
        experimental = {
            ghost_text = true,
            native_menu = false,
        },
        window = {
            completion = cmp.config.window.bordered(),
            documentation = cmp.config.window.bordered(),
        },
        sources = get_sources(),
        mapping = get_mappings(cmp, luasnip),
    })

    -- Set up command-line completion
    setup_search_cmdline(cmp)
    setup_command_cmdline(cmp)
end

return M
