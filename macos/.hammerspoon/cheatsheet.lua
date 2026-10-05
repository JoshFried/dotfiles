--- Context-aware searchable access to the tracked workflow cheatsheets.

local bindings = require("bindings")
local kanagawa = require("kanagawa")

local M = {}
local chooser
local tmuxTask
local repoRoot = os.getenv("HOME") .. "/repos/dotfiles"

local sources = {
    { path = repoRoot .. "/WORKFLOW_CHEATSHEET.md", name = "Workflow" },
    { path = hs.configdir .. "/CHEATSHEET.md", name = "Hammerspoon" },
    { path = os.getenv("HOME") .. "/.work.cheatsheet.md", name = "Work" },
}

local terminalApps = {
    Ghostty = true,
    WezTerm = true,
    Terminal = true,
    iTerm2 = true,
}

local function parseSource(source)
    local file = io.open(source.path, "r")
    if not file then
        return {}
    end

    local entries = {}
    local group = "General"
    local section = "General"
    for line in file:lines() do
        local levelTwoHeading = line:match("^##%s+(.+)$")
        local levelThreeHeading = line:match("^###%s+(.+)$")
        if levelTwoHeading then
            group = levelTwoHeading
            section = group
        elseif levelThreeHeading then
            section = string.format("%s · %s", group, levelThreeHeading)
        else
            local item = line:match("^%s*%-%s+(.+)$")
            if item then
                entries[#entries + 1] = {
                    text = item,
                    section = section,
                    source = source.name,
                }
            end
        end
    end

    file:close()
    return entries
end

local function priorityTerms(context)
    local terms = {}
    local app = context.app or ""
    local command = context.command or ""
    local path = context.path or ""

    if terminalApps[app] then
        terms = { "tmux", "sesh", "shell", "copy", "aerospace" }
    elseif app == "Hammerspoon" then
        terms = { "discovery", "service", "automatic", "battery" }
    else
        terms = { "applications", "productivity", "discovery", "windows" }
    end

    if command:match("n?vim") then
        table.insert(terms, 1, "neovim")
    end
    if path:match("/workplace/") then
        table.insert(terms, 1, "work")
    end
    if command:match("aws") or path:lower():match("cloudwatch") then
        table.insert(terms, 1, "cloudwatch")
        table.insert(terms, 2, "aws")
    end

    return terms
end

local function entryPriority(entry, terms)
    local searchable = (entry.section .. " " .. entry.text .. " " .. entry.source):lower()
    for index, term in ipairs(terms) do
        if searchable:find(term, 1, true) then
            return index
        end
    end
    return #terms + 1
end

local function buildChoices(context)
    local terms = priorityTerms(context)
    local choices = {}

    for _, source in ipairs(sources) do
        for _, entry in ipairs(parseSource(source)) do
            choices[#choices + 1] = {
                text = entry.text,
                subText = string.format("%s · %s", entry.source, entry.section),
                priority = entryPriority(entry, terms),
            }
        end
    end

    table.sort(choices, function(left, right)
        if left.priority == right.priority then
            if left.subText == right.subText then
                return left.text < right.text
            end
            return left.subText < right.subText
        end
        return left.priority < right.priority
    end)

    return choices
end

local function showChooser(context)
    context = context or {}
    local frontmostApplication = hs.application.frontmostApplication()
    context.app = context.app or (frontmostApplication and frontmostApplication:name()) or "Desktop"

    if not chooser then
        chooser = hs.chooser.new(function(choice)
            if not choice then
                return
            end

            local copied = choice.text:match("`([^`]+)`") or choice.text
            hs.pasteboard.setContents(copied)
            hs.alert.show("Copied: " .. copied, 1)
        end)
        kanagawa.styleChooser(chooser, {
            title = "Context Cheatsheet",
            rows = 14,
            width = 62,
        })
    end

    local contextParts = { "Context Cheatsheet", context.app }
    if context.command and context.command ~= "" then
        contextParts[#contextParts + 1] = context.command
    end
    chooser:placeholderText(table.concat(contextParts, " · "))
    chooser:choices(buildChoices(context))
    kanagawa.showChooser(chooser)
end

local function showContextCheatsheet()
    local frontmostApplication = hs.application.frontmostApplication()
    local app = frontmostApplication and frontmostApplication:name() or "Desktop"
    if not terminalApps[app] then
        showChooser({ app = app })
        return
    end

    local tmux
    for _, candidate in ipairs({ "/opt/homebrew/bin/tmux", "/usr/local/bin/tmux", "/usr/bin/tmux" }) do
        if hs.fs.attributes(candidate) then
            tmux = candidate
            break
        end
    end
    if not tmux then
        showChooser({ app = app })
        return
    end
    tmuxTask = hs.task.new(tmux, function(exitCode, stdOut)
        tmuxTask = nil
        local command, path, session
        if exitCode == 0 then
            command, path, session = (stdOut or ""):match("^([^|]*)|([^|]*)|([^|\n]*)")
        end
        showChooser({
            app = app,
            command = command,
            path = path,
            session = session,
        })
    end, {
        "display-message",
        "-p",
        "#{pane_current_command}|#{pane_current_path}|#{session_name}",
    })

    if not tmuxTask or not tmuxTask:start() then
        tmuxTask = nil
        showChooser({ app = app })
    end
end

bindings.bind({
    group = "Productivity",
    title = "Context cheatsheet",
    modifiers = hyper,
    key = "/",
    action = showContextCheatsheet,
})

hs.urlevent.bind("cheatsheet", showContextCheatsheet)

M.show = showContextCheatsheet

return M
