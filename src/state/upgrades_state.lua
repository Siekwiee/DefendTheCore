require "src.ECS.components.ui"

---@class UpgradesState : Object
local UpgradesState = Object:extend()

function UpgradesState:init()
    self.name = "Upgrades"

    self.colors = {
        bg = {0.06, 0.07, 0.10, 1},
        title = {1, 1, 1, 1},
        panel = {0.09, 0.10, 0.14, 1},
        card = {0.14, 0.16, 0.22, 1},
        cardHover = {0.18, 0.20, 0.28, 1},
        cardPress = {0.12, 0.14, 0.20, 1},
        text = {1, 1, 1, 1},
        muted = {0.8, 0.85, 0.9, 1},
        button = {0.15, 0.17, 0.22, 1},
        buttonHover = {0.22, 0.25, 0.32, 1},
        buttonPress = {0.10, 0.12, 0.16, 1},
    }

    -- Load definitions from external data file
    self.upgradeDefs = require("src.data.upgrades")

    self.ui = UIBox({ background = { color = self.colors.bg, drawMode = "fill" } })
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    self.ui:resize(w, h)

    self:registerCallbacks()

    -- Shared top bar for consistency (without back button)
    local TopBar = require("src.ui.top_bar")
    self.topbar = TopBar("Upgrades", "", w, h)

    self:buildLayout(w, h)
end

function UpgradesState:enter()
    if self.ui and (not self.ui.inputListeners or next(self.ui.inputListeners) == nil) then
        self.ui:setupInputListeners()
    end
end

function UpgradesState:exit()
    if self.ui then self.ui:destroy() end
    if self.topbar then self.topbar:destroy() end
end

function UpgradesState:onEscape()
    _G.Game.StateManager:switchState("MainHub")
end

function UpgradesState:update(dt)
    if self.ui then self.ui:update(dt) end
end

function UpgradesState:draw()
    if self.ui then self.ui:draw() end
    if self.topbar then self.topbar:draw() end
end

function UpgradesState:resize(w, h)
    if self.ui then
        self.ui:resize(w, h)
        self:layout(w, h)
    end
    if self.topbar then self.topbar:resize(w, h) end
end

function UpgradesState:registerCallbacks()
    local cm = _G.Game.CallbackManager
    cm:register("upgrades:buttonHover", function(element, isHovered)
        if not element or not element.background then return end
        element.background.color = isHovered and self.colors.buttonHover or self.colors.button
    end)
    cm:register("upgrades:buttonPress", function(element)
        if not element or not element.background then return end
        element.background.color = self.colors.buttonPress
    end)
    cm:register("upgrades:buttonRelease", function(element)
        if not element or not element.background then return end
        element.background.color = element.isHovered and self.colors.buttonHover or self.colors.button
    end)

    -- Card interactions
    cm:register("upgrades:cardHover", function(element, isHovered)
        if not element or not element.background then return end
        element.background.color = isHovered and self.colors.cardHover or (element.baseColor or self.colors.card)
    end)
    cm:register("upgrades:cardPress", function(element)
        if not element or not element.background then return end
        element.background.color = self.colors.cardPress
    end)
    cm:register("upgrades:cardRelease", function(element)
        if not element or not element.background then return end
        local target = element.isHovered and self.colors.cardHover or (element.baseColor or self.colors.card)
        element.background.color = target
    end)

    cm:register("upgrades:back", function()
        _G.Game.StateManager:switchState("MainHub")
    end)

    cm:register("upgrades:cardClick", function(element, args)
        local id = args and args.id
        if not id then return end
        local defs = self.upgradeDefs
        local def
        for _, d in ipairs(defs) do if d.id == id then def = d break end end
        if not def then return end

        local save = _G.Game.SaveSystem
        if save:hasPermanentUpgrade(id) then
            print("Already unlocked: " .. id)
            return
        end
        local cost = def.cost or 0
        if save:spendCredits(cost) then
            if save:unlockPermanentUpgrade(id) then
                print("Unlocked upgrade: " .. id .. " for " .. tostring(cost) .. " credits")
                if _G.Game.PROFILE then save:save(_G.Game.PROFILE) end
                -- Update card text/state
                self:updateCardElement(element, def)
            end
        else
            print("Not enough credits for: " .. id .. " (cost: " .. tostring(cost) .. ")")
        end
    end)
