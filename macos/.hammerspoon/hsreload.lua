local function reloadConfig()
    hs.reload()
    hs.alert.show("Config reloaded")
end

require("bindings").bind({
    group = "System",
    title = "Reload Hammerspoon",
    modifiers = hyper,
    key = "R",
    action = reloadConfig,
})
