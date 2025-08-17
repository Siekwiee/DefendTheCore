require "src.ECS.components.ui"

---@class GameHubState : Object
local GameHubState = Object:extend()

function GameHubState:init()
    self.name = "MainHub"

    self.colors = {
        bg = {0.06, 0.07, 0.10, 1},
        title = {1, 1, 1, 1},
        subtitle = {0.85, 0.88, 0.92, 1},
        panel = {0.09, 0.10, 0.14, 1},
        button = {0.15, 0.17, 0.22, 1},
        buttonHover = {0.22, 0.25, 0.32, 1},
        buttonPress = {0.10, 0.12, 0.16, 1},
        text = {1, 1, 1, 1},
        muted = {0.8, 0.85, 0.9, 1},
    }

    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local TopBar = require("src.ui.top_bar")
    -- Shared top bar for Hub (no back button here)
    self.topbar = TopBar("Command Hub", "", w, h)
    self.ui = UIBox({ background = { color = self.colors.bg, drawMode = "fill" } })
    self.ui:resize(w, h)

    self:registerCallbacks()
    self:buildLayout(w, h)
end

function GameHubState:enter()
    if self.ui and (not self.ui.inputListeners or next(self.ui.inputListeners) == nil) then
        self.ui:setupInputListeners()
    end
end

function GameHubState:exit()
    if self.ui then self.ui:destroy() end
end

function GameHubState:onEscape()
    _G.Game.StateManager:switchState("MainMenu")
end

function GameHubState:update(dt)
    if self.ui then self.ui:update(dt) end
    if self.topbar then self.topbar:update(dt) end
end

function GameHubState:draw()
    if self.ui then self.ui:draw() end
    if self.topbar then self.topbar:draw() end
end

function GameHubState:resize(w, h)
    if self.ui then
        self.ui:resize(w, h)
        self:layout(w, h)
    end
    if self.topbar then self.topbar:resize(w, h) end
end

function GameHubState:registerCallbacks()
    local cm = _G.Game.CallbackManager

    cm:register("hub:buttonHover", function(element, isHovered)
        if not element or not element.background then return end
        element.background.color = isHovered and self.colors.buttonHover or self.colors.button
    end)
    cm:register("hub:buttonPress", function(element)
        if not element or not element.background then return end
        element.background.color = self.colors.buttonPress
    end)
    cm:register("hub:buttonRelease", function(element)
        if not element or not element.background then return end
        element.background.color = element.isHovered and self.colors.buttonHover or self.colors.button
    end)

    cm:register("hub:play", function()
        _G.Game.StateManager:switchState("EndlessRun")
    end)
    cm:register("hub:inventory", function()
        _G.Game.StateManager:switchState("Inventory")
    end)
    cm:register("hub:upgrades", function()
        _G.Game.StateManager:switchState("Upgrades")
    end)
    cm:register("hub:grantCredits", function()
        if _G.Game.SaveSystem then
            _G.Game.SaveSystem:addCredits(100)
            if _G.Game.PROFILE then _G.Game.SaveSystem:save(_G.Game.PROFILE) end
        end
    end)
    cm:register("hub:deleteSave", function()
        if _G.Game.SaveSystem then
            local ok, err = _G.Game.SaveSystem:deleteSave()
            if ok and _G.Game.PROFILE then
                _G.Game.SaveSystem:save(_G.Game.PROFILE)
            end
        end
    end)
    cm:register("hub:backToMenu", function()
        _G.Game.StateManager:switchState("MainMenu")
    end)
end

function GameHubState:createButton(label, cbName, x, y, w, h)
    local button = UIElement({
        elementName = "hub_btn_" .. string.gsub(string.lower(label), "%s+", "_"),
        x = x, y = y, width = w, height = h,
        pivotX = 0.5, pivotY = 0.5,
        text = label,
        fontSize = 24,
        textColor = self.colors.text,
        background = { color = self.colors.button, drawMode = "fill" },
        callbackName = cbName,
        hoverCallbackName = "hub:buttonHover",
        pressCallbackName = "hub:buttonPress",
        releaseCallbackName = "hub:buttonRelease",
        zIndex = 2,
        isFocusable = true,
    })
    self.ui:addElement(button)
    return button
end

function GameHubState:buildLayout(w, h)
    self.ui:clear()

    -- Title and old resource panel removed; TopBar provides title and resources
    self.title = nil
    self.resPanel = nil
    self.resLabel = nil

    -- Primary action buttons (centered column)
    local btnW, btnH = 320, 60
    local cx, top = w * 0.5, h * 0.45
    self.btnPlay = self:createButton("Play (Endless)", "hub:play", cx, top, btnW, btnH)
    self.btnInventory = self:createButton("Inventory", "hub:inventory", cx, top + 80, btnW, btnH)
    self.btnUpgrades = self:createButton("Upgrades", "hub:upgrades", cx, top + 160, btnW, btnH)

    -- Debug: grant credits
    self.btnGrant = self:createButton("+100 Credits (Debug)", "hub:grantCredits", cx, top + 240, btnW, btnH)
    -- Debug: delete save
    self.btnDeleteSave = self:createButton("Delete Save (Debug)", "hub:deleteSave", cx, top + 320, btnW, btnH)

    -- Back to main menu
    self.btnBack = UIElement({
        elementName = "hub_back",
        x = 24, y = h - 24,
        width = 220, height = 42,
        pivotX = 0, pivotY = 1,
        text = "Back to Main Menu",
        fontSize = 18,
        textColor = self.colors.text,
        background = { color = self.colors.button, drawMode = "fill" },
        callbackName = "hub:backToMenu",
        hoverCallbackName = "hub:buttonHover",
        pressCallbackName = "hub:buttonPress",
        releaseCallbackName = "hub:buttonRelease",
        zIndex = 2,
        isFocusable = true,
    })
    self.ui:addElement(self.btnBack)

    -- Initial focus - use focusableElements array
    if #self.ui.focusableElements > 0 then
        self.ui:setFocusByIndex(1)
    end

    -- Force first resource text update
    self:update(0)
end

function GameHubState:layout(w, h)
    if not self.ui then return end
    -- Title and resource panel removed (TopBar handles these)
    -- no-op
    -- Buttons
    if self.btnPlay and self.btnInventory and self.btnUpgrades then
        local btnW, btnH = 320, 60
        local cx, top = w * 0.5, h * 0.45
        self.btnPlay:setPosition(cx, top)
        self.btnPlay:setSize(btnW, btnH)
        self.btnInventory:setPosition(cx, top + 80)
        self.btnInventory:setSize(btnW, btnH)
        self.btnUpgrades:setPosition(cx, top + 160)
        self.btnUpgrades:setSize(btnW, btnH)
        if self.btnGrant then
            self.btnGrant:setPosition(cx, top + 240)
            self.btnGrant:setSize(btnW, btnH)
        end
        if self.btnDeleteSave then
            self.btnDeleteSave:setPosition(cx, top + 320)
            self.btnDeleteSave:setSize(btnW, btnH)
        end
    end
    if self.btnBack then
        self.btnBack:setPosition(24, h - 24)
        self.btnBack:setSize(220, 42)
    end
end

return GameHubState

