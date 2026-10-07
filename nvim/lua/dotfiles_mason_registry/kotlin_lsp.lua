local version = "263.6379.0"
local version_template = '{{ version | strip_prefix "kotlin-lsp/v" }}'
local download_root = "https://download.jetbrains.com/language-server/kotlin-server/" .. version_template
local server_root = "kotlin-server-" .. version_template

return {
	name = "kotlin-lsp",
	description = "Kotlin Language Server and plugin for Visual Studio Code",
	homepage = "https://github.com/Kotlin/kotlin-lsp",
	licenses = { "Apache-2.0" },
	languages = { "Kotlin" },
	categories = { "LSP" },
	source = {
		id = "pkg:generic/Kotlin/kotlin-lsp@kotlin-lsp/v" .. version,
		download = {
			{
				target = "darwin_x64",
				files = {
					["kotlin-lsp.zip"] = download_root .. "/" .. server_root .. ".sit",
				},
				bin = server_root .. "/bin/intellij-server",
			},
			{
				target = "darwin_arm64",
				files = {
					["kotlin-lsp.zip"] = download_root .. "/" .. server_root .. "-aarch64.sit",
				},
				bin = server_root .. "/bin/intellij-server",
			},
			{
				target = "linux_x64",
				files = {
					["kotlin-lsp.tar.gz"] = download_root .. "/" .. server_root .. ".tar.gz",
				},
				bin = server_root .. "/bin/intellij-server",
			},
			{
				target = "linux_arm64",
				files = {
					["kotlin-lsp.tar.gz"] = download_root .. "/" .. server_root .. "-aarch64.tar.gz",
				},
				bin = server_root .. "/bin/intellij-server",
			},
			{
				target = "win_x64",
				files = {
					["kotlin-lsp.zip"] = download_root .. "/" .. server_root .. ".win.zip",
				},
				bin = "bin/intellij-server.exe",
			},
			{
				target = "win_arm64",
				files = {
					["kotlin-lsp.zip"] = download_root .. "/" .. server_root .. "-aarch64.win.zip",
				},
				bin = "bin/intellij-server.exe",
			},
		},
	},
	bin = {
		["intellij-server"] = "{{source.download.bin}}",
	},
	neovim = {
		lspconfig = "kotlin_lsp",
	},
}
