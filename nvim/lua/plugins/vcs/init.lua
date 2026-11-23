-- Collect Git views, hunk signs and conflict resolution into the version-control
-- plugin spec.

return {
    require("plugins.vcs.misc"),
    require('plugins.vcs.gitsigns'),
    require('plugins.vcs.git-conflict')
}
