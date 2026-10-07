--- On-demand AeroSpace workspace and window overview.

local bindings = require("bindings")
local kanagawa = require("kanagawa")

local M = {}
local aerospace = "/opt/homebrew/bin/aerospace"
local canvas
local keyWatcher
local workspaceTask
local windowTask
local actionTask
local requestId = 0
local selectedIndex = 1
local model
local visibleWorkspaces = {}
local visibleWindowCount = 0
local searchQuery = ""

local function color(hex, alpha)
    local value = kanagawa.rgb(hex)
    value.alpha = alpha or 1
    return value
end

local colors = {
    backdrop = color(kanagawa.palette.sumiInk0, 0.60),
    card = color(kanagawa.palette.sumiInk3, 0.98),
    cardCurrent = color(kanagawa.palette.sumiInk4, 0.98),
    border = color(kanagawa.palette.sumiInk5),
    selected = color(kanagawa.palette.crystalBlue),
    foreground = color(kanagawa.palette.fujiWhite),
    secondary = color(kanagawa.palette.oldWhite),
    muted = color(kanagawa.palette.katanaGray),
    active = color(kanagawa.palette.springGreen),
    separator = color(kanagawa.palette.sumiInk5, 0.8),
}

local function terminateTask(task)
    if task and task:isRunning() then
        task:terminate()
    end
end

local function hide()
    requestId = requestId + 1
    terminateTask(workspaceTask)
    terminateTask(windowTask)
    workspaceTask = nil
    windowTask = nil

    if keyWatcher then
        keyWatcher:stop()
        keyWatcher = nil
    end

    if canvas then
        canvas:delete()
        canvas = nil
    end
end

local function startAction(arguments)
    hide()
    terminateTask(actionTask)
    actionTask = hs.task.new(aerospace, function()
        actionTask = nil
    end, arguments)
    if actionTask and not actionTask:start() then
        actionTask = nil
        hs.alert.show("Unable to contact AeroSpace")
    end
end

local function switchWorkspace(workspace)
    if workspace then
        startAction({ "workspace", workspace.name })
    end
end

local function focusWindow(windowId)
    if windowId then
        startAction({ "focus", "--window-id", tostring(windowId) })
    end
end

local function appIcon(bundleID)
    if not bundleID or bundleID == "" then
        return nil
    end
    local ok, image = pcall(hs.image.imageFromAppBundle, bundleID)
    return ok and image or nil
end

local function createCanvas(frame, elements)
    if canvas then
        canvas:delete()
    end

    canvas = hs.canvas.new(frame)
    canvas:appendElements(table.unpack(elements))
    canvas:level(hs.canvas.windowLevels.overlay)
    canvas:clickActivating(false)
    canvas:mouseCallback(function(_, message, elementId)
        if message ~= "mouseDown" then
            return
        end

        if elementId == "background" then
            hide()
            return
        end

        local workspaceName = elementId and elementId:match("^workspace:(.+)$")
        if workspaceName then
            for _, workspace in ipairs(visibleWorkspaces) do
                if workspace.name == workspaceName then
                    switchWorkspace(workspace)
                    return
                end
            end
        end

        local windowId = elementId and elementId:match("^window:(%d+)$")
        if windowId then
            focusWindow(windowId)
        end
    end)
    canvas:show()
end

local function renderLoading()
    local screen = hs.mouse.getCurrentScreen() or hs.screen.mainScreen()
    local frame = screen:fullFrame()
    createCanvas(frame, {
        {
            id = "background",
            type = "rectangle",
            action = "fill",
            fillColor = colors.backdrop,
            frame = { x = 0, y = 0, w = frame.w, h = frame.h },
            trackMouseDown = true,
        },
        {
            type = "text",
            text = "Workspace Overview",
            textColor = colors.foreground,
            textSize = 30,
            textAlignment = "center",
            frame = { x = 0, y = frame.h / 2 - 34, w = frame.w, h = 42 },
        },
        {
            type = "text",
            text = "Reading AeroSpace state…",
            textColor = colors.muted,
            textSize = 15,
            textAlignment = "center",
            frame = { x = 0, y = frame.h / 2 + 12, w = frame.w, h = 28 },
        },
    })
