function Get_codelldb()
    local mason_registry = require("mason-registry")
    local codelldb = mason_registry.get_package("codelldb")
    local extension_path = codelldb:get_install_path() .. "/extension/"
    local codelldb_path = extension_path .. "adapter/codelldb"
    local liblldb_path = extension_path .. "lldb/lib/liblldb.dylib"
    return codelldb_path, liblldb_path
end

return {
    {
        require("plugins.extra.lang.rust.rustaceanvim"),
        require("plugins.extra.lang.rust.ts"),
        require("plugins.extra.lang.rust.neotest"),
        require("plugins.extra.lang.rust.dap")
    }
}
