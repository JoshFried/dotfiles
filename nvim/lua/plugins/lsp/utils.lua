local M = {}

local FORMATTING = require("null-ls").methods.FORMATTING
local DIAGNOSTICS = require("null-ls").methods.DIAGNOSTICS
local COMPLETION = require("null-ls").methods.COMPLETION
local CODE_ACTION = require("null-ls").methods.CODE_ACTION
local HOVER = require("null-ls").methods.HOVER
local autocmd_clear = vim.api.nvim_clear_autocmds

local augroup_highlight = vim.api.nvim_create_augroup("custom-lsp-references", {
	clear = true,
})

local function list_registered_providers_names(ft)
	local s = require("null-ls.sources")
	local available_sources = s.get_available(ft)
	local registered = {}
	for _, source in ipairs(available_sources) do
		for method in pairs(source.methods) do
			registered[method] = registered[method] or {}
			table.insert(registered[method], source.name)
		end
	end
	return registered
end

function M.list_formatters(ft)
	local providers = list_registered_providers_names(ft)
	return providers[FORMATTING] or {}
end

function M.list_linters(ft)
	local providers = list_registered_providers_names(ft)
	return providers[DIAGNOSTICS] or {}
end

function M.list_completions(ft)
	local providers = list_registered_providers_names(ft)
	return providers[COMPLETION] or {}
end

function M.list_code_actions(ft)
	local providers = list_registered_providers_names(ft)
	return providers[CODE_ACTION] or {}
end

function M.list_hovers(ft)
	local providers = list_registered_providers_names(ft)
	return providers[HOVER] or {}
end

function M.capabilities()
	local capabilities = vim.lsp.protocol.make_client_capabilities()
	return require("cmp_nvim_lsp").default_capabilities(capabilities)
end

local autocmd = function(args)
	local event = args[1]
	local group = args[2]
	local callback = args[3]

	vim.api.nvim_create_autocmd(event, {
		group = group,
		buffer = args[4],
		callback = function()
			callback()
		end,
		one = args.once,
	})
end

function M.on_attach(on_attach)
	vim.api.nvim_create_autocmd("LspAttach", {
		callback = function(args)
			local bufnr = args.buf
			local client = vim.lsp.get_client_by_id(args.data.client_id)

			if client.server_capabilities.documentHighlightProvider then
				autocmd_clear({
					group = augroup_highlight,
					buffer = bufnr,
				})
				autocmd({ "CursorHold", augroup_highlight, vim.lsp.buf.document_highlight, bufnr })
				autocmd({ "CursorMoved", augroup_highlight, vim.lsp.buf.clear_references, bufnr })
			end

			-- TODO: FIX THIS
			if client.name == "eslint" then
				client.server_capabilities.documentFormattingProvider = true
			end
			if client.name == "tsserver" then
				client.server_capabilities.documentFormattingProvider = false
			end

			on_attach(client, bufnr)
		end,
	})
end

return M
