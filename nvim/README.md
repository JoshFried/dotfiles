
# Neovim configuration

`init.lua` is the entry point. For the startup sequence and checks for the
optional work plugins, see the [maintainer guide](../MAINTAINING.md#follow-a-neovim-feature).

- **Change a global shortcut** in `lua/config/keymaps/`. Register a new group
  in `lua/config/keymaps.lua`. For a shortcut that should load a plugin on
  demand, put the mapping in that plugin's `keys` spec.
- **Add language tools** under `lua/plugins/extra/lang/`. For languages split
  across files, the directory's `init.lua` returns the specs to import.
  Extend the common `opts` when contributing another server or formatter.
  Supplying a new `config` function for the same plugin can replace its
  shared initialization for every filetype.
- **Diagnose a plugin** with `:Lazy` to check whether it loaded, `:messages`
  for startup errors and `:verbose nmap <key>` for the active mapping.
  Inspect language tools in a buffer of the affected filetype so filetype
  triggers and buffer-local mappings have had a chance to run.
