---@class Shield : Object
---@field name string
---@field angle number
---@field arc number
---@field max number
---@field current number
Shield = Object:extend()

function Shield:init(properties)
    self.name = "shield"
    self.angle = (properties and properties.angle) or 0 -- degrees
    self.arc = (properties and properties.arc) or 120    -- degrees of coverage
    self.max = (properties and properties.max) or 20
    self.current = (properties and properties.current) or self.max
end

return Shield


