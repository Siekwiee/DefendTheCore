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
---@field focusableElements UIElement[] List of focusable elements in creation order
---@field needsSort boolean Z-index sorting flag
---@field inputListeners table Event listener functions that need to be cleaned up
---@field focusedIndex integer? Index of currently focused focusable element in focusableElements
---@field tooltipElement UIElement? Currently active tooltip element
UIBox = Transformable:extend()

---@param properties table? Optional properties table
function UIBox:init(properties)
    -- Initialize transformable properties
    Transformable.init(self, "UIBox", properties)
    
    -- List of UI elements managed by this box
    self.elements = {}
    -- List of focusable elements in creation order (for navigation)
    self.focusableElements = {}
    -- Z-index sorting for elements
    self.needsSort = false
    -- Track input listeners for cleanup
    self.inputListeners = {}
    -- Keyboard focus handling
    self.focusedIndex = nil
    -- Tooltip handling
    self.tooltipElement = nil

    -- Background of UIBox
    if properties and properties.background then
        self.background = properties.background
    else
        self.background = {
            color = {0.5, 0.0, 0.5, 1}, -- Purple background as default because then something is missing and purple is recognized as a missing texture
            drawMode = "fill" -- "fill" or "line"
        }
    end

    -- Do not auto-register input listeners here; states attach on enter()
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
    -- Key press handler
    local keyPressedHandler = function(eventData)
        self:handleKeyPressed(eventData.key)
    end
    
    -- Register listeners
    _G.Game.InputManager:addEventListener("mousepressed", mousePressedHandler)
    _G.Game.InputManager:addEventListener("mousereleased", mouseReleasedHandler)
    _G.Game.InputManager:addEventListener("mousemoved", mouseMovedHandler)
    _G.Game.InputManager:addEventListener("keypressed", keyPressedHandler)
    
    -- Store references for cleanup
    self.inputListeners.mousepressed = mousePressedHandler
    self.inputListeners.mousereleased = mouseReleasedHandler
    self.inputListeners.mousemoved = mouseMovedHandler
    self.inputListeners.keypressed = keyPressedHandler
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
    if self.inputListeners.keypressed then
        _G.Game.InputManager:removeEventListener("keypressed", self.inputListeners.keypressed)
    end
    self.inputListeners = {}
end

function UIBox:addElement(element)
    table.insert(self.elements, element)
    -- Add to focusable elements list if it's focusable
    if element.isFocusable then
        table.insert(self.focusableElements, element)
    end
    self.needsSort = true
end

function UIBox:removeElement(element)
    for i, e in ipairs(self.elements) do
        if e == element then
            table.remove(self.elements, i)
            break
        end
    end
    -- Also remove from focusable elements
    for i, e in ipairs(self.focusableElements) do
        if e == element then
            table.remove(self.focusableElements, i)
            break
        end
    end
end

---Clear all elements from this UIBox
function UIBox:clear()
    self.elements = {}
    self.focusableElements = {}
    self.focusedIndex = nil
    self.needsSort = false
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
    
    -- Determine tooltip element (top-most hovered with ready tooltip)
    self.tooltipElement = nil
    for i = #self.elements, 1, -1 do
        local element = self.elements[i]
        if element.visible and element.isInteractive and element.isHovered and element.isTooltipReady and element:isTooltipReady() then
            self.tooltipElement = element
            break
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
        if element:contains(x, y) and element.isInteractive and element.visible and element.enabled ~= false then
            element:onMousePressed(x, y, button)
            if element.isFocusable then
                -- Find the index in focusableElements array
                for focusIndex, focusElement in ipairs(self.focusableElements) do
                    if focusElement == element then
                        self:setFocusByIndex(focusIndex)
                        break
                    end
                end
            end
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
        if element and element.isInteractive and element.visible then
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

---Handle key press events for focus navigation and activation
---@param key string
function UIBox:handleKeyPressed(key)
    if key == "tab" then
        self:focusNext()
    elseif key == "up" or key == "left" then
        self:focusPrevious()
    elseif key == "down" or key == "right" then
        self:focusNext()
    elseif key == "return" or key == "space" then
        local element = self:getFocusedElement()
        if element and element.isInteractive and element.enabled ~= false and element.callbackName then
            _G.Game.CallbackManager:execute(element.callbackName, element, element.callbackArgs)
        end
    end
