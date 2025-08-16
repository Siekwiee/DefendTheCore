require "src.ECS.components.ui"
---@class MainMenuState : Object
MainMenuState = Object:extend()

function MainMenuState:init()
    self.name = "MainMenu"

    self.colors = {
        bg = {0.06, 0.07, 0.1, 1},
        title = {1, 1, 1, 1},
        subtitle = {0.8, 0.85, 0.9, 1},
        button = {0.15, 0.17, 0.22, 1},
        buttonHover = {0.22, 0.25, 0.32, 1},
        buttonPress = {0.1, 0.12, 0.16, 1},
    }

    self.ui = UIBox({
        background = { color = self.colors.bg, drawMode = "fill" }
    })

    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    self.ui:resize(w, h)

    self:registerCallbacks()
    self:buildLayout(w, h)
end

function MainMenuState:enter()
    -- Re-attach input listeners when this state becomes active again
    if self.ui and (not self.ui.inputListeners or next(self.ui.inputListeners) == nil) then
        self.ui:setupInputListeners()
    end
end

function MainMenuState:exit()
    if self.ui then
        self.ui:destroy()
    end
end

function MainMenuState:update(dt)
    if self.ui then
        self.ui:update(dt)
    end
end

function MainMenuState:draw()
    if self.ui then
        self.ui:draw()
    end
    if _G.Game and _G.Game.DEBUG then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("FPS: " .. tostring(love.timer.getFPS()), 10, 10)
    end
    -- Version bottom-left
    love.graphics.setColor(1, 1, 1, 0.6)
    love.graphics.print("v" .. tostring(_G.Game.VERSION), 10, love.graphics.getHeight() - 24)
    love.graphics.setColor(1, 1, 1, 1)
end

function MainMenuState:resize(w, h)
    if self.ui then
        self.ui:resize(w, h)
        self:layoutElements(w, h)
    end
end

-- === Internal helpers ===

function MainMenuState:registerCallbacks()
    local cm = _G.Game.CallbackManager

    cm:register("menu:buttonHover", function(element, isHovered)
        if not element or not element.background then return end
        element.background.color = isHovered and self.colors.buttonHover or self.colors.button
    end)

    cm:register("menu:buttonPress", function(element)
        if not element or not element.background then return end
        element.background.color = self.colors.buttonPress
    end)

    cm:register("menu:buttonRelease", function(element)
        if not element or not element.background then return end
        element.background.color = element.isHovered and self.colors.buttonHover or self.colors.button
    end)

    cm:register("menu:start", function()
        local sm = _G.Game.StateManager
        if sm and sm.states and sm.states["Run"] then
            sm:switchState("Run")
        else
            print("[MainMenu] Start selected (Run state not implemented yet)")
        end
    end)

    cm:register("menu:options", function()
        print("[MainMenu] Options selected (coming soon)")
    end)

    cm:register("menu:quit", function()
        _G.Game.StateManager:exit()
    end)
end

function MainMenuState:buildLayout(w, h)
    -- Title
    self.title = UIElement({
        elementName = "title",
        x = w * 0.5,
        y = h * 0.28,
        width = math.min(900, w * 0.9),
        height = 96,
        pivotX = 0.5,
        pivotY = 0.5,
        text = _G.Game.GAME_NAME or "Defend the Core",
        fontSize = 64,
        textColor = self.colors.title,
        background = { color = {0, 0, 0, 0}, drawMode = "none" },
        zIndex = 1,
    })
    self.ui:addElement(self.title)

    -- Subtitle
    self.subtitle = UIElement({
        elementName = "subtitle",
        x = w * 0.5,
        y = h * 0.36,
        width = math.min(900, w * 0.9),
        height = 40,
        pivotX = 0.5,
        pivotY = 0.5,
        text = "A minimal roguelike defense",
        fontSize = 22,
        textColor = self.colors.subtitle,
        background = { color = {0, 0, 0, 0}, drawMode = "none" },
        zIndex = 1,
    })
    self.ui:addElement(self.subtitle)

    -- Buttons
    local buttonWidth, buttonHeight = 280, 56
    self.btnStart = self:createButton("Start Run", "menu:start", w * 0.5, h * 0.55, buttonWidth, buttonHeight)
    self.btnOptions = self:createButton("Options", "menu:options", w * 0.5, h * 0.55 + 70, buttonWidth, buttonHeight)
    self.btnQuit = self:createButton("Quit", "menu:quit", w * 0.5, h * 0.55 + 140, buttonWidth, buttonHeight)
end

function MainMenuState:layoutElements(w, h)
    if self.title then
        self.title:setPosition(w * 0.5, h * 0.28)
        self.title:setSize(math.min(900, w * 0.9), 96)
    end
    if self.subtitle then
        self.subtitle:setPosition(w * 0.5, h * 0.36)
        self.subtitle:setSize(math.min(900, w * 0.9), 40)
    end
    if self.btnStart and self.btnOptions and self.btnQuit then
        local buttonWidth, buttonHeight = 280, 56
        self.btnStart:setPosition(w * 0.5, h * 0.55)
        self.btnStart:setSize(buttonWidth, buttonHeight)
        self.btnOptions:setPosition(w * 0.5, h * 0.55 + 70)
        self.btnOptions:setSize(buttonWidth, buttonHeight)
        self.btnQuit:setPosition(w * 0.5, h * 0.55 + 140)
        self.btnQuit:setSize(buttonWidth, buttonHeight)
    end
end

function MainMenuState:createButton(label, callbackName, x, y, w, h)
    local button = UIElement({
        elementName = "btn_" .. string.gsub(string.lower(label), "%s+", "_"),
        x = x,
        y = y,
        width = w,
        height = h,
        pivotX = 0.5,
        pivotY = 0.5,
        text = label,
        fontSize = 24,
        textColor = {1, 1, 1, 1},
        background = { color = self.colors.button, drawMode = "fill" },
        callbackName = callbackName,
        hoverCallbackName = "menu:buttonHover",
        pressCallbackName = "menu:buttonPress",
        releaseCallbackName = "menu:buttonRelease",
        zIndex = 2,
    })
    self.ui:addElement(button)
    return button
end