end

function UpgradesState:updateCardElement(card, def)
    local save = _G.Game.SaveSystem
    local unlocked = save:hasPermanentUpgrade(def.id)
    local status = unlocked and "Unlocked" or ("Cost: " .. tostring(def.cost))
    card.text = def.title .. "\n\n" .. def.desc .. "\n\n" .. status
    card.baseColor = unlocked and {0.12, 0.18, 0.14, 1} or self.colors.card
    card.background.color = card.baseColor
end

function UpgradesState:createCard(def, x, y, w, h)
    local card = UIElement({
        elementName = "upg_card_"..def.id,
        x = x, y = y, width = w, height = h,
        pivotX = 0.5, pivotY = 0.5,
        text = "", -- set below
        fontSize = 18,
        textColor = self.colors.text,
        wrap = true,
        textAlign = "left",
        textVAlign = "top",
        padding = { l = 16, t = 16, r = 16, b = 16 },
        background = { color = self.colors.card, drawMode = "fill" },
        hoverCallbackName = "upgrades:cardHover",
        pressCallbackName = "upgrades:cardPress",
        releaseCallbackName = "upgrades:cardRelease",
        callbackName = "upgrades:cardClick",
        callbackArgs = { id = def.id },
        isFocusable = true,
        zIndex = 2,
    })
    self:updateCardElement(card, def)
    self.ui:addElement(card)
    return card
end

function UpgradesState:buildLayout(w, h)
    self.ui:clear()

    -- Title
    self.title = UIElement({
        elementName = "upgrades_title",
        x = w * 0.5, y = h * 0.12,
        width = math.min(1100, w * 0.9), height = 64,
        pivotX = 0.5, pivotY = 0.5,
        text = "Permanent Upgrades",
        fontSize = 42,
        textColor = self.colors.title,
        background = { color = {0,0,0,0}, drawMode = "none" },
        zIndex = 1,
    })
    self.ui:addElement(self.title)

    -- Cards grid (3 columns)
    -- Responsive grid sizing based on count
    local count = #self.upgradeDefs
    local cols = math.min(3, math.max(1, math.ceil(math.sqrt(count))))
    local rows = math.ceil(count / cols)
    local cardW, cardH = 320, 180
    local spacing = 24
    local totalW = cols * cardW + (cols - 1) * spacing
    local startX = (w - totalW) * 0.5 + cardW * 0.5
    local startY = h * 0.24 + cardH * 0.5

    local i = 1
    for r=1,rows do
        for c=1,cols do
            local def = self.upgradeDefs[i]
            if not def then break end
            self:createCard(def,
                startX + (c-1)*(cardW + spacing),
                startY + (r-1)*(cardH + spacing),
                cardW, cardH)
            i = i + 1
        end
    end

    -- Back button
    self.btnBack = UIElement({
        elementName = "upgrades_back",
        x = 24, y = h - 24,
        width = 160, height = 42,
        pivotX = 0, pivotY = 1,
        text = "Back",
        fontSize = 18,
        textColor = self.colors.text,
        background = { color = self.colors.button, drawMode = "fill" },
        callbackName = "upgrades:back",
        hoverCallbackName = "upgrades:buttonHover",
        pressCallbackName = "upgrades:buttonPress",
        releaseCallbackName = "upgrades:buttonRelease",
        zIndex = 2,
        isFocusable = true,
    })
    self.ui:addElement(self.btnBack)

    -- Initial focus
    for i, e in ipairs(self.ui.elements) do
        if e.isFocusable then self.ui:setFocusByIndex(i) break end
    end

    -- Force update of card text/state post rebuild
    for _, el in ipairs(self.ui.elements) do
        if el.elementName and el.elementName:match("^upg_card_") then
            local id = el.elementName:gsub("upg_card_", "")
            for _, def in ipairs(self.upgradeDefs) do
                if def.id == id then self:updateCardElement(el, def) break end
            end
        end
    end
end

function UpgradesState:layout(w, h)
    if self.title then
        self.title:setPosition(w * 0.5, h * 0.12)
        self.title:setSize(math.min(1100, w * 0.9), 64)
    end
    -- Rebuild for simplicity on resize
    self:buildLayout(w, h)
end

return UpgradesState