end

---Get element by name
---@param elementName string
---@return UIElement|nil
function UIBox:getElementByName(elementName)
    for _, element in ipairs(self.elements) do
        if element.elementName == elementName then
            return element
        end
    end
    return nil
end



---Set focus by element index in focusableElements array
---@param index integer
function UIBox:setFocusByIndex(index)
    if index < 1 or index > #self.focusableElements then return end
    local element = self.focusableElements[index]
    if not element or not element.isFocusable or element.visible == false then return end
    local previous = self:getFocusedElement()
    if previous then
        previous.isFocused = false
        if previous.blurCallbackName then
            _G.Game.CallbackManager:execute(previous.blurCallbackName, previous, previous.callbackArgs)
        end
    end
    self.focusedIndex = index
    element.isFocused = true
    if element.focusCallbackName then
        _G.Game.CallbackManager:execute(element.focusCallbackName, element, element.callbackArgs)
    end
end

---Get the currently focused element
---@return UIElement|nil
function UIBox:getFocusedElement()
    if not self.focusedIndex then return nil end
    return self.focusableElements[self.focusedIndex]
end

---Focus the next focusable element
function UIBox:focusNext()
    if #self.focusableElements == 0 then return end
    local start = self.focusedIndex or 0
    for offset = 1, #self.focusableElements do
        local i = ((start + offset - 1) % #self.focusableElements) + 1
        local e = self.focusableElements[i]
        if e.visible and e.isFocusable and (e.enabled ~= false) then
            self:setFocusByIndex(i)
            return
        end
    end
end

---Focus the previous focusable element
function UIBox:focusPrevious()
    if #self.focusableElements == 0 then return end
    local start = self.focusedIndex or 1
    for offset = 1, #self.focusableElements do
        -- Fix negative modulo arithmetic for proper backward navigation
        local i = ((start - offset - 1 + #self.focusableElements) % #self.focusableElements) + 1
        local e = self.focusableElements[i]
        if e.visible and e.isFocusable and (e.enabled ~= false) then
            self:setFocusByIndex(i)
            return
        end
    end
end

function UIBox:draw_background()
    local color = self.background.color
    local mode = self.background.drawMode
    if mode ~= "none" then
        love.graphics.setColor(color[1], color[2], color[3], color[4])
        love.graphics.rectangle(mode, 0, 0, self.width, self.height)
        love.graphics.setColor(1, 1, 1, 1)
    end
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
    if self.tooltipElement then
        self:draw_tooltip(self.tooltipElement)
    end
end

---Draw tooltip for the given element near the mouse
---@param element UIElement
function UIBox:draw_tooltip(element)
    local text = element.tooltipText
    if not text or text == "" then return end
    local mx, my = _G.Game.InputManager:getMousePosition()
    local padding = 8
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(text)
    local textHeight = font:getHeight()
    local boxWidth = textWidth + padding * 2
    local boxHeight = textHeight + padding * 2
    local x = math.min(mx + 16, (self.width or love.graphics.getWidth()) - boxWidth - 8)
    local y = math.min(my + 16, (self.height or love.graphics.getHeight()) - boxHeight - 8)
    love.graphics.setColor(0, 0, 0, 0.85)
    love.graphics.rectangle("fill", x, y, boxWidth, boxHeight)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("line", x + 0.5, y + 0.5, boxWidth - 1, boxHeight - 1)
    love.graphics.printf(text, x + padding, y + padding, textWidth, "left")
    love.graphics.setColor(1, 1, 1, 1)
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
---@field enabled boolean Whether the element is enabled for interaction
---@field isFocusable boolean Whether the element can receive keyboard focus
---@field isFocused boolean Whether the element is currently focused
---@field focusCallbackName string? Callback name when focused
---@field blurCallbackName string? Callback name when focus is lost
---@field focusOutlineColor number[]? Outline color when focused
---@field tooltipText string? Tooltip text to show on hover
---@field tooltipDelay number? Time in seconds before showing tooltip
---@field hoverTime number Accumulated hover time
---@field textAlign string Horizontal text alignment: "left"|"center"|"right"
---@field textVAlign string Vertical text alignment: "top"|"middle"|"bottom"
---@field wrap boolean Whether to wrap text within width
---@field padding table Padding table {l,t,r,b}
UIElement = Transformable:extend()

---@param properties table? Optional properties table
function UIElement:init(properties)
    -- Initialize transformable properties
    Transformable.init(self, "UIElement", properties)
    
    -- Basic properties
    self.elementName = properties and properties.elementName or "DefaultElementName"
    self.zIndex = properties and properties.zIndex or 0
    self.visible = properties and (properties.visible ~= nil) and properties.visible or true
    
    -- Visual properties
    self.color = properties and properties.color or {1, 1, 1, 1}
    self.drawMode = properties and properties.drawMode or "fill" -- "fill" or "line"
    self.text = properties and properties.text
    self.background = properties and properties.background or
                      (_G.Game and _G.Game.CONSTANTS and _G.Game.CONSTANTS.UI and _G.Game.CONSTANTS.UI.DEFAULT_BACKGROUND) or
                      { color = {0, 0, 0, 0}, drawMode = "none" }
    
    -- Font handling - create font from size if provided, otherwise use provided font or default
    if properties and properties.fontSize then
        self.fontSize = properties.fontSize
        self.font = love.graphics.newFont(self.fontSize)
    else
        self.fontSize = nil
        self.font = properties and properties.font or love.graphics.getFont()
    end
    
    self.textColor = properties and properties.textColor or {0, 0, 0, 1}
    self.textAlign = properties and properties.textAlign or "center"
    self.textVAlign = properties and properties.textVAlign or "middle"
    self.wrap = properties and properties.wrap or false
    self.padding = properties and properties.padding or {l = 0, t = 0, r = 0, b = 0}
    
    -- Interactive state
    self.isHovered = false
    self.isPressed = false
    self.isFocused = false
    self.enabled = properties and (properties.enabled ~= nil) and properties.enabled or true
    self.isFocusable = properties and (properties.isFocusable ~= nil) and properties.isFocusable or false
    
    -- Interaction colors
    self.hoverColor = properties and properties.hoverColor
    self.pressColor = properties and properties.pressColor
    self.focusOutlineColor = properties and properties.focusOutlineColor or {1, 1, 1, 0.5}
    
    -- Callback names for CallbackManager
    self.callbackName = properties and properties.callbackName -- Main callback (usually click)
    self.hoverCallbackName = properties and properties.hoverCallbackName
    self.pressCallbackName = properties and properties.pressCallbackName
    self.releaseCallbackName = properties and properties.releaseCallbackName
    self.callbackArgs = properties and properties.callbackArgs
    self.focusCallbackName = properties and properties.focusCallbackName
    self.blurCallbackName = properties and properties.blurCallbackName

    -- Tooltip
    self.tooltipText = properties and properties.tooltipText
    self.tooltipDelay = properties and properties.tooltipDelay or 0.6
    self.hoverTime = 0

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
    if not self.isInteractive or not self.visible or not self.enabled then return end
    
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
    if not self.isInteractive or not self.visible or not self.enabled then return end
    
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
    if self.isHovered then
        self.hoverTime = self.hoverTime + dt
    else
        self.hoverTime = 0
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
            local alpha = (self.enabled and 1) or 0.5
            love.graphics.setColor(bgColor[1], bgColor[2], bgColor[3], (bgColor[4] or 1) * alpha)
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
        -- Draw focus outline if focused
        if self.isFocused then
            local x, y = self:getRenderPosition()
            love.graphics.setColor(self.focusOutlineColor[1], self.focusOutlineColor[2], self.focusOutlineColor[3], self.focusOutlineColor[4])
            love.graphics.rectangle("line", x + 1.5, y + 1.5, self.width - 3, self.height - 3)
        end
        -- Draw text if provided
        if self.text and self.textColor then
            local alpha = (self.enabled and 1) or 0.6
            love.graphics.setColor(self.textColor[1], self.textColor[2], self.textColor[3], (self.textColor[4] or 1) * alpha)
            love.graphics.setFont(self.font)
            local x, y = self:getRenderPosition()
            local innerX = x + (self.padding.l or 0)
            local innerY = y + (self.padding.t or 0)
            local innerW = self.width - (self.padding.l or 0) - (self.padding.r or 0)
            local innerH = self.height - (self.padding.t or 0) - (self.padding.b or 0)
            if self.wrap then
                local align = self.textAlign
                love.graphics.printf(self.text, innerX, innerY + self:_computeVerticalOffset(innerH), innerW, align)
            else
                local textWidth = self.font:getWidth(self.text)
                local textHeight = self.font:getHeight()
                local tx = innerX
                if self.textAlign == "center" then
                    tx = innerX + (innerW - textWidth) / 2
                elseif self.textAlign == "right" then
                    tx = innerX + (innerW - textWidth)
                end
                local ty = innerY
                if self.textVAlign == "middle" then
                    ty = innerY + (innerH - textHeight) / 2
                elseif self.textVAlign == "bottom" then
                    ty = innerY + (innerH - textHeight)
                end
                love.graphics.print(self.text, tx, ty)
            end
        end
    end
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

---Compute vertical offset for wrapped text
---@param innerH number
function UIElement:_computeVerticalOffset(innerH)
    if self.textVAlign == "top" then return 0 end
    local lineHeight = self.font:getHeight() * self.font:getLineHeight()
    local ty = 0
    if self.textVAlign == "middle" then
        ty = (innerH - lineHeight) / 2
    elseif self.textVAlign == "bottom" then
        ty = innerH - lineHeight
    end
    return ty
end

---Set the displayed text
---@param text string
function UIElement:setText(text)
    self.text = text
end

---Enable/disable the element
---@param enabled boolean
function UIElement:setEnabled(enabled)
    self.enabled = enabled
end

---Show/hide the element
---@param visible boolean
function UIElement:setVisible(visible)
    self.visible = visible
end

---Whether the tooltip is ready to be shown
---@return boolean
function UIElement:isTooltipReady()
    return self.isHovered and self.tooltipText ~= nil and self.hoverTime >= (self.tooltipDelay or 0)
end

---@class UIToast : Object
---@field message string The toast message text
---@field duration number How long the toast should be visible
---@field fadeInTime number Time to fade in
---@field fadeOutTime number Time to fade out
---@field totalTime number Total time the toast has been alive
---@field alpha number Current alpha for fade animations
---@field x number X position
---@field y number Y position
---@field width number Toast width
---@field height number Toast height
---@field backgroundColor table Background color {r,g,b,a}
---@field textColor table Text color {r,g,b,a}
---@field font love.Font Font for the text
---@field isVisible boolean Whether the toast is currently visible
UIToast = Object:extend()

function UIToast:init(message, duration, x, y)
    self.message = message or "Notification"
    self.duration = duration or 3.0
    self.fadeInTime = 0.3
    self.fadeOutTime = 0.5
    self.totalTime = 0
    self.alpha = 0

    -- Colors matching the game's style
    self.backgroundColor = {0.09, 0.10, 0.14, 0.95}
    self.textColor = {1, 1, 1, 1}
    self.borderColor = {0.22, 0.25, 0.32, 1}

    -- Font
    self.font = love.graphics.newFont(16)

    -- Calculate dynamic size based on text content
    self:calculateSize()

    -- Positioning (default to top-right, adjusted for dynamic width)
    self.x = x or (love.graphics.getWidth() - self.width - 20)
    self.y = y or 60

    self.isVisible = true
end

---Calculate the optimal size for the toast based on text content
function UIToast:calculateSize()
    local padding = 24 -- Horizontal padding (12px on each side)
    local verticalPadding = 16 -- Vertical padding (8px on each side)
    local maxWidth = love.graphics.getWidth() * 0.4 -- Max 40% of screen width
    local minWidth = 200 -- Minimum width for consistency

    -- Get text dimensions
    local textWidth = self.font:getWidth(self.message)
    local lineHeight = self.font:getHeight()

    -- Calculate width
    if textWidth + padding <= maxWidth then
        -- Text fits in one line
        self.width = math.max(minWidth, textWidth + padding)
        self.height = lineHeight + verticalPadding
        self.wrappedText = self.message
        self.lineCount = 1
    else
        -- Text needs to be wrapped
        self.width = maxWidth
        local availableWidth = maxWidth - padding

        -- Calculate wrapped text and line count
        self.wrappedText = self.message
        local _, wrappedLines = self.font:getWrap(self.message, availableWidth)
        self.lineCount = #wrappedLines
        self.height = (lineHeight * self.lineCount) + verticalPadding
    end
end

function UIToast:update(dt)
    if not self.isVisible then return end

    self.totalTime = self.totalTime + dt

    -- Calculate alpha based on fade phases
    if self.totalTime < self.fadeInTime then
        -- Fade in
        self.alpha = self.totalTime / self.fadeInTime
    elseif self.totalTime < (self.duration - self.fadeOutTime) then
        -- Fully visible
        self.alpha = 1.0
    elseif self.totalTime < self.duration then
        -- Fade out
        local fadeProgress = (self.totalTime - (self.duration - self.fadeOutTime)) / self.fadeOutTime
        self.alpha = 1.0 - fadeProgress
    else
        -- Expired
        self.alpha = 0
        self.isVisible = false
    end
end

function UIToast:draw()
    if not self.isVisible or self.alpha <= 0 then return end

    -- Save current color
    local r, g, b, a = love.graphics.getColor()
    local currentFont = love.graphics.getFont()

    -- Draw background with alpha
    love.graphics.setColor(
        self.backgroundColor[1],
        self.backgroundColor[2],
        self.backgroundColor[3],
        self.backgroundColor[4] * self.alpha
    )
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 8, 8)

    -- Draw border
    love.graphics.setColor(
        self.borderColor[1],
        self.borderColor[2],
        self.borderColor[3],
        self.borderColor[4] * self.alpha
    )
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height, 8, 8)

    -- Draw text
    love.graphics.setFont(self.font)
    love.graphics.setColor(
        self.textColor[1],
        self.textColor[2],
        self.textColor[3],
        self.textColor[4] * self.alpha
    )

    -- Position text with proper padding and vertical centering
    local textX = self.x + 12
    local lineHeight = self.font:getHeight()
    local totalTextHeight = lineHeight * self.lineCount
    local textY = self.y + (self.height - totalTextHeight) / 2

    -- Use printf for proper text wrapping if needed
    if self.lineCount > 1 then
        local availableWidth = self.width - 24 -- Account for padding
        love.graphics.printf(self.wrappedText, textX, textY, availableWidth, "left")
    else
        love.graphics.print(self.wrappedText, textX, textY)
    end

    -- Restore previous state
    love.graphics.setColor(r, g, b, a)
    love.graphics.setFont(currentFont)
    love.graphics.setLineWidth(1)
end

function UIToast:isExpired()
    return not self.isVisible
end

function UIToast:setPosition(x, y)
    self.x = x
    self.y = y
end

---@class UIToastManager : Object
---@field toasts UIToast[] Queue of active toasts
---@field spacing number Vertical spacing between toasts
---@field baseX number Base X position for toasts
---@field baseY number Base Y position for toasts
UIToastManager = Object:extend()

function UIToastManager:init()
    self.toasts = {}
    self.spacing = 10 -- Reduced spacing since toasts are now variable height
    self.baseY = 60
end

function UIToastManager:addToast(message, duration)
    -- Create toast with temporary position, it will be repositioned
    local toast = UIToast(message, duration, 0, self.baseY)
    table.insert(self.toasts, toast)
    self:repositionToasts()
    return toast
end

function UIToastManager:update(dt)
    -- Update all toasts
    for i = #self.toasts, 1, -1 do
        local toast = self.toasts[i]
        toast:update(dt)

        -- Remove expired toasts
        if toast:isExpired() then
            table.remove(self.toasts, i)
        end
    end

    -- Reposition remaining toasts
    self:repositionToasts()
end

function UIToastManager:repositionToasts()
    local currentY = self.baseY

    for i, toast in ipairs(self.toasts) do
        -- Position each toast at the right edge, accounting for its width
        local targetX = love.graphics.getWidth() - toast.width - 20
        toast:setPosition(targetX, currentY)

        -- Move down by this toast's height plus spacing for the next toast
        currentY = currentY + toast.height + self.spacing
    end
end

function UIToastManager:draw()
    for _, toast in ipairs(self.toasts) do
        toast:draw()
    end
end

function UIToastManager:clear()
    self.toasts = {}
end

function UIToastManager:resize(width, height)
    -- Recalculate sizes for all existing toasts in case screen size affects max width
    for _, toast in ipairs(self.toasts) do
        toast:calculateSize()
    end
    self:repositionToasts()
end
