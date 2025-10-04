local prefix = 'plugins.extra.lang.java'

return {
    {
        require(prefix .. ".ts"),
        require(prefix .. ".jdtls"),
        -- require(prefix .. ".nvim-java"),
        require(prefix .. ".mason"),
        require(prefix .. ".null-ls"),
    }
}
