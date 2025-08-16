require "src.ECS.components.ui"

---@class InventoryState : Object
local InventoryState = Object:extend()

function InventoryState:init()
    self.name = "Inventory"

    self.colors = {
        bg = {0.06, 0.07, 0.10, 1},
        title = {1, 1, 1, 1},
        panel = {0.09, 0.10, 0.14, 1},
        grid = {0.12, 0.14, 0.18, 1},
        cell = {0.14, 0.16, 0.22, 1},
        text = {1, 1, 1, 1},
        muted = {0.8, 0.85, 0.9, 1},
        button = {0.15, 0.17, 0.22, 1},
        buttonHover = {0.22, 0.25, 0.32, 1},
        buttonPress = {0.10, 0.12, 0.16, 1},
    }

    self.ui = UIBox({ background = { color = self.colors.bg, drawMode = "fill" } })
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    self.ui:resize(w, h)

    self:registerCallbacks()

    -- Create shared top bar (no back button here)
    local TopBar = require("src.ui.top_bar")
    self.topbar = TopBar("Inventory", "", w, h)

    self:buildLayout(w, h)
end

function InventoryState:enter()
    if self.ui and (not self.ui.inputListeners or next(self.ui.inputListeners) == nil) then
        self.ui:setupInputListeners()
    end
    -- No back button on TopBar for Inventory
    if self.topbar then self.topbar.backCallbackName = "" end
end

function InventoryState:exit()
    if self.ui then self.ui:destroy() end
    if self.topbar then self.topbar:destroy() end
end

function InventoryState:onEscape()
    _G.Game.StateManager:switchState("MainHub")
end

function InventoryState:update(dt)
    if self.ui then self.ui:update(dt) end
end

function InventoryState:draw()
    if self.ui then self.ui:draw() end
    if self.topbar then self.topbar:draw() end
end

function InventoryState:resize(w, h)
    if self.ui then
        self.ui:resize(w, h)
        -- Rebuild layout to resize the grid cells responsively
        self:buildLayout(w, h)
    end
    if self.topbar then self.topbar:resize(w, h) end
end

function InventoryState:registerCallbacks()
    local cm = _G.Game.CallbackManager

    cm:register("inventory:buttonHover", function(element, isHovered)
        if not element or not element.background then return end
        element.background.color = isHovered and self.colors.buttonHover or self.colors.button
    end)
    cm:register("inventory:buttonPress", function(element)
        if not element or not element.background then return end
        element.background.color = self.colors.buttonPress
    end)
    cm:register("inventory:buttonRelease", function(element)
        if not element or not element.background then return end
        element.background.color = element.isHovered and self.colors.buttonHover or self.colors.button
    end)

    cm:register("inventory:back", function()
        _G.Game.StateManager:switchState("MainHub")
    end)

    -- Inventory cell interactions (hover/press/release) for later use
    cm:register("inventory:cellHover", function(element, isHovered)
        if element and element.background then
            element.background.color = isHovered and {0.18, 0.20, 0.26, 1} or self.colors.cell
        end
    end)
    cm:register("inventory:cellPress", function(element)
        if element and element.background then element.background.color = {0.12, 0.14, 0.18, 1} end
    end)
    cm:register("inventory:cellRelease", function(element)
        if element and element.background then
            local target = element.isHovered and {0.18, 0.20, 0.26, 1} or self.colors.cell
            element.background.color = target
        end
    end)
    cm:register("inventory:cellClick", function(element)
        -- Placeholder: open item details or equip/unequip when items are present
        print("Clicked inventory cell: " .. tostring(element and element.elementName))
    end)
end

function InventoryState:_addCell(name, x, y, w, h)
    local cell = UIElement({
        elementName = name,
        x = x, y = y, width = w, height = h,
        pivotX = 0.5, pivotY = 0.5,
        background = { color = self.colors.cell, drawMode = "fill" },
        hoverCallbackName = "inventory:cellHover",
        pressCallbackName = "inventory:cellPress",
        releaseCallbackName = "inventory:cellRelease",
        callbackName = "inventory:cellClick",
        zIndex = 2,
        isFocusable = true,
    })
    self.ui:addElement(cell)
    return cell
end

function InventoryState:buildLayout(w, h)
    self.ui:clear()

    -- Title
    self.title = UIElement({
        elementName = "inventory_title",
        x = w * 0.5, y = h * 0.12,
        width = math.min(1100, w * 0.9), height = 64,
        pivotX = 0.5, pivotY = 0.5,
        text = "Inventory",
        fontSize = 42,
        textColor = self.colors.title,
        background = { color = {0,0,0,0}, drawMode = "none" },
        zIndex = 1,
    })
    self.ui:addElement(self.title)

    -- Inventory panel and cells
    local panelW, panelH = math.min(1100, w * 0.9), h * 0.6
    local panelX, panelY = (w - panelW) * 0.5, h * 0.20
    self.panel = UIElement({
        elementName = "inventory_panel",
        x = panelX, y = panelY, width = panelW, height = panelH,
        pivotX = 0, pivotY = 0,
        background = { color = self.colors.panel, drawMode = "fill" },
        zIndex = 1,
    })
    self.ui:addElement(self.panel)

    -- Build a simple interactive grid of cells as placeholders
    local cols, rows = 8, 4
    local cellW, cellH = panelW / cols, panelH / rows
    local startX, startY = panelX + cellW/2, panelY + cellH/2
    for r=1,rows do
        for c=1,cols do
            local name = string.format("inv_cell_%d_%d", r, c)
            self:_addCell(name, startX + (c-1)*cellW, startY + (r-1)*cellH, cellW - 8, cellH - 8)
        end
    end

    -- Back button
    self.btnBack = UIElement({
        elementName = "inventory_back",
        x = 24, y = h - 24,
        width = 160, height = 42,
        pivotX = 0, pivotY = 1,
        text = "Back",
        fontSize = 18,
        textColor = self.colors.text,
        background = { color = self.colors.button, drawMode = "fill" },
        callbackName = "inventory:back",
        hoverCallbackName = "inventory:buttonHover",
        pressCallbackName = "inventory:buttonPress",
        releaseCallbackName = "inventory:buttonRelease",
        zIndex = 2,
        isFocusable = true,
    })
    self.ui:addElement(self.btnBack)

    -- Initial focus
    for i, e in ipairs(self.ui.elements) do
        if e.isFocusable then self.ui:setFocusByIndex(i) break end
    end
end

function InventoryState:layout(w, h)
    if self.title then
        self.title:setPosition(w * 0.5, h * 0.12)
        self.title:setSize(math.min(1100, w * 0.9), 64)
    end
    if self.panel then
        local panelW, panelH = math.min(1100, w * 0.9), h * 0.6
        local panelX, panelY = (w - panelW) * 0.5, h * 0.20
        self.panel:setPosition(panelX, panelY)
        self.panel:setSize(panelW, panelH)
    end
    if self.btnBack then
        self.btnBack:setPosition(24, h - 24)
        self.btnBack:setSize(160, 42)
    end
end

return InventoryState

