local M = {}
local log = hs.logger.new("services", "debug")

function M.reload()
    log.i("Reloading Hammerspoon configuration")
    hs.alert.show("Reloading Hammerspoon")
    hs.timer.doAfter(0.1, hs.reload)
end

require("bindings").register({
    group = "System",
    title = "Reload Hammerspoon",
    shortcut = "Service manager",
    action = M.reload,
})

return M
