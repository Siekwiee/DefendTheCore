local System = require "src.ECS.System"

AISeekSystem = System:extend("AISeekSystem")

function AISeekSystem:init()
	System.init(self)
	-- Only steer enemies (not projectiles)
	self:requireAll("transform", "velocity", "enemy")
	self.targetProvider = nil -- function(world) -> {x,y}
end

function AISeekSystem:setTargetProvider(fn)
	self.targetProvider = fn
end

function AISeekSystem:update(dt)
	if not self.targetProvider then return end
	local tx, ty = self.targetProvider(self.world)
	for _, e in pairs(self.entities) do
		local t = e:getComponent("transform")
		local v = e:getComponent("velocity")
		local dx = tx - t.x
		local dy = ty - t.y
		local len = math.sqrt(dx*dx + dy*dy) + 1e-6
		local speed = math.sqrt(v.vx*v.vx + v.vy*v.vy)
		v.vx = (dx/len) * speed
		v.vy = (dy/len) * speed
	end
end

return AISeekSystem


