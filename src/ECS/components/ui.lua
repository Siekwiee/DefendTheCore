---Merge multiple property tables into one, with later tables overriding earlier ones
---@param ... table Property tables to merge
---@return table mergedProps The merged properties table
local function mergeProps(...)
    local result = {}
    local tables = {...}
    
    for _, props in ipairs(tables) do
        if props then
            for key, value in pairs(props) do
                result[key] = value
            end
        end
    end
    
    return result
end

-- Make mergeProps globally available in the UI module
UI = {
    mergeProps = mergeProps
}

---@class UIBox : Transformable
---@field elements UIElement[] List of UI elements managed by this box
---@field needsSort boolean Z-index sorting flag
---@field inputListeners table Event listener functions that need to be cleaned up
UIBox = Transformable:extend()

---@param properties table? Optional properties table
function UIBox:init(properties)
    -- Initialize transformable properties
    Transformable.init(self, "UIBox", properties)
    
    -- List of UI elements managed by this box
    self.elements = {}
    -- Z-index sorting for elements
    self.needsSort = false
    -- Track input listeners for cleanup
    self.inputListeners = {}

    -- Background of UIBox
    if properties and properties.background then
        self.background = properties.background
    else
        self.background = {
            color = {0.5, 0.0, 0.5, 1}, -- Purple background as default because then something is missing and purple is recognized as a missing texture
            drawMode = "fill" -- "fill" or "line"
        }
    end
    
    -- Register input event listeners
    self:setupInputListeners()
end

---Setup input event listeners for this UIBox
function UIBox:setupInputListeners()
    -- Mouse press handler
    local mousePressedHandler = function(eventData)
        self:handleMousePressed(eventData.x, eventData.y, eventData.button)
    end
    
    -- Mouse release handler
    local mouseReleasedHandler = function(eventData)
        self:handleMouseReleased(eventData.x, eventData.y, eventData.button)
    end
    
    -- Mouse move handler
    local mouseMovedHandler = function(eventData)
        self:handleMouseMoved(eventData.x, eventData.y)
    end
    
    -- Register listeners
    _G.Game.InputManager:addEventListener("mousepressed", mousePressedHandler)
    _G.Game.InputManager:addEventListener("mousereleased", mouseReleasedHandler)
    _G.Game.InputManager:addEventListener("mousemoved", mouseMovedHandler)
    
    -- Store references for cleanup
    self.inputListeners.mousepressed = mousePressedHandler
    self.inputListeners.mousereleased = mouseReleasedHandler
    self.inputListeners.mousemoved = mouseMovedHandler
end

---Clean up input event listeners
function UIBox:destroy()
    if self.inputListeners.mousepressed then
        _G.Game.InputManager:removeEventListener("mousepressed", self.inputListeners.mousepressed)
    end
    if self.inputListeners.mousereleased then
        _G.Game.InputManager:removeEventListener("mousereleased", self.inputListeners.mousereleased)
    end
    if self.inputListeners.mousemoved then
        _G.Game.InputManager:removeEventListener("mousemoved", self.inputListeners.mousemoved)
    end
    self.inputListeners = {}
end

function UIBox:addElement(element)
    table.insert(self.elements, element)
    self.needsSort = true
end

function UIBox:removeElement(element)
    for i, e in ipairs(self.elements) do
        if e == element then
            table.remove(self.elements, i)
            break
        end
    end
end

-- Sort elements by z-index if needed
function UIBox:sortElements()
    if self.needsSort then
        table.sort(self.elements, function(a, b)
            return (a.zIndex or 0) < (b.zIndex or 0)
        end)
        self.needsSort = false
    end
end

function UIBox:update(dt)
    self:sortElements()
    
    -- Update elements
    for _, element in ipairs(self.elements) do
        if element.update then
            element:update(dt)
        end
    end
end

function UIBox:updateElementProperties(elementName, propertieName, newValue)
    for _, element in ipairs(self.elements) do
        if element.elementName == elementName then
            element[propertieName] = newValue
        end
    end
end