end

local function gridColumns(frameWidth, workspaceCount)
    return frameWidth >= 1250 and math.min(5, workspaceCount) or math.min(2, workspaceCount)
end

local function fuzzyMatches(value, query)
    local valueIndex = 1
    local normalizedValue = value:lower()
    local normalizedQuery = query:lower()

    for queryIndex = 1, #normalizedQuery do
        local character = normalizedQuery:sub(queryIndex, queryIndex)
        local matchIndex = normalizedValue:find(character, valueIndex, true)
        if not matchIndex then
            return false
        end
        valueIndex = matchIndex + 1
    end

    return true
end

local function applySearch()
    local selectedWorkspace =
        visibleWorkspaces[selectedIndex] and visibleWorkspaces[selectedIndex].name
    visibleWorkspaces = {}
    visibleWindowCount = 0

    for _, workspace in ipairs(model.workspaces) do
        local matchingWindows = {}
        for _, window in ipairs(workspace.windows) do
            if fuzzyMatches(window.appName, searchQuery) then
                matchingWindows[#matchingWindows + 1] = window
            end
        end

        local hasVisibleWindows =
            searchQuery == "" and #workspace.windows > 0 or #matchingWindows > 0
        if hasVisibleWindows then
            local visibleWorkspace = workspace
            if searchQuery ~= "" then
                visibleWorkspace = {
                    name = workspace.name,
                    monitorId = workspace.monitorId,
                    monitorName = workspace.monitorName,
                    focused = workspace.focused,
                    visible = workspace.visible,
                    windows = matchingWindows,
                }
            end
            visibleWorkspaces[#visibleWorkspaces + 1] = visibleWorkspace
            visibleWindowCount = visibleWindowCount + #visibleWorkspace.windows
        end
    end

    selectedIndex = 1
    for index, workspace in ipairs(visibleWorkspaces) do
        if workspace.name == selectedWorkspace or
            (not selectedWorkspace and workspace.focused)
        then
            selectedIndex = index
            break
        end
    end
end

local function render()
    if not model then
        return
    end

    local screen = hs.mouse.getCurrentScreen() or hs.screen.mainScreen()
    local frame = screen:fullFrame()
    local topInset = math.max(40, screen:frame().y - frame.y)
    local count = #visibleWorkspaces
    local margin = math.max(28, math.floor(frame.w * 0.025))
    local gap = 14
    local headerHeight = topInset + 122
    local footerHeight = 34
    local availableHeight = frame.h - headerHeight - footerHeight
    local elements = {
        {
            id = "background",
            type = "rectangle",
            action = "fill",
            fillColor = colors.backdrop,
            frame = { x = 0, y = 0, w = frame.w, h = frame.h },
            trackMouseDown = true,
        },
        {
            type = "text",
            text = "Workspace Overview",
            textColor = colors.foreground,
            textSize = 30,
            frame = { x = margin, y = topInset + 12, w = frame.w - margin * 2, h = 38 },
        },
        {
            type = "text",
            text = string.format("%d workspaces · %d windows", count, visibleWindowCount),
            textColor = colors.muted,
            textSize = 14,
            frame = { x = margin, y = topInset + 48, w = frame.w - margin * 2, h = 24 },
        },
        {
            type = "rectangle",
            action = "strokeAndFill",
            fillColor = colors.card,
            strokeColor = searchQuery ~= "" and colors.selected or colors.border,
            strokeWidth = searchQuery ~= "" and 2 or 1,
            roundedRectRadii = { xRadius = 7, yRadius = 7 },
            frame = { x = margin, y = topInset + 76, w = frame.w - margin * 2, h = 36 },
        },
        {
            type = "text",
            text = searchQuery ~= "" and searchQuery .. "▌" or "Type to filter applications…",
            textColor = searchQuery ~= "" and colors.foreground or colors.muted,
            textSize = 15,
            frame = {
                x = margin + 12,
                y = topInset + 83,
                w = frame.w - margin * 2 - 24,
                h = 23,
            },
        },
        {
            type = "text",
            text = "↑↓←→ navigate · Return select · Delete edit · Esc close",
            textColor = colors.muted,
            textSize = 12,
            textAlignment = "center",
            frame = { x = margin, y = frame.h - 27, w = frame.w - margin * 2, h = 20 },
        },
    }

    if count == 0 then
        elements[#elements + 1] = {
            type = "text",
            text = "No applications match “" .. searchQuery .. "”",
            textColor = colors.muted,
            textSize = 18,
            textAlignment = "center",
            frame = {
                x = margin,
                y = headerHeight + availableHeight / 2 - 18,
                w = frame.w - margin * 2,
                h = 36,
            },
        }
        createCanvas(frame, elements)
        return
    end

    local columns = gridColumns(frame.w, count)
    local rows = math.ceil(count / columns)
    local cardWidth = (frame.w - margin * 2 - gap * (columns - 1)) / columns
    local cardHeight = math.min(300, (availableHeight - gap * (rows - 1)) / rows)
    local gridHeight = cardHeight * rows + gap * (rows - 1)
    local gridY = headerHeight + math.max(0, (availableHeight - gridHeight) / 2)

    for index, workspace in ipairs(visibleWorkspaces) do
        local column = (index - 1) % columns
        local row = math.floor((index - 1) / columns)
        local x = margin + column * (cardWidth + gap)
        local y = gridY + row * (cardHeight + gap)
        local selected = index == selectedIndex
        local fillColor = workspace.focused and colors.cardCurrent or colors.card
        local strokeColor = selected and colors.selected or colors.border

        elements[#elements + 1] = {
            id = "workspace:" .. workspace.name,
            type = "rectangle",
            action = "strokeAndFill",
            fillColor = fillColor,
            strokeColor = strokeColor,
            strokeWidth = selected and 3 or 1,
            roundedRectRadii = { xRadius = 8, yRadius = 8 },
            frame = { x = x, y = y, w = cardWidth, h = cardHeight },
            trackMouseDown = true,
        }
        elements[#elements + 1] = {
            type = "text",
            text = workspace.name,
            textColor = selected and colors.selected or colors.foreground,
            textSize = 27,
            frame = { x = x + 18, y = y + 14, w = 54, h = 38 },
        }

        local status = workspace.focused and "CURRENT" or workspace.monitorName
        elements[#elements + 1] = {
            type = "text",
            text = status,
            textColor = workspace.focused and colors.active or colors.muted,
            textSize = 11,
            textAlignment = "right",
            textLineBreak = "truncateTail",
            frame = { x = x + 76, y = y + 20, w = cardWidth - 94, h = 22 },
        }

        local contentY = y + 60
        local rowHeight = 46
        local maxRows = math.max(1, math.floor((cardHeight - 72) / rowHeight))
        local visibleWindows = math.min(#workspace.windows, maxRows)

        if visibleWindows == 0 then
            elements[#elements + 1] = {
                type = "text",
                text = "Empty",
                textColor = colors.muted,
                textSize = 14,
                textAlignment = "center",
                frame = { x = x + 16, y = contentY + 28, w = cardWidth - 32, h = 28 },
            }
        end

        for windowIndex = 1, visibleWindows do
            local window = workspace.windows[windowIndex]
            local rowY = contentY + (windowIndex - 1) * rowHeight
            local icon = appIcon(window.bundleID)

            elements[#elements + 1] = {
                id = "window:" .. window.id,
                type = "rectangle",
                action = "fill",
                fillColor = color(kanagawa.palette.sumiInk3, 0.01),
                frame = { x = x + 12, y = rowY, w = cardWidth - 24, h = rowHeight },
                trackMouseDown = true,
            }

            if windowIndex > 1 then
                elements[#elements + 1] = {
                    type = "segments",
                    action = "stroke",
                    strokeColor = colors.separator,
                    strokeWidth = 1,
                    coordinates = {
                        { x = x + 16, y = rowY },
                        { x = x + cardWidth - 16, y = rowY },
                    },
                }
            end

            if icon then
                elements[#elements + 1] = {
                    type = "image",
                    image = icon,
                    imageScaling = "scaleProportionally",
                    frame = { x = x + 18, y = rowY + 9, w = 27, h = 27 },
                }
            end

            local textX = x + (icon and 54 or 18)
            local textWidth = cardWidth - (textX - x) - 16
            elements[#elements + 1] = {
                type = "text",
                text = window.appName,
                textColor = colors.secondary,
                textSize = 13,
                textLineBreak = "truncateTail",
                frame = { x = textX, y = rowY + 4, w = textWidth, h = 20 },
            }
            elements[#elements + 1] = {
                type = "text",
                text = window.title,
                textColor = colors.muted,
                textSize = 11,
                textLineBreak = "truncateTail",
                frame = { x = textX, y = rowY + 23, w = textWidth, h = 18 },
            }
        end

        local hiddenCount = #workspace.windows - visibleWindows
        if hiddenCount > 0 then
            elements[#elements + 1] = {
                type = "text",
                text = string.format("+%d more", hiddenCount),
                textColor = colors.muted,
                textSize = 11,
                textAlignment = "right",
                frame = {
                    x = x + 18,
                    y = y + cardHeight - 24,
                    w = cardWidth - 36,
                    h = 18,
                },
            }
        end
    end

    createCanvas(frame, elements)
end

local function moveSelection(delta)
    if not model or #visibleWorkspaces == 0 then
        return
    end
    selectedIndex = ((selectedIndex - 1 + delta) % #visibleWorkspaces) + 1
    render()
end

local function removeLastSearchCharacter()
    searchQuery = searchQuery:sub(1, math.max(0, #searchQuery - 1))
    applySearch()
    render()
end

local function appendSearchCharacters(characters)
    if not characters or characters == "" or characters:find("[%c]") then
        return false
    end

    searchQuery = searchQuery .. characters
    applySearch()
    render()
    return true
end

local function startKeyWatcher()
    if keyWatcher then
        keyWatcher:stop()
    end

    keyWatcher = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
        local key = hs.keycodes.map[event:getKeyCode()]
        if key == "escape" then
            hide()
            return true
        end
        if not model then
            return false
        end

        if key == "delete" or key == "forwarddelete" then
            if searchQuery ~= "" then
                removeLastSearchCharacter()
            end
            return true
        end

        local screen = hs.mouse.getCurrentScreen() or hs.screen.mainScreen()
        local columns = #visibleWorkspaces > 0 and
            gridColumns(screen:fullFrame().w, #visibleWorkspaces) or 1
        if key == "left" then
            moveSelection(-1)
            return true
        elseif key == "right" then
            moveSelection(1)
            return true
        elseif key == "up" then
            moveSelection(-columns)
            return true
        elseif key == "down" then
            moveSelection(columns)
            return true
        elseif key == "return" or key == "padenter" then
            switchWorkspace(visibleWorkspaces[selectedIndex])
            return true
        end

        local flags = event:getFlags()
        if not flags.cmd and not flags.ctrl and not flags.alt then
            return appendSearchCharacters(event:getCharacters())
        end

        return false
    end)
    keyWatcher:start()
end

local function parseModel(workspaceOutput, windowOutput)
    local workspaces = {}
    local workspaceByName = {}
    local windowCount = 0

    for line in workspaceOutput:gmatch("[^\r\n]+") do
        local name, monitorId, focused, visible, monitorName =
            line:match("^([^|]*)|([^|]*)|([^|]*)|([^|]*)|(.*)$")
        if name and name ~= "" then
            local workspace = {
                name = name,
                monitorId = monitorId,
                monitorName = monitorName,
                focused = focused == "true",
                visible = visible == "true",
                windows = {},
            }
            workspaces[#workspaces + 1] = workspace
            workspaceByName[name] = workspace
        end
    end

    for line in windowOutput:gmatch("[^\r\n]+") do
        local workspaceName, appName, bundleID, windowId, title =
            line:match("^([^|]*)|([^|]*)|([^|]*)|([^|]*)|(.*)$")
        local workspace = workspaceByName[workspaceName]
        if workspace and windowId and windowId ~= "" then
            workspace.windows[#workspace.windows + 1] = {
                id = windowId,
                appName = appName ~= "" and appName or "Application",
                bundleID = bundleID,
                title = title ~= "" and title or "Untitled",
            }
            windowCount = windowCount + 1
        end
    end

    table.sort(workspaces, function(left, right)
        local leftNumber = tonumber(left.name)
        local rightNumber = tonumber(right.name)
        if leftNumber and rightNumber then
            return leftNumber < rightNumber
        end
        return left.name < right.name
    end)

    for index, workspace in ipairs(workspaces) do
        table.sort(workspace.windows, function(left, right)
            if left.appName == right.appName then
                return left.title < right.title
            end
            return left.appName < right.appName
        end)
        if workspace.focused then
            selectedIndex = index
        end
    end

    return {
        workspaces = workspaces,
        windowCount = windowCount,
    }
end

local function show()
    if canvas then
        hide()
        return
    end

    if not hs.fs.attributes(aerospace) then
        hs.alert.show("AeroSpace is not installed")
        return
    end

    requestId = requestId + 1
    local currentRequest = requestId
    local results = {}
    selectedIndex = 1
    visibleWorkspaces = {}
    visibleWindowCount = 0
    searchQuery = ""
    model = nil
    renderLoading()
    startKeyWatcher()

    local function finish()
        if currentRequest ~= requestId or results.workspaces == nil or results.windows == nil then
            return
        end

        model = parseModel(results.workspaces, results.windows)
        if #model.workspaces == 0 then
            hide()
            hs.alert.show("AeroSpace returned no workspaces")
            return
        end
        applySearch()
        render()
    end

    workspaceTask = hs.task.new(aerospace, function(exitCode, stdOut, stdErr)
        workspaceTask = nil
        if currentRequest ~= requestId then
            return
        end
        if exitCode ~= 0 then
            hide()
            hs.alert.show("Unable to read AeroSpace workspaces")
            hs.printf("AeroSpace workspace overview: %s", stdErr)
            return
        end
        results.workspaces = stdOut or ""
        finish()
    end, {
        "list-workspaces",
        "--all",
        "--format",
        "%{workspace}|%{monitor-id}|%{workspace-is-focused}|%{workspace-is-visible}|%{monitor-name}",
    })

    windowTask = hs.task.new(aerospace, function(exitCode, stdOut, stdErr)
        windowTask = nil
        if currentRequest ~= requestId then
            return
        end
        if exitCode ~= 0 then
            hide()
            hs.alert.show("Unable to read AeroSpace windows")
            hs.printf("AeroSpace workspace overview: %s", stdErr)
            return
        end
        results.windows = stdOut or ""
        finish()
    end, {
        "list-windows",
        "--all",
        "--format",
        "%{workspace}|%{app-name}|%{app-bundle-id}|%{window-id}|%{window-title}",
    })

    if not workspaceTask or not workspaceTask:start() or not windowTask or not windowTask:start() then
        hide()
        hs.alert.show("Unable to start AeroSpace overview")
    end
end

bindings.bind({
    group = "Workspaces",
    title = "Workspace overview",
    modifiers = hyper,
    key = "E",
    keywords = { "aerospace", "windows", "overview", "expose" },
    priority = 10,
    action = show,
})

M.hide = hide
M.show = show

return M
