local System = require "src.ECS.System"

CollisionSystem = System:extend("CollisionSystem")

local function dist2(ax, ay, bx, by)
	local dx = ax - bx
	local dy = ay - by
	return dx*dx + dy*dy
end

function CollisionSystem:init()
	System.init(self)
	self:requireAll("transform", "circle_collider")
	self.shaderManager = nil  -- Will be set by the world/run state
	self.particleSystem = nil  -- Will be set by the world/run state
	self.audioSystem = nil  -- Will be set by the world/run state

	-- Initialize damage system
	local DamageSystem = require "src.ECS.systems.damage_system"
	self.damageSystem = DamageSystem()
end

function CollisionSystem:setShaderManager(shaderManager)
	self.shaderManager = shaderManager
end

function CollisionSystem:setParticleSystem(particleSystem)
	self.particleSystem = particleSystem
end

function CollisionSystem:setAudioSystem(audioSystem)
	self.audioSystem = audioSystem
end

function CollisionSystem:update(dt)
	local entityList = {}
	for _, e in pairs(self.entities) do
		table.insert(entityList, e)
	end
	for i = 1, #entityList - 1 do
		local a = entityList[i]
		local ta = a:getComponent("transform")
		local ca = a:getComponent("circle_collider")
		local coma = a:getComponent("combat")
		for j = i + 1, #entityList do
			local b = entityList[j]
			local tb = b:getComponent("transform")
			local cb = b:getComponent("circle_collider")
			local comb = b:getComponent("combat")
			local rsum = (ca.radius or 0) + (cb.radius or 0)
			if dist2(ta.x, ta.y, tb.x, tb.y) <= rsum * rsum then
				-- Advanced damage system with types and resistances
				if coma and comb and coma.faction ~= comb.faction then
					local baseDmgA = comb.contactDamage or 0
					local baseDmgB = coma.contactDamage or 0
					local dmgTypeA = comb.damageType or "kinetic"
					local dmgTypeB = coma.damageType or "kinetic"

					-- Get enemy types for damage calculation
					local enemyA = a:getComponent("enemy")
					local enemyB = b:getComponent("enemy")
					local enemyTypeA = enemyA and enemyA.kind or "runner"
					local enemyTypeB = enemyB and enemyB.kind or "runner"

					-- directional shield support
					local shieldA = a:getComponent("shield")
					local shieldB = b:getComponent("shield")
					local hasShieldA = shieldA and shieldA.current and shieldA.current > 0
					local hasShieldB = shieldB and shieldB.current and shieldB.current > 0

					-- Calculate damage with type effectiveness
					local dmgA = baseDmgA
					local dmgB = baseDmgB

					-- Apply damage type calculations for enemies
					if coma.faction == "enemy" and baseDmgA > 0 then
						dmgA = self.damageSystem:calculateDamage(baseDmgA, dmgTypeA, enemyTypeA, hasShieldA)
					end
					if comb.faction == "enemy" and baseDmgB > 0 then
						dmgB = self.damageSystem:calculateDamage(baseDmgB, dmgTypeB, enemyTypeB, hasShieldB)
					end

					-- Shield blocking (directional)
					if hasShieldA then
						local dir = math.deg(math.atan2(tb.y - ta.y, tb.x - ta.x))
						if CollisionSystem._withinArc(dir, shieldA.angle, shieldA.arc) then
							local absorbed = math.min(shieldA.current, dmgA)
							shieldA.current = shieldA.current - absorbed
							dmgA = dmgA - absorbed
						end
					end
					if hasShieldB then
						local dir = math.deg(math.atan2(ta.y - tb.y, ta.x - tb.x))
						if CollisionSystem._withinArc(dir, shieldB.angle, shieldB.arc) then
							local absorbed = math.min(shieldB.current, dmgB)
							shieldB.current = shieldB.current - absorbed
							dmgB = dmgB - absorbed
						end
					end

					-- apply calculated damage
					coma.hp = (coma.hp or 1) - dmgA
					comb.hp = (comb.hp or 1) - dmgB

					-- Visual effects for damage
					if self.shaderManager then
						-- Screen shake for core damage
						if (coma.isCore and dmgA > 0) or (comb.isCore and dmgB > 0) then
							self.shaderManager:screenShake(0.3, 0.2)
						end
						-- Smaller shake for regular hits
						if dmgA > 0 or dmgB > 0 then
							self.shaderManager:screenShake(0.1, 0.1)
						end
					end

					-- Audio effects for damage
					if self.audioSystem then
						-- Core hit sound
						if (coma.isCore and dmgA > 0) or (comb.isCore and dmgB > 0) then
							self.audioSystem:playCoreHit()
						end
						-- Regular hit sounds with effectiveness feedback
						if dmgA > 0 and coma.faction == "enemy" then
							local effectiveness = self.damageSystem:getEffectiveness(dmgTypeA, enemyTypeA)
							self.audioSystem:playHit(dmgTypeA, effectiveness)
						end
						if dmgB > 0 and comb.faction == "enemy" then
							local effectiveness = self.damageSystem:getEffectiveness(dmgTypeB, enemyTypeB)
							self.audioSystem:playHit(dmgTypeB, effectiveness)
						end
					end

					-- Particle effects for impacts
					if self.particleSystem then
						-- Impact particles at collision point
						local impactX = (ta.x + tb.x) * 0.5
						local impactY = (ta.y + tb.y) * 0.5
						local direction = math.atan2(tb.y - ta.y, tb.x - ta.x)
						self.particleSystem:impact(impactX, impactY, direction, 0.8)
					end

					-- projectiles die on hit
					if coma.diesOnHit then a:destroy() end
					if comb.diesOnHit then b:destroy() end
					-- Stop further processing for these two this frame
					break
				end
			end
		end
	end

	-- Cleanup dead
	for _, e in pairs(self.entities) do
		local c = e:getComponent("combat")
		if c and c.hp <= 0 then
			-- Death effects
			if c.faction == "enemy" then
				local t = e:getComponent("transform")
				if t then
					-- Death particles
					if self.particleSystem then
						local intensity = math.min(2.0, (c.maxHp or 1) / 5)  -- Scale with enemy size
						self.particleSystem:death(t.x, t.y, intensity)
					end

					-- Death sound
					if self.audioSystem then
						local size = (c.maxHp or 1) / 10
						self.audioSystem:playExplosion(size)
					end
				end
			end
			e:destroy()
		end
	end
end

function CollisionSystem._withinArc(dirDeg, centerDeg, arcDeg)
    local function norm(a)
        while a > 180 do a = a - 360 end
        while a < -180 do a = a + 360 end
        return a
    end
    local delta = norm(dirDeg - centerDeg)
    return math.abs(delta) <= (arcDeg * 0.5)
end
return CollisionSystem