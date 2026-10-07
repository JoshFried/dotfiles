-- Runtime patches and workarounds for nvim/LSP issues.
-- Keep these separate from options.lua so they're easy to find and remove
-- when upstream fixes land.

-- Restore removed LSP commands from nvim 0.12
vim.api.nvim_create_user_command("LspLog", function()
	vim.cmd.edit(vim.lsp.get_log_path())
end, {})
vim.api.nvim_create_user_command("LspInfo", function()
	vim.cmd("checkhealth lsp")
end, {})

-- Decompile classes inside jars when kotlin-lsp navigates to jar:// URIs.
-- nvim-jdtls retains ownership of jdt:// and plain *.class buffers.
local decompile_group = vim.api.nvim_create_augroup("CfrDecompile", { clear = true })
vim.api.nvim_create_autocmd("BufReadCmd", {
	group = decompile_group,
	pattern = "jar://*",
	callback = function(args)
		local jar, class_path = args.match:match("^jar://(.-)!/(.+)$")
		if not jar then
			return
		end

		local buf = args.buf
		vim.bo[buf].buftype = "nofile"
		vim.bo[buf].swapfile = false
		vim.bo[buf].modifiable = true

		local cfr = vim.fn.exepath("cfr-decompiler")
		local class_name = class_path:gsub("/", "."):gsub("%.class$", "")
		local result = cfr ~= "" and vim.fn.systemlist({ cfr, jar, class_name }) or {}
		if vim.v.shell_error == 0 and #result > 0 then
			vim.api.nvim_buf_set_lines(buf, 0, -1, false, result)
			vim.bo[buf].filetype = "java"
		else
			vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "// Decompilation failed" })
		end
		vim.bo[buf].modifiable = false
	end,
})
