--- Validates Hammerspoon Lua files before manual or automatic reloads.

local M = {}
local log = hs.logger.new("hsreload", "debug")
local configDirectory = hs.configdir
local debounceTimer = nil
local pendingReloadTimer = nil
local watchers = {}

local function trim(value)
    return (value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function collectLuaFiles(directory, files)
    for name in hs.fs.dir(directory) do
        if name ~= "." and name ~= ".." then
            local path = directory .. "/" .. name
            local linkAttributes = hs.fs.symlinkAttributes(path)
            local attributes = hs.fs.attributes(path)

            if attributes and attributes.mode == "directory"
                and (not linkAttributes or linkAttributes.mode ~= "link")
            then
                collectLuaFiles(path, files)
            elseif attributes and attributes.mode == "file" and name:match("%.lua$") then
                files[#files + 1] = path
            end
        end
    end
end

local function luaFiles()
    local files = {}
    local ok, errorMessage = pcall(collectLuaFiles, configDirectory, files)
    if not ok then
        return nil, tostring(errorMessage)
    end

    table.sort(files)
    return files
end

local function validationFailed(errorMessage)
    local message = trim(errorMessage)
    if message == "" then
        message = "Lua validation failed without an error message"
    end

    log.e(message)
    hs.alert.show("Hammerspoon reload blocked", 2)
    hs.notify.new({
        title = "Hammerspoon configuration invalid",
        informativeText = message,
    }):send()
end

local function reloadValidatedConfiguration()
    log.i("Hammerspoon configuration is valid; reloading")
    hs.alert.show("Reloading Hammerspoon")

    pendingReloadTimer = hs.timer.doAfter(0.1, function()
        pendingReloadTimer = nil
        hs.reload()
    end)
end

local function validateAndReload()
    if debounceTimer then
        debounceTimer:stop()
        debounceTimer = nil
    end

    local files, collectionError = luaFiles()
    if not files then
        validationFailed(collectionError)
        return
    end
    if #files == 0 then
        validationFailed("No Lua files found in " .. configDirectory)
        return
    end

    for _, path in ipairs(files) do
        local chunk, errorMessage = loadfile(path)
        if not chunk then
            validationFailed(errorMessage)
            return
        end
    end

    reloadValidatedConfiguration()
end

local function scheduleValidatedReload()
    if pendingReloadTimer then
        pendingReloadTimer:stop()
        pendingReloadTimer = nil
    end

    if debounceTimer then
        debounceTimer:stop()
    end

    debounceTimer = hs.timer.doAfter(0.5, function()
        debounceTimer = nil
        validateAndReload()
    end)
end

local function containsLuaChange(paths)
    for _, path in ipairs(paths) do
        if path:match("%.lua$") then
            return true
        end
    end
    return false
end

local function watchConfiguration()
    watchers[#watchers + 1] = hs.pathwatcher.new(configDirectory, function(paths)
        if containsLuaChange(paths) then
            scheduleValidatedReload()
        end
    end):start()

    local workLink = configDirectory .. "/work.lua"
    local workLinkAttributes = hs.fs.symlinkAttributes(workLink)
    local workTarget = workLinkAttributes and workLinkAttributes.target
    if not workTarget then
        return
    end

    local workDirectory = workTarget:match("^(.*)/[^/]+$")
    if not workDirectory then
        return
    end

    watchers[#watchers + 1] = hs.pathwatcher.new(workDirectory, function(paths)
        for _, path in ipairs(paths) do
            if path == workTarget then
                scheduleValidatedReload()
                return
            end
        end
    end):start()
end

function M.reload()
    validateAndReload()
end

M.watchers = watchers

require("bindings").register({
    group = "System",
    title = "Reload Hammerspoon",
    shortcut = "Service manager",
    action = M.reload,
})

watchConfiguration()

return M