---Handle mouse press events
---@param x number Mouse X position
---@param y number Mouse Y position  
---@param button number Mouse button
function UIBox:handleMousePressed(x, y, button)
    self:sortElements()
    
    -- Process elements in reverse order (top-most first for input)
    for i = #self.elements, 1, -1 do
        local element = self.elements[i]
        if element:contains(x, y) and element.isInteractive and element.visible then
            element:onMousePressed(x, y, button)
            break -- Stop at first element that handled the input
        end
    end
end

---Handle mouse release events
---@param x number Mouse X position
---@param y number Mouse Y position
---@param button number Mouse button
function UIBox:handleMouseReleased(x, y, button)
    self:sortElements()
    
    -- Process elements in reverse order (top-most first for input)
    for i = #self.elements, 1, -1 do
        local element = self.elements[i]
        if element.isInteractive and element.visible then
            element:onMouseReleased(x, y, button)
        end
    end
end

---Handle mouse move events
---@param x number Mouse X position
---@param y number Mouse Y position
function UIBox:handleMouseMoved(x, y)
    self:sortElements()
    
    -- Update hover state for all interactive elements
    for _, element in ipairs(self.elements) do
        if element.isInteractive and element.visible then
            local wasHovered = element.isHovered
            element.isHovered = element:contains(x, y)
            
            -- Call hover callback if state changed
            if wasHovered ~= element.isHovered and element.hoverCallbackName then
                _G.Game.CallbackManager:execute(element.hoverCallbackName, element, element.isHovered, element.callbackArgs)
            end
        end
    end
end

function UIBox:draw_background()
    local color = self.background.color
    love.graphics.setColor(color[1], color[2], color[3], color[4])
    love.graphics.rectangle(self.background.drawMode, 0, 0, self.width, self.height)
    love.graphics.setColor(1, 1, 1, 1)
end

---Resize the UIBox and its elements
---@param width number New width
---@param height number New height
function UIBox:resize(width, height)
    self.width = width
    self.height = height
    -- Elements should handle their own resizing if needed
end

function UIBox:draw()
    self:draw_background()
    for _, element in ipairs(self.elements) do
        if element.visible and element.draw_self then
            element:draw_self()
        end
    end
end

---@class UIElement : Transformable
---@field elementName string The name of the element
---@field zIndex number Z-index for rendering order
---@field visible boolean Whether the element is visible
---@field color number[] Base color {r,g,b,a}
---@field drawMode string "fill" or "line"
---@field text string? Optional text to display
---@field fontSize number? Optional text size (creates font automatically)
---@field font love.Font Font to use for text
---@field textColor number[] Text color {r,g,b,a}
---@field isHovered boolean Current hover state
---@field isPressed boolean Current pressed state
---@field isInteractive boolean Whether this element can be interacted with
---@field hoverColor number[]? Optional color when hovered
---@field pressColor number[]? Optional color when pressed
---@field callbackName string? Main callback name (usually for clicks)
---@field hoverCallbackName string? Callback name for hover events
---@field pressCallbackName string? Callback name for press events
---@field releaseCallbackName string? Callback name for release events
---@field onDraw function? Custom draw function
UIElement = Transformable:extend()

