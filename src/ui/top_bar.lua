require "src.ECS.components.ui"

---@class TopBar : Object
local TopBar = Object:extend()

---Create a top bar with title, back button and live resources
---@param title string
---@param backCallbackName string callback to execute when back button pressed
---@param width number
---@param height number
function TopBar:init(title, backCallbackName, width, height)
    self.colors = {
        bar = {0.09, 0.10, 0.14, 0.96},
        text = {1, 1, 1, 1},
        button = {0.15, 0.17, 0.22, 1},
        buttonHover = {0.22, 0.25, 0.32, 1},
        buttonPress = {0.10, 0.12, 0.16, 1},
        muted = {0.8, 0.85, 0.9, 1},
    }

    self.ui = UIBox({ background = { color = {0,0,0,0}, drawMode = "none" } })
    self.titleText = title or ""
    self.backCallbackName = backCallbackName or ""
    self:build(width, height)
    self:registerCallbacks()
end

function TopBar:registerCallbacks()
    local cm = _G.Game.CallbackManager
    cm:register("topbar:buttonHover", function(el, isH)
        if not el or not el.background then return end
        el.background.color = isH and self.colors.buttonHover or self.colors.button
    end)
    cm:register("topbar:buttonPress", function(el)
        if not el or not el.background then return end
        el.background.color = self.colors.buttonPress
    end)
    cm:register("topbar:buttonRelease", function(el)
        if not el or not el.background then return end
        el.background.color = el.isHovered and self.colors.buttonHover or self.colors.button
    end)
end

function TopBar:update(dt)
    if self.ui then self.ui:update(dt) end
    -- Update resources label text
    if self.resLabel then
        local p = _G.Game.PROFILE and _G.Game.PROFILE.player or {}
        local credits = tostring(p.credits or 0)
        local parts = tostring(p.parts or 0)
        local cores = tostring(p.cores or 0)
        self.resLabel.text = string.format("Credits: %s   Parts: %s   Cores: %s", credits, parts, cores)
    end
end

function TopBar:draw()
    if self.ui then self.ui:draw() end
end

function TopBar:resize(w, h)
    self:build(w, h)
end

function TopBar:destroy()
    if self.ui then self.ui:destroy() end
end

function TopBar:build(w, h)
    self.ui:clear()
    local barH = 56
    -- Bar background
    self.bar = UIElement({
        elementName = "topbar_bg",
        x = 0, y = 0, width = w, height = barH,
        pivotX = 0, pivotY = 0,
        background = { color = self.colors.bar, drawMode = "fill" },
        zIndex = 1,
    })
    self.ui:addElement(self.bar)

    -- Title
    self.title = UIElement({
        elementName = "topbar_title",
        x = w * 0.5, y = barH * 0.5,
        width = w * 0.4, height = barH,
        pivotX = 0.5, pivotY = 0.5,
        text = self.titleText,
        fontSize = 24,
        textColor = self.colors.text,
        background = { color = {0,0,0,0}, drawMode = "none" },
        zIndex = 2,
    })
    self.ui:addElement(self.title)

    -- Back button (optional). If no callback provided, omit button.
    if self.backCallbackName and self.backCallbackName ~= "" then
        self.backBtn = UIElement({
            elementName = "topbar_back",
            x = 12, y = barH/2,
            width = 120, height = 36,
            pivotX = 0, pivotY = 0.5,
            text = "Back",
            fontSize = 18,
            textColor = self.colors.text,
            background = { color = self.colors.button, drawMode = "fill" },
            callbackName = self.backCallbackName,
            hoverCallbackName = "topbar:buttonHover",
            pressCallbackName = "topbar:buttonPress",
            releaseCallbackName = "topbar:buttonRelease",
            zIndex = 2,
            isFocusable = true,
        })
        self.ui:addElement(self.backBtn)
    else
        self.backBtn = nil
    end

    -- Resources label (right side)
    self.resLabel = UIElement({
        elementName = "topbar_resources",
        x = w - 12, y = barH/2,
        width = w * 0.4, height = barH,
        pivotX = 1, pivotY = 0.5,
        text = "",
        fontSize = 18,
        textColor = self.colors.muted,
        background = { color = {0,0,0,0}, drawMode = "none" },
        zIndex = 2,
        textAlign = "right",
    })
    self.ui:addElement(self.resLabel)
end

return TopBar

