---@class Transform : Object
---@field name string
---@field x number
---@field y number
Transform = Object:extend()

function Transform:init(properties)
	self.name = "transform"
	self.x = (properties and properties.x) or 0
	self.y = (properties and properties.y) or 0
end

return Transform


