local System = require "src.ECS.System"

ProjectileSystem = System:extend("ProjectileSystem")

function ProjectileSystem:init()
	System.init(self)
	self:requireAll("transform")
	self.fireCooldown = 0
	self.fireInterval = 0.25
	self.fireFunc = nil -- function(world) -> {x,y,dirX,dirY,speed,damage}
end

function ProjectileSystem:setFireFunction(fn)
	self.fireFunc = fn
end

function ProjectileSystem:setInterval(interval)
	if interval and interval > 0 then
		self.fireInterval = interval
	end
end

function ProjectileSystem:update(dt)
	if not self.fireFunc then return end
	self.fireCooldown = self.fireCooldown - dt
	if self.fireCooldown <= 0 then
		self.fireCooldown = self.fireInterval
		local spec = self.fireFunc(self.world)
		if spec then self:spawnProjectile(spec) end
	end
end

function ProjectileSystem:spawnProjectile(spec)
	local Entity = require "src.ECS.Entity"
	local Transform = require "src.ECS.components.transform"
	local Velocity = require "src.ECS.components.velocity"
	local Collider = require "src.ECS.components.circle_collider"
	local Combat = require "src.ECS.components.combat"
	local e = Entity:new()
	e:addComponent(Transform({x = spec.x, y = spec.y}))
	e:addComponent(Velocity({vx = spec.dirX * spec.speed, vy = spec.dirY * spec.speed}))
	e:addComponent(Collider({radius = spec.radius or 4}))
	e:addComponent(Combat({faction = "player", hp = 1, maxHp = 1, contactDamage = spec.damage or 1, diesOnHit = true}))
	self.world:addEntity(e)
end

return ProjectileSystem


