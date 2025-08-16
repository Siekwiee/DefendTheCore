---@class Enemy : Object
---@field name string
---@field kind string
Enemy = Object:extend()

function Enemy:init(properties)
	self.name = "enemy"
	self.kind = (properties and properties.kind) or "runner"
end

return Enemy


