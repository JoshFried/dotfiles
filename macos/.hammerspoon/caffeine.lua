require("bindings").bind({
    group = "System",
    title = "Sleep",
    modifiers = { "cmd", "alt" },
    key = "S",
    action = function()
        hs.caffeinate.systemSleep()
    end,
})
