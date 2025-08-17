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
    -- Apply setting changes live to systems in Run state if needed later; for now we just update globals.
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
        if sm and sm.states and sm.states["MainHub"] then
            sm:switchState("MainHub")
        else
            print("[MainMenu] Start selected (Hub state not implemented yet)")
        end
    end)

    cm:register("menu:options", function()
        _G.Game.StateManager:switchState("Options")
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
        text = "A hub-based survival defense",
        fontSize = 22,
        textColor = self.colors.subtitle,
        background = { color = {0, 0, 0, 0}, drawMode = "none" },
        zIndex = 1,
    })
    self.ui:addElement(self.subtitle)

    -- Buttons
    local buttonWidth, buttonHeight = 280, 56
    self.btnStart = self:createButton("Start Run", "menu:start", w * 0.5, h * 0.55, buttonWidth, buttonHeight, { isFocusable = true, tooltipText = "Begin a new run" })
    self.btnOptions = self:createButton("Options", "menu:options", w * 0.5, h * 0.55 + 70, buttonWidth, buttonHeight, { isFocusable = true, tooltipText = "Settings (soon)" })
    self.btnQuit = self:createButton("Quit", "menu:quit", w * 0.5, h * 0.55 + 140, buttonWidth, buttonHeight, { isFocusable = true, tooltipText = "Exit to desktop" })

    -- Set initial keyboard focus to first focusable element
    if #self.ui.focusableElements > 0 then
        self.ui:setFocusByIndex(1)
    end
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

function MainMenuState:createButton(label, callbackName, x, y, w, h, extraProps)
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
    if extraProps then
        for k, v in pairs(extraProps) do
            button[k] = v
        end
    end
    self.ui:addElement(button)
    return button
end

