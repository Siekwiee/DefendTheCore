require "src.ECS.components.ui"

---@class OptionsState : Object
local OptionsState = Object:extend()

function OptionsState:init()
    self.name = "Options"

    self.colors = {
        bg = {0.06, 0.07, 0.10, 1},
        title = {1, 1, 1, 1},
        text = {1, 1, 1, 1},
        button = {0.15, 0.17, 0.22, 1},
        buttonHover = {0.22, 0.25, 0.32, 1},
        buttonPress = {0.10, 0.12, 0.16, 1},
    }

    self.ui = UIBox({ background = { color = self.colors.bg, drawMode = "fill" } })
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    self.ui:resize(w, h)

    self:registerCallbacks()
    self:buildLayout(w, h)
end

function OptionsState:enter()
    if self.ui and (not self.ui.inputListeners or next(self.ui.inputListeners) == nil) then
        self.ui:setupInputListeners()
    end
end

function OptionsState:exit()
    if self.ui then self.ui:destroy() end
end

function OptionsState:onEscape()
    _G.Game.StateManager:switchState("MainMenu")
end

function OptionsState:update(dt)
    if self.ui then self.ui:update(dt) end
end

function OptionsState:draw()
    -- First draw the background
    love.graphics.clear(0.06, 0.07, 0.10, 1)

    -- Then draw the UI
    if self.ui then
        self.ui:draw()
    end
end

function OptionsState:resize(w, h)
    if self.ui then
        self.ui:resize(w, h)
        self:layout(w, h)
    end
end

function OptionsState:registerCallbacks()
    local cm = _G.Game.CallbackManager
    cm:register("options:buttonHover", function(element, isHovered)
        if not element or not element.background then return end
        element.background.color = isHovered and self.colors.buttonHover or self.colors.button
    end)
    cm:register("options:buttonPress", function(element)
        if not element or not element.background then return end
        element.background.color = self.colors.buttonPress
    end)
    cm:register("options:buttonRelease", function(element)
        if not element or not element.background then return end
        element.background.color = element.isHovered and self.colors.buttonHover or self.colors.button
    end)
    cm:register("options:back", function()
        _G.Game.StateManager:switchState("MainMenu")
    end)
end

function OptionsState:buildLayout(w, h)
    self.ui:clear()

    self.title = UIElement({
        elementName = "options_title",
        x = w * 0.5, y = h * 0.12,
        width = math.min(1100, w * 0.9), height = 64,
        pivotX = 0.5, pivotY = 0.5,
        text = "Options",
        fontSize = 42,
        textColor = self.colors.title,
        background = { color = {0,0,0,0}, drawMode = "none" },
        zIndex = 1,
    })
    self.ui:addElement(self.title)

    -- FPS toggle example from settings profile
    local fpsLabel = UIElement({
        elementName = "opt_fps_label",
        x = w * 0.5 - 80, y = h * 0.28,
        width = 200, height = 40,
        pivotX = 1, pivotY = 0.5,
        text = "Show FPS",
        fontSize = 20,
        textColor = self.colors.text,
        background = { color = {0,0,0,0}, drawMode = "none" },
        zIndex = 2,
    })
    self.ui:addElement(fpsLabel)

    local fpsBtn = UIElement({
        elementName = "opt_fps_btn",
        x = w * 0.5 + 80, y = h * 0.28,
        width = 100, height = 40,
        pivotX = 0, pivotY = 0.5,
        text = _G.Game.SETTINGS.showFPS and "ON" or "OFF",
        fontSize = 18,
        textColor = self.colors.text,
        background = { color = self.colors.button, drawMode = "fill" },
        callbackName = "options:toggleFPS",
        hoverCallbackName = "options:buttonHover",
        pressCallbackName = "options:buttonPress",
        releaseCallbackName = "options:buttonRelease",
        zIndex = 2,
        isFocusable = true
    })
    self.ui:addElement(fpsBtn)

    local cm = _G.Game.CallbackManager
    cm:register("options:toggleFPS", function(el)
        _G.Game.SETTINGS.showFPS = not _G.Game.SETTINGS.showFPS
        el.text = _G.Game.SETTINGS.showFPS and "ON" or "OFF"
    end)

    -- Back
    self.btnBack = UIElement({
        elementName = "options_back",
        x = 24, y = h - 24,
        width = 160, height = 42,
        pivotX = 0, pivotY = 1,
        text = "Back",
        fontSize = 18,
        textColor = self.colors.text,
        background = { color = self.colors.button, drawMode = "fill" },
        callbackName = "options:back",
        hoverCallbackName = "options:buttonHover",
        pressCallbackName = "options:buttonPress",
        releaseCallbackName = "options:buttonRelease",
        zIndex = 2,
        isFocusable = true,
    })
    self.ui:addElement(self.btnBack)

    -- Initial focus - use focusableElements array
    if #self.ui.focusableElements > 0 then
        self.ui:setFocusByIndex(1)
    end
end

function OptionsState:layout(w, h)
    if self.title then
        self.title:setPosition(w * 0.5, h * 0.12)
        self.title:setSize(math.min(1100, w * 0.9), 64)
    end
    if self.btnBack then
        self.btnBack:setPosition(24, h - 24)
        self.btnBack:setSize(160, 42)
    end
end

return OptionsState

