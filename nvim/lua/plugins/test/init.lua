-- Collect the test runners, task executor, coverage viewer and associated
-- keybindings into the shared test spec.

local prefix = 'plugins.test'
return {
    require(prefix .. ".compiler"),
    require(prefix .. ".coverage"),
    require(prefix .. ".hydra"),
    require(prefix .. ".neotest"),
    require(prefix .. ".overseer"),
    require(prefix .. ".vim-test"),
}
