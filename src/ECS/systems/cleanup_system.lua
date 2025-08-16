local System = require "src.ECS.System"

CleanupSystem = System:extend("CleanupSystem")

function CleanupSystem:init()
	System.init(self)
	self:requireAll("transform")
	self.bounds = {xMin = -200, yMin = -200, xMax = 9999, yMax = 9999}
end

function CleanupSystem:setBounds(xMin, yMin, xMax, yMax)
	if not self.bounds then
		self.bounds = {xMin = -200, yMin = -200, xMax = 9999, yMax = 9999}
	end
	self.bounds.xMin = xMin
	self.bounds.yMin = yMin
	self.bounds.xMax = xMax
	self.bounds.yMax = yMax
end

function CleanupSystem:update(dt)
	if not self.bounds then return end
	for _, e in pairs(self.entities) do
		local t = e:getComponent("transform")
		if t.x < self.bounds.xMin or t.x > self.bounds.xMax or t.y < self.bounds.yMin or t.y > self.bounds.yMax then
			e:destroy()
		end
	end
end

return CleanupSystem