---@param properties table? Optional properties table
function UIElement:init(properties)
    -- Initialize transformable properties
    Transformable.init(self, "UIElement", properties)
    
    -- Basic properties
    self.elementName = properties and properties.elementName or "DefaultElementName"
    self.zIndex = properties and properties.zIndex or 0
    self.visible = properties and properties.visible ~= nil and properties.visible or true
    
    -- Visual properties
    self.color = properties and properties.color or {1, 1, 1, 1}
    self.drawMode = properties and properties.drawMode or "fill" -- "fill" or "line"
    self.text = properties and properties.text
    self.background = properties and properties.background or _G.Game.CONSTANTS.UI.DEFAULT_BACKGROUND
    
    -- Font handling - create font from size if provided, otherwise use provided font or default
    if properties and properties.fontSize then
        self.fontSize = properties.fontSize
        self.font = love.graphics.newFont(self.fontSize)
    else
        self.fontSize = nil
        self.font = properties and properties.font or love.graphics.getFont()
    end
    
    self.textColor = properties and properties.textColor or {0, 0, 0, 1}
    
    -- Interactive state
    self.isHovered = false
    self.isPressed = false
    
    -- Interaction colors
    self.hoverColor = properties and properties.hoverColor
    self.pressColor = properties and properties.pressColor
    
    -- Callback names for CallbackManager
    self.callbackName = properties and properties.callbackName -- Main callback (usually click)
    self.hoverCallbackName = properties and properties.hoverCallbackName
    self.pressCallbackName = properties and properties.pressCallbackName
    self.releaseCallbackName = properties and properties.releaseCallbackName
    self.callbackArgs = properties and properties.callbackArgs

    -- Set interactive flag if any callbacks are defined
    self.isInteractive = (self.callbackName ~= nil) or (self.hoverCallbackName ~= nil) or 
                        (self.pressCallbackName ~= nil) or (self.releaseCallbackName ~= nil)
    
    -- Custom draw function
    self.onDraw = properties and properties.onDraw
end

---Handle mouse press events
---@param x number Mouse X position
---@param y number Mouse Y position
---@param button number Mouse button (1=left, 2=right, 3=middle)
function UIElement:onMousePressed(x, y, button)
    if not self.isInteractive or not self.visible then return end
    
    if button == 1 then -- Left mouse button
        self.isPressed = true
        if self.pressCallbackName then
            _G.Game.CallbackManager:execute(self.pressCallbackName, self, self.callbackArgs)
        end
    end
end

---Handle mouse release events
---@param x number Mouse X position
---@param y number Mouse Y position
---@param button number Mouse button (1=left, 2=right, 3=middle)
function UIElement:onMouseReleased(x, y, button)
    if not self.isInteractive or not self.visible then return end
    
    if button == 1 then -- Left mouse button
        local wasPressed = self.isPressed
        self.isPressed = false
        
        -- Call release callback if element was pressed
        if wasPressed and self.releaseCallbackName then
            _G.Game.CallbackManager:execute(self.releaseCallbackName, self, self.callbackArgs)
        end
        
        -- Call main callback if element was clicked (pressed and released on same element)
        if wasPressed and self:contains(x, y) and self.callbackName then
            _G.Game.CallbackManager:execute(self.callbackName, self, self.callbackArgs)
        end
    end
end

---Set the font size and create a new font
---@param size number The new font size
function UIElement:setFontSize(size)
    self.fontSize = size
    self.font = love.graphics.newFont(size)
end

function UIElement:update(dt)
    -- No default update behavior
    if self.elementName == "DefaultElementName" then
        print("Element with default name detected, please set the elementName property, else updates wont be possible")
    end
end

function UIElement:draw_self()
    if not self.visible then return end
    
    if self.onDraw then
        -- Custom draw function
        self:onDraw()
    else
        -- Draw background if specified and not 'none'
        if self.background and self.background.drawMode ~= "none" then
            local bgColor = self.background.color or {1, 1, 1, 1}
            love.graphics.setColor(bgColor[1], bgColor[2], bgColor[3], bgColor[4])
            local x, y = self:getRenderPosition()
            love.graphics.rectangle(string.lower(self.background.drawMode), x, y, self.width, self.height)
        end
        -- Choose color based on state
        local currentColor = self.color
        if self.isPressed and self.pressColor then
            currentColor = self.pressColor
        elseif self.isHovered and self.hoverColor then
            currentColor = self.hoverColor
        end
        -- Draw text if provided
        if self.text and self.textColor then
            love.graphics.setColor(self.textColor[1], self.textColor[2], self.textColor[3], self.textColor[4])
            love.graphics.setFont(self.font)  -- Set the font before using it
            local textWidth = self.font:getWidth(self.text)
            local textHeight = self.font:getHeight()
            local x, y = self:getRenderPosition()
            local textX = x + (self.width - textWidth) / 2
            local textY = y + (self.height - textHeight) / 2
            love.graphics.print(self.text, textX, textY)
        end
    end
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end
