--- Builds a searchable chooser from every visible registered binding.

local bindings = require("bindings")
local hyperState = require("hyper")
local kanagawa = require("kanagawa")

local M = {}
local actionById = {}
local activeRequestId = 0
local workspaceTask
local aerospace = "/opt/homebrew/bin/aerospace"
local chooser = hs.chooser.new(function(choice)
    if not choice then
        return
    end

    local action = actionById[choice.id]
    if action then
        hs.timer.doAfter(0, action.action)
    end
end)

kanagawa.styleChooser(chooser, { title = "Command Palette", rows = 12, width = 45 })

--- Removes surrounding whitespace from command output.
---@param value? string
---@return string
local function trim(value)
    return (value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

--- Builds the active application context before Hammerspoon takes focus.
---@return BindingContext
local function currentContext()
    local application = hs.application.frontmostApplication()
    return {
        app = application and application:name() or "Desktop",
        bundleID = application and application:bundleID() or "",
    }
end

--- Formats the chooser title for the active context.
---@param context BindingContext
---@return string
local function contextTitle(context)
    local parts = { "Command Palette", context.app or "Desktop" }
    if context.workspace and context.workspace ~= "" then
        parts[#parts + 1] = "Workspace " .. context.workspace
    end
    return table.concat(parts, " · ")
end

--- Rebuilds choices ordered by relevance to the active desktop context.
---@param context BindingContext
local function updateChoices(context)
    actionById = {}
    local choices = {}

    for index, action in ipairs(bindings.actions()) do
        local id = tostring(index)
        local score, matches = bindings.contextScore(action, context)
        local details = {}
        if #matches > 0 then
            details[#details + 1] = table.concat(matches, " + ")
        end
        details[#details + 1] = action.group
        details[#details + 1] = action.shortcut
        if action.keywords and #action.keywords > 0 then
            details[#details + 1] = table.concat(action.keywords, " ")
        end

        actionById[id] = action
        choices[#choices + 1] = {
            id = id,
            text = action.title,
            subText = table.concat(details, " · "),
            contextScore = score,
            group = action.group,
        }
    end

    table.sort(choices, function(left, right)
        if left.contextScore ~= right.contextScore then
            return left.contextScore > right.contextScore
        end
        if left.group ~= right.group then
            return left.group < right.group
        end
        return left.text < right.text
    end)

    chooser:placeholderText(contextTitle(context))
    chooser:choices(choices)
end

--- Adds AeroSpace workspace context without delaying chooser display.
---@param context BindingContext
---@param requestId integer
local function refreshWorkspaceContext(context, requestId)
    if workspaceTask then
        workspaceTask:terminate()
        workspaceTask = nil
    end

    if not hs.fs.attributes(aerospace) then
        return
    end

    workspaceTask = hs.task.new(aerospace, function(exitCode, stdOut)
        workspaceTask = nil
        if exitCode ~= 0 or requestId ~= activeRequestId or not chooser:isVisible() then
            return
        end

        local workspace = trim(stdOut)
        if workspace ~= "" then
            context.workspace = workspace
            updateChoices(context)
        end
    end, { "list-workspaces", "--focused" })

    if workspaceTask and not workspaceTask:start() then
        workspaceTask = nil
    end
end

--- Rebuilds and opens the command palette from the current registry.
local function showCommandPalette()
    activeRequestId = activeRequestId + 1
    local requestId = activeRequestId
    local context = currentContext()

    updateChoices(context)
    kanagawa.showChooser(chooser)
    hs.timer.doAfter(0.06, function()
        if requestId == activeRequestId and chooser:isVisible() then
            refreshWorkspaceContext(context, requestId)
        end
    end)
end

bindings.bind({
    group = "System",
    title = "Command palette",
    modifiers = hyper,
    key = ";",
    action = showCommandPalette,
})

bindings.bind({
    group = "System",
    title = "Command palette",
    modifiers = {},
    key = "F18",
    action = function()
        if not hyperState.wasChordUsedRecently() then
            showCommandPalette()
        end
    end,
    hidden = true,
})

M.show = showCommandPalette

return M
