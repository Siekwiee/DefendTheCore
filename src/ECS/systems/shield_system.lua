local System = require "src.ECS.System"

ShieldSystem = System:extend("ShieldSystem")

function ShieldSystem:init()
	System.init(self)
	self:requireAll("shield")
end

function ShieldSystem:update(dt)
	for _, entity in pairs(self.entities) do
		local shield = entity:getComponent("shield")
		if shield then
			-- Rotate shield over time
			local rotationSpeed = 45  -- degrees per second
			shield.angle = (shield.angle + rotationSpeed * dt) % 360
			
			-- Regenerate shield slowly when not taking damage
			if shield.current < shield.max then
				local regenRate = shield.max * 0.1  -- 10% per second
				shield.current = math.min(shield.max, shield.current + regenRate * dt)
			end
		end
	end
end

return ShieldSystem
