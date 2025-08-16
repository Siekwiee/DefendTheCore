---@class Combat : Object
---@field name string
---@field hp number
---@field maxHp number
---@field contactDamage number
---@field damageType string
---@field faction string
---@field diesOnHit boolean
---@field isCore boolean
Combat = Object:extend()

function Combat:init(properties)
	self.name = "combat"
	self.maxHp = (properties and properties.maxHp) or 1
	self.hp = (properties and properties.hp) or self.maxHp
	self.contactDamage = (properties and properties.contactDamage) or 0
	self.damageType = (properties and properties.damageType) or "kinetic"
	self.faction = (properties and properties.faction) or "neutral"
	self.diesOnHit = (properties and properties.diesOnHit) or false
	self.isCore = (properties and properties.isCore) or false
end

return Combat


