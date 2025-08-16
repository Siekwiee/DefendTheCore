---@class CircleCollider : Object
---@field name string
---@field radius number
---@field isTrigger boolean
---@field mask string
CircleCollider = Object:extend()

function CircleCollider:init(properties)
	self.name = "circle_collider"
	self.radius = (properties and properties.radius) or 8
	self.isTrigger = (properties and properties.isTrigger) or false
	self.mask = (properties and properties.mask) or "generic"
end

return CircleCollider


