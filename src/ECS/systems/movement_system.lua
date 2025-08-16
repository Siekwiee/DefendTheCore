local System = require "src.ECS.System"

MovementSystem = System:extend("MovementSystem")

function MovementSystem:init()
	System.init(self)
	self:requireAll("transform", "velocity")
end

function MovementSystem:update(dt)
	for _, entity in pairs(self.entities) do
		local t = entity:getComponent("transform")
		local v = entity:getComponent("velocity")
		t.x = t.x + v.vx * dt
		t.y = t.y + v.vy * dt
	end
end

return MovementSystem