function MainMenuState:openOptions()
    -- Clear existing option panel if it exists
    if self.optionsPanel then
        self.ui:removeElement(self.optionsPanel)
        self.optionsPanel = nil
    end

    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local panelW, panelH = 460, 300
    local panelX, panelY = (w - panelW) * 0.5, (h - panelH) * 0.5

    -- Container panel
    self.optionsPanel = UIElement({
        elementName = "options_panel",
        x = panelX,
        y = panelY,
        width = panelW,
        height = panelH,
        background = { color = {0.08, 0.09, 0.12, 0.95}, drawMode = "fill" },
        zIndex = 10,
        onDraw = function()
            -- Title
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.setFont(love.graphics.newFont(24))
            love.graphics.print("Options", panelX + 16, panelY + 12)
            love.graphics.setFont(love.graphics.newFont(14))
        end
    })
    self.ui:addElement(self.optionsPanel)

    -- Close button
    local btnClose = UIElement({
        elementName = "btn_close_options",
        x = panelX + panelW - 100,
        y = panelY + panelH - 46,
        width = 84,
        height = 30,
        text = "Close",
        fontSize = 18,
        textColor = {1, 1, 1, 1},
        background = { color = self.colors.button, drawMode = "fill" },
        callbackName = "menu:closeOptions",
        hoverCallbackName = "menu:buttonHover",
        pressCallbackName = "menu:buttonPress",
        releaseCallbackName = "menu:buttonRelease",
        zIndex = 11,
        isFocusable = true,
    })
    self.ui:addElement(btnClose)

    -- Show FPS toggle
    local fpsLabel = UIElement({
        elementName = "lbl_show_fps",
        x = panelX + 24,
        y = panelY + 70,
        width = 200,
        height = 28,
        text = "Show FPS Counter",
        fontSize = 18,
        textAlign = "left",
        textVAlign = "middle",
        background = { color = {0,0,0,0}, drawMode = "none" },
        zIndex = 11,
    })
    self.ui:addElement(fpsLabel)

    local fpsToggle = UIElement({
        elementName = "btn_toggle_fps",
        x = panelX + panelW - 140,
        y = panelY + 66,
        width = 100,
        height = 32,
        text = (_G.Game.SETTINGS.showFPS ~= false) and "ON" or "OFF",
        fontSize = 18,
        textColor = {1, 1, 1, 1},
        background = { color = self.colors.button, drawMode = "fill" },
        callbackName = "menu:toggleFPS",
        hoverCallbackName = "menu:buttonHover",
        pressCallbackName = "menu:buttonPress",
        releaseCallbackName = "menu:buttonRelease",
        zIndex = 11,
        isFocusable = true,
    })
    self.ui:addElement(fpsToggle)

    -- Volume sliders labels
    local masterLabel = UIElement({
        elementName = "lbl_master",
        x = panelX + 24,
        y = panelY + 116,
        width = 200,
        height = 24,
        text = "Master Volume",
        fontSize = 18,
        textAlign = "left",
        textVAlign = "middle",
        background = { color = {0,0,0,0}, drawMode = "none" },
        zIndex = 11,
    })
    self.ui:addElement(masterLabel)

    local sfxLabel = UIElement({
        elementName = "lbl_sfx",
        x = panelX + 24,
        y = panelY + 156,
        width = 200,
        height = 24,
        text = "SFX Volume",
        fontSize = 18,
        textAlign = "left",
        textVAlign = "middle",
        background = { color = {0,0,0,0}, drawMode = "none" },
        zIndex = 11,
    })
    self.ui:addElement(sfxLabel)

    -- Slider draw helper
    local function sliderDraw(element, value)
        local x, y = element:getRenderPosition()
        local w, h = element.width, element.height
        love.graphics.setColor(0.2, 0.25, 0.32, 1)
        love.graphics.rectangle("fill", x, y + h/2 - 4, w, 8)
        love.graphics.setColor(0.3, 0.7, 1.0, 1)
        love.graphics.rectangle("fill", x, y + h/2 - 4, w * value, 8)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("line", x, y + h/2 - 4, w, 8)
    end

    -- Master volume slider
    local masterSlider = UIElement({
        elementName = "slider_master",
        x = panelX + 240,
        y = panelY + 116,
        width = 200,
        height = 24,
        background = { color = {0,0,0,0}, drawMode = "none" },
        onDraw = function(el)
            local v = _G.Game.SETTINGS.audio.master or 0.8
            sliderDraw(el, v)
        end,
        callbackName = "menu:sliderMaster",
        zIndex = 11,
        isFocusable = true,
    })
    self.ui:addElement(masterSlider)

    -- SFX volume slider
    local sfxSlider = UIElement({
        elementName = "slider_sfx",
        x = panelX + 240,
        y = panelY + 156,
        width = 200,
        height = 24,
        background = { color = {0,0,0,0}, drawMode = "none" },
        onDraw = function(el)
            local v = _G.Game.SETTINGS.audio.sfx or 0.9
            sliderDraw(el, v)
        end,
        callbackName = "menu:sliderSFX",
        zIndex = 11,
        isFocusable = true,
    })
    self.ui:addElement(sfxSlider)

    -- Register callbacks for options controls
    local cm = _G.Game.CallbackManager
    cm:register("menu:closeOptions", function()
        if self.optionsPanel then
            self.ui:removeElement(self.optionsPanel)
            self.optionsPanel = nil
            -- Remove panel-related controls too
            for _, name in ipairs({"btn_close_options","btn_toggle_fps","lbl_show_fps","lbl_master","slider_master","lbl_sfx","slider_sfx"}) do
                local el = self.ui:getElementByName(name)
                if el then self.ui:removeElement(el) end
            end
        end
    end)

    cm:register("menu:toggleFPS", function(button)
        _G.Game.SETTINGS.showFPS = not (_G.Game.SETTINGS.showFPS == false)
        button.text = (_G.Game.SETTINGS.showFPS ~= false) and "ON" or "OFF"
    end)

    -- Sliders adjust on Left/Right keys when focused
    cm:register("menu:sliderMaster", function(el)
        local step = 0.1
        local v = (_G.Game.SETTINGS.audio.master or 0.8) + (love.keyboard.isDown("right") and step or (love.keyboard.isDown("left") and -step or 0))
        v = math.max(0, math.min(1, v))
        _G.Game.SETTINGS.audio.master = v
    end)

    cm:register("menu:sliderSFX", function(el)
        local step = 0.1
        local v = (_G.Game.SETTINGS.audio.sfx or 0.9) + (love.keyboard.isDown("right") and step or (love.keyboard.isDown("left") and -step or 0))
        v = math.max(0, math.min(1, v))
        _G.Game.SETTINGS.audio.sfx = v
    end)
end