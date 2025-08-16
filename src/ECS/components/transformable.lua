---@class Transformable : Object
---@field name string Name of the transformable object
---@field x number X position
---@field y number Y position
---@field width number Width
---@field height number Height
---@field rotation number Rotation in radians
---@field scaleX number X scale factor
---@field scaleY number Y scale factor
---@field pivotX number X pivot point (0-1)
---@field pivotY number Y pivot point (0-1)
Transformable = Object:extend()

---Initialize a new Transformable object
---@param name string Name of the transformable
---@param properties table? Optional properties table
function Transformable:init(name, properties)
    self.name = name
    
    -- Initialize with zeros if no properties provided
    self.x = 0
    self.y = 0
    self.width = 0
    self.height = 0
    self.rotation = 0
    self.scaleX = 1
    self.scaleY = 1
    
    -- Add pivot/anchor properties (0,0 is top-left, 0.5,0.5 is center)
    self.pivotX = 0.5
    self.pivotY = 0.5
    
    -- Set properties if they were provided
    if properties then
        if properties.x then self.x = properties.x end
        if properties.y then self.y = properties.y end
        if properties.width then self.width = properties.width end
        if properties.height then self.height = properties.height end
        if properties.rotation then self.rotation = properties.rotation end
        if properties.scaleX then self.scaleX = properties.scaleX end
        if properties.scaleY then self.scaleY = properties.scaleY end
        if properties.pivotX then self.pivotX = properties.pivotX end
        if properties.pivotY then self.pivotY = properties.pivotY end
    end
end

---Get the bounding box of the transformable (simplified, ignores rotation/scale)
---@return number x, number y, number width, number height
function Transformable:getBounds()
    local offsetX = self.width * self.pivotX
    local offsetY = self.height * self.pivotY
    return self.x - offsetX, self.y - offsetY, self.width, self.height
end

---Set the position of the transformable
---@param x number X position
---@param y number Y position
function Transformable:setPosition(x, y)
    self.x = x
    self.y = y
end

---Set the size of the transformable
---@param width number Width
---@param height number Height
function Transformable:setSize(width, height)
    self.width = width
    self.height = height
end

---Set the rotation of the transformable
---@param rotation number Rotation in radians
function Transformable:setRotation(rotation)
    self.rotation = rotation
end

---Set the scale of the transformable
---@param sx number X scale factor
---@param sy? number Y scale factor (optional, uses sx if not provided)
function Transformable:setScale(sx, sy)
    self.scaleX = sx
    self.scaleY = sy or sx -- If only one value provided, make uniform scale
end

---Set the pivot/anchor point (0,0 is top-left, 0.5,0.5 is center, 1,1 is bottom-right)
---@param px number X pivot point (0-1)
---@param py? number Y pivot point (0-1, optional, uses px if not provided)
function Transformable:setPivot(px, py)
    self.pivotX = px
    self.pivotY = py or px -- If only one value provided, use same for both axes
end

---Translate the transformable by a delta amount
---@param dx? number X delta (optional)
---@param dy? number Y delta (optional)
function Transformable:translate(dx, dy)
    self.x = self.x + (dx or 0)
    self.y = self.y + (dy or 0)
end

---Check if a point is inside the transformable's bounds
---@param px number Point X coordinate
---@param py number Point Y coordinate
---@return boolean inside True if point is inside bounds
function Transformable:contains(px, py)
    local offsetX = self.width * self.pivotX
    local offsetY = self.height * self.pivotY
    local x = self.x - offsetX
    local y = self.y - offsetY
    
    return px >= x and px <= x + self.width and 
           py >= y and py <= y + self.height
end

---Get the actual rendering position considering pivot point
---@return number x, number y The render position coordinates
function Transformable:getRenderPosition()
    return self.x - (self.width * self.pivotX), 
           self.y - (self.height * self.pivotY)
end

return Transformable