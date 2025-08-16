-- this component checks the clicked area for any entities with this component if the mouse is clicked on the entity it will call the OnClick function

---@class Clickable : Object
---@field onClick fun()
---@field onHover fun()
---@field onUnhover fun()
---@field onPress fun()
---@field onRelease fun()
---@field bounds table
---@field enabled boolean
---@field clickTolerance number
---@field pressStartX number
---@field pressStartY number
---@field isPressed boolean
---@field isHovered boolean
local Clickable = Object:extend()

---@class ClickableOptions
---@field onClick fun()
---@field onHover fun()
---@field onUnhover fun()
---@field onPress fun()
---@field onRelease fun()
local ClickableOptions = {
    onClick = function() end,
    onHover = function() end,
    onUnhover = function() end,
    onPress = function() end,
    onRelease = function() end
}

---@param options ClickableOptions
function Clickable:init(options)
    options = options or {}
    
    self.onClick = options.onClick or function() end
    self.onHover = options.onHover or function() end
    self.onUnhover = options.onUnhover or function() end
    self.onPress = options.onPress or function() end
    self.onRelease = options.onRelease or function() end
    
    -- Set component name
    self.name = "clickable"
    -- Set default bounds (will be updated from Transform)
    self.bounds = {x = 0, y = 0, width = 0, height = 0}
    -- Enable by default
    self.enabled = true
    
    -- Click tolerance and tracking
    self.clickTolerance = 5 -- Reduced from 10 to minimize issues
    self.pressStartX = nil
    self.pressStartY = nil
    self.isPressed = false
    self.isHovered = false
end

---@param x number
---@param y number
function Clickable:isPointInside(x, y)
    return x >= self.bounds.x and x <= self.bounds.x + self.bounds.width and
           y >= self.bounds.y and y <= self.bounds.y + self.bounds.height
end

---@param enabled boolean
function Clickable:setEnabled(enabled)
    self.enabled = enabled
end

---@param x number
---@param y number
---@param width number
---@param height number
function Clickable:setBounds(x, y, width, height)
    self.bounds = {
        x = x,
        y = y,
        width = width,
        height = height
    }
end

---@param dt number
---@param entity Entity
function Clickable:update(dt, entity)
    if not self.enabled then return end
    
    -- Update bounds from Transform if available
    local transform = entity:getComponent("Transform")
    if transform then
        local x, y, w, h = transform:getBounds()
        self:setBounds(x, y, w, h)
    end
    
    -- Process any state changes needed during update
    local mx, my = love.mouse.getPosition()
    
    -- Track previous states to detect changes
    local wasHovered = self.isHovered
    local wasPressed = self.isPressed
    
    -- Update hover state
    self.isHovered = self:isPointInside(mx, my)
    
    -- Handle hover state changes
    if self.isHovered and not wasHovered then
        self.onHover()
    elseif not self.isHovered and wasHovered then
        self.onUnhover()
    end
    
    -- Handle press state changes
    if self.isPressed and not love.mouse.isDown(1) then
        self.isPressed = false
        self.onRelease()
        
        -- Use tolerance-based click detection
        if self.pressStartX and self.pressStartY then
            local dx = mx - self.pressStartX
            local dy = my - self.pressStartY
            local distance = math.sqrt(dx * dx + dy * dy)
            
            -- Allow click if within tolerance OR if still inside bounds
            if distance <= self.clickTolerance or self.isHovered then
                self.onClick()
            end
        end
        
        -- Reset press tracking
        self.pressStartX = nil
        self.pressStartY = nil
    end
end

---@param x number
---@param y number
---@param button number
function Clickable:mousePressed(x, y, button)
    if not self.enabled then return false end
    
    if button == 1 and self:isPointInside(x, y) then
        self.isPressed = true
        self.pressStartX = x
        self.pressStartY = y
        self.onPress()
        return true
    end
    
    return false
end

---@param x number
---@param y number
---@param button number
function Clickable:mouseReleased(x, y, button)
    if not self.enabled or not self.isPressed then return false end
    
    self.isPressed = false
    self.onRelease()
    
    if button == 1 and self.pressStartX and self.pressStartY then
        -- Calculate distance from initial press position
        local dx = x - self.pressStartX
        local dy = y - self.pressStartY
        local distance = math.sqrt(dx * dx + dy * dy)
        
        -- Allow click if within tolerance OR if still inside bounds
        if distance <= self.clickTolerance or self:isPointInside(x, y) then
            self.onClick()
            
            -- Reset press tracking
            self.pressStartX = nil
            self.pressStartY = nil
            return true
        end
    end
    
    -- Reset press tracking on failed click
    self.pressStartX = nil
    self.pressStartY = nil
    return false
end

---@param x number
---@param y number
function Clickable:mouseMoved(x, y)
    if not self.enabled then 
        if self.isHovered then
            self.isHovered = false
            self.onUnhover()
        end
        return false 
    end
    
    local wasHovered = self.isHovered
    self.isHovered = self:isPointInside(x, y)
    
    if self.isHovered and not wasHovered then
        self.onHover()
        return true
    elseif not self.isHovered and wasHovered then
        self.onUnhover()
        return true
    end
    
    return self.isHovered
end

---@param entity Entity
---@param mx number
---@param my number
function Clickable:isInside(entity, mx, my)
    local transform = entity:getComponent("Transform")
    if not transform then
        return false
    end

    -- Simple AABB check (Axis-Aligned Bounding Box)
    -- Ignores rotation and scaling for simplicity. Add that logic if needed.
    local x, y, w, h = transform:getBounds()
    return mx >= x and mx <= x + w and my >= y and my <= y + h
end

return Clickable
