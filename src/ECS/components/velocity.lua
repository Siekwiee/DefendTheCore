---@class Velocity : Object
---@field name string
---@field vx number
---@field vy number
Velocity = Object:extend()

function Velocity:init(properties)
	self.name = "velocity"
	self.vx = (properties and properties.vx) or 0
	self.vy = (properties and properties.vy) or 0
end

return Velocity


