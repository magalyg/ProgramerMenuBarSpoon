-- VSCode / Cursor Menu Bar Switcher in Hammerspoon
-- Initialize logging
local logger = hs.logger.new('VSCodeSwitcher', 'info')
logger.i("Initializing VSCode/Cursor Menu Bar Switcher")

local vscodeMenu = hs.menubar.new()
local vscodeTimer = nil

-- Get matching windows for VSCode or Cursor
local function getCodeWindows()
    logger.i("Scanning for VSCode/Cursor windows")
    local windows = hs.window.filter.new():getWindows()
    local codeWindows = {}

    -- Log all windows found first
    logger.i(string.format("Total windows found: %d", #windows))
    for i, win in ipairs(windows) do
        local appName = win:application():name()
        local windowTitle = win:title()
        logger.i(string.format("Window %d: %s - %s (ID: %d)", i, appName, windowTitle, win:id()))
    end

    -- Then filter for VSCode/Cursor windows
    local targetApps = {"Code", "Cursor", "Visual Studio Code", "VSCode"}

    for _, win in ipairs(windows) do
        local appName = win:application():name()
        local appNameLower = string.lower(appName)
        local matched = false

        -- Check if app name contains any of the target app names
        for _, target in ipairs(targetApps) do
            local targetLower = string.lower(target)
            if string.find(appNameLower, targetLower, 1, true) then
                matched = true
                logger.i(string.format("MATCH FOUND: App name '%s' contains '%s'", appName, target))
                break
            end
        end

        if matched then
            local windowTitle = win:title()
            logger.i(string.format("Adding matched %s window: %s (ID: %d)", appName, windowTitle, win:id()))
            table.insert(codeWindows, {
                title = windowTitle,
                id = win:id(),
                win = win
            })
        else
            logger.d(string.format("No match for app: %s", appName))
        end
    end

    logger.i(string.format("Found %d VSCode/Cursor windows out of %d total windows", #codeWindows, #windows))
    return codeWindows
end

-- Build menu
local function updateMenu()
    logger.d("Updating menu...")
    local items = {}
    local codeWindows = getCodeWindows()

    if #codeWindows == 0 then
        logger.d("No VSCode/Cursor windows found, showing disabled menu item")
        table.insert(items, {
            title = "❌ No VSCode/Cursor windows",
            disabled = true
        })
    else
        logger.d(string.format("Building menu with %d windows", #codeWindows))
        for i, w in ipairs(codeWindows) do
            local displayTitle = w.title ~= "" and w.title or "[untitled]"
            local appName = w.win:application():name()

            -- Determine emoji based on app and file type
            local emoji = "📄" -- default
            if appName == "Cursor" then
                emoji = "🔮"
            elseif appName == "Code" or string.find(appName, "Visual Studio Code") then
                -- Check file extension for more specific emojis
                if string.find(displayTitle:lower(), "%.js") or string.find(displayTitle:lower(), "%.ts") then
                    emoji = "🟨" -- JavaScript/TypeScript
                elseif string.find(displayTitle:lower(), "%.py") then
                    emoji = "🐍" -- Python
                elseif string.find(displayTitle:lower(), "%.lua") then
                    emoji = "🌙" -- Lua
                elseif string.find(displayTitle:lower(), "%.json") then
                    emoji = "📋" -- JSON
                elseif string.find(displayTitle:lower(), "%.md") then
                    emoji = "📝" -- Markdown
                elseif string.find(displayTitle:lower(), "%.css") or string.find(displayTitle:lower(), "%.scss") then
                    emoji = "🎨" -- CSS
                elseif string.find(displayTitle:lower(), "%.html") then
                    emoji = "🌐" -- HTML
                elseif string.find(displayTitle:lower(), "%.git") or string.find(displayTitle:lower(), "git") then
                    emoji = "🔀" -- Git
                elseif displayTitle == "[untitled]" then
                    emoji = "✨" -- Untitled
                else
                    emoji = "💻" -- VS Code default
                end
            end

            -- Add app indicator
            local appIndicator = ""
            if appName == "Cursor" then
                appIndicator = " [Cursor]"
            elseif appName == "Code" then
                appIndicator = " [Code]"
            elseif string.find(appName, "Visual Studio Code") then
                appIndicator = " [VSCode]"
            end

            local menuTitle = string.format("%s %s%s", emoji, displayTitle, appIndicator)

            logger.d(string.format("Adding menu item %d: %s", i, menuTitle))
            table.insert(items, {
                title = menuTitle,
                fn = function()
                    logger.i(string.format("User selected window: %s (ID: %d)", w.title, w.id))
                    w.win:focus()
                    logger.d("Window focused successfully")
                end
            })
        end
    end

    vscodeMenu:setMenu(items)
    logger.d("Menu updated successfully")
end

-- Setup menubar icon
logger.i("Setting up menubar icon")
vscodeMenu:setTitle("💻")
logger.i("Performing initial menu update")
updateMenu()

-- Auto-refresh every 3 seconds
logger.i("Starting auto-refresh timer (3 second interval)")
vscodeTimer = hs.timer.doEvery(20, function()
    logger.d("Timer triggered - updating menu")
    updateMenu()
end)

logger.i("VSCode/Cursor Menu Bar Switcher initialized successfully")
