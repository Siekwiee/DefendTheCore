local System = require "src.ECS.System"

RenderSystem = System:extend("RenderSystem")

function RenderSystem:init()
	System.init(self)
	self:requireAll("transform")

	-- Initialize shader manager
	local ShaderManager = require "src.managers.shader_manager"
	self.shaderManager = ShaderManager()

	-- Initialize particle system
	local ParticleSystem = require "src.ECS.systems.particle_system"
	self.particleSystem = ParticleSystem()

	-- Time tracking for animations
	self.time = 0

	-- Color palette for clean geometric design
	self.colors = {
		core = {0.4, 0.8, 1.0, 1},
		coreGlow = {0.6, 0.9, 1.0, 0.6},
		projectile = {0.9, 0.95, 1.0, 1},
		projectileTrail = {0.7, 0.85, 1.0, 0.4},

		-- Enemy colors by type
		runner = {1.0, 0.3, 0.3, 1},      -- Red triangles
		swarm = {1.0, 0.6, 0.2, 1},       -- Orange small circles
		tank = {0.8, 0.2, 0.8, 1},        -- Purple squares
		shield = {0.2, 0.7, 1.0, 1},      -- Blue hexagons
		boss = {1.0, 0.1, 0.1, 1},        -- Dark red large shape

		-- UI colors
		background = {0.15, 0.15, 0.18, 1},
		outline = {1, 1, 1, 0.9},
		damaged = {0.6, 0.6, 0.65, 1},

		-- Shield colors
		shieldFull = {0.2, 0.8, 1.0, 1},
		shieldLow = {1.0, 0.4, 0.2, 1},
	}
end

function RenderSystem:update(dt)
	self.time = self.time + dt

	if self.shaderManager then
		self.shaderManager:update(dt)
	end
	if self.particleSystem then
		self.particleSystem:update(dt)
	end
end

function RenderSystem:draw()
	-- Draw entities
	for _, entity in pairs(self.entities) do
		local t = entity:getComponent("transform")
		local combat = entity:getComponent("combat")
		local collider = entity:getComponent("circle_collider")
		local shield = entity:getComponent("shield")
		local enemy = entity:getComponent("enemy")

		local radius = (collider and collider.radius) or 8

		if combat and combat.faction == "player" and combat.isCore then
			self:drawCore(t.x, t.y, radius)
		elseif combat and combat.faction == "player" and combat.diesOnHit then
			self:drawProjectile(t.x, t.y, radius)
			-- Add projectile trail
			if self.particleSystem and love.math.random() < 0.3 then
				self.particleSystem:trail(t.x, t.y, 0.5)
			end
		elseif combat and combat.faction == "enemy" then
			local enemyType = self:getEnemyType(enemy, radius)
			self:drawEnemy(t.x, t.y, radius, enemyType, combat, shield)
		else
			-- Fallback for unknown entities
			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.circle("line", t.x, t.y, radius)
		end
	end

	-- Draw particles on top
	if self.particleSystem then
		self.particleSystem:draw()
	end

	love.graphics.setColor(1, 1, 1, 1)
end

-- Determine enemy type based on components and size
function RenderSystem:getEnemyType(enemy, radius)
	if enemy and enemy.kind == "boss" then
		return "boss"
	elseif radius <= 8 then
		return "swarm"
	elseif radius <= 12 then
		return "runner"
	elseif radius <= 16 then
		return "shield"
	else
		return "tank"
	end
end

-- Draw the core with a distinctive geometric design
function RenderSystem:drawCore(x, y, radius)
	-- Draw range indicator (subtle)
	love.graphics.setColor(self.colors.core[1], self.colors.core[2], self.colors.core[3], 0.1)
	local range = 200  -- Approximate firing range
	love.graphics.circle("line", x, y, range)

	-- Apply glow shader for the core
	local hasGlow = self.shaderManager and self.shaderManager:applyGlow(self.colors.core, 0.4)

	-- Outer glow ring with pulsing effect
	local pulseIntensity = 0.8 + 0.2 * math.sin(self.time * 2)
	love.graphics.setColor(self.colors.coreGlow[1], self.colors.coreGlow[2], self.colors.coreGlow[3], self.colors.coreGlow[4] * pulseIntensity)
	love.graphics.circle("fill", x, y, radius + 6)

	-- Main core body - octagon
	love.graphics.setColor(self.colors.core)
	self:drawRegularPolygon(x, y, radius, 8, 0)

	-- Clear shader for detail work
	if hasGlow then
		self.shaderManager:clearShader()
	end

	-- Inner detail - rotating smaller octagon
	love.graphics.setColor(1, 1, 1, 0.8)
	local rotationAngle = self.time * 0.5  -- Slow rotation
	self:drawRegularPolygon(x, y, radius * 0.6, 8, math.pi/8 + rotationAngle, "line")

	-- Energy core lines
	love.graphics.setColor(1, 1, 1, 0.6)
	for i = 0, 3 do
		local angle = (i / 4) * 2 * math.pi + rotationAngle * 2
		local innerR = radius * 0.3
		local outerR = radius * 0.5
		local x1 = x + math.cos(angle) * innerR
		local y1 = y + math.sin(angle) * innerR
		local x2 = x + math.cos(angle) * outerR
		local y2 = y + math.sin(angle) * outerR
		love.graphics.line(x1, y1, x2, y2)
	end

	-- Center dot
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.circle("fill", x, y, 3)
end

-- Draw projectiles as small bright shapes
function RenderSystem:drawProjectile(x, y, radius)
	-- Outer glow
	love.graphics.setColor(self.colors.projectileTrail)
	love.graphics.circle("fill", x, y, radius + 2)

	-- Main projectile body
	love.graphics.setColor(self.colors.projectile)
	love.graphics.circle("fill", x, y, radius)

	-- Bright center core
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.circle("fill", x, y, radius * 0.4)

	-- Energy spark effect
	love.graphics.setColor(1, 1, 1, 0.8)
	for i = 0, 3 do
		local angle = (i / 4) * 2 * math.pi + self.time * 8
		local sparkX = x + math.cos(angle) * (radius + 1)
		local sparkY = y + math.sin(angle) * (radius + 1)
		love.graphics.circle("fill", sparkX, sparkY, 0.5)
	end
end

-- Draw enemies with distinct geometric shapes
function RenderSystem:drawEnemy(x, y, radius, enemyType, combat, shield)
	local hpPct = math.max(0, math.min(1, (combat.hp or 0) / (combat.maxHp or 1)))

	-- Background (damaged area)
	love.graphics.setColor(self.colors.damaged)
	self:drawEnemyShape(x, y, radius, enemyType, "fill")

	-- Health fill
	love.graphics.setColor(self.colors[enemyType] or self.colors.runner)
	self:drawEnemyShapeWithHealth(x, y, radius, enemyType, hpPct)

	-- Outline
	love.graphics.setColor(self.colors.outline)
	self:drawEnemyShape(x, y, radius, enemyType, "line")

	-- Shield indicator
	if shield and shield.current and shield.current > 0 then
		self:drawShield(x, y, radius, shield)
	end
end

-- Draw enemy shapes based on type
function RenderSystem:drawEnemyShape(x, y, radius, enemyType, mode)
	if enemyType == "runner" then
		-- Triangle pointing toward center (upward for now)
		self:drawRegularPolygon(x, y, radius, 3, -math.pi/2, mode)
		-- Add speed lines for runners
		if mode == "line" then
			love.graphics.setColor(self.colors.runner[1], self.colors.runner[2], self.colors.runner[3], 0.6)
			for i = 1, 3 do
				local offset = i * 3
				love.graphics.line(x - offset, y + radius + 2, x - offset - 4, y + radius + 6)
			end
		end
	elseif enemyType == "swarm" then
		-- Small circle with pulsing effect
		love.graphics.circle(mode, x, y, radius)
		if mode == "line" then
			-- Add small dots around swarm units
			love.graphics.setColor(self.colors.swarm[1], self.colors.swarm[2], self.colors.swarm[3], 0.4)
			for i = 0, 5 do
				local angle = (i / 6) * 2 * math.pi
				local dotX = x + math.cos(angle) * (radius + 4)
				local dotY = y + math.sin(angle) * (radius + 4)
				love.graphics.circle("fill", dotX, dotY, 1)
			end
		end
	elseif enemyType == "tank" then
		-- Square with armor plating details
		self:drawRegularPolygon(x, y, radius, 4, math.pi/4, mode)
		if mode == "line" then
			-- Add armor detail lines
			love.graphics.setColor(self.colors.tank[1], self.colors.tank[2], self.colors.tank[3], 0.8)
			local innerSize = radius * 0.6
			self:drawRegularPolygon(x, y, innerSize, 4, math.pi/4, "line")
		end
	elseif enemyType == "shield" then
		-- Hexagon with shield indicators
		self:drawRegularPolygon(x, y, radius, 6, 0, mode)
		if mode == "line" then
			-- Add hexagonal detail pattern
			love.graphics.setColor(self.colors.shield[1], self.colors.shield[2], self.colors.shield[3], 0.6)
			local innerSize = radius * 0.7
			self:drawRegularPolygon(x, y, innerSize, 6, math.pi/6, "line")
		end
	elseif enemyType == "boss" then
		-- Complex multi-layered boss design
		self:drawRegularPolygon(x, y, radius, 12, 0, mode)
		if mode == "line" then
			-- Add multiple layers for boss complexity
			love.graphics.setColor(self.colors.boss[1], self.colors.boss[2], self.colors.boss[3], 0.8)
			self:drawRegularPolygon(x, y, radius * 0.8, 8, math.pi/8, "line")
			love.graphics.setColor(self.colors.boss[1], self.colors.boss[2], self.colors.boss[3], 0.6)
			self:drawRegularPolygon(x, y, radius * 0.6, 6, 0, "line")
			-- Add spikes
			for i = 0, 7 do
				local angle = (i / 8) * 2 * math.pi
				local spikeX = x + math.cos(angle) * radius
				local spikeY = y + math.sin(angle) * radius
				local tipX = x + math.cos(angle) * (radius + 6)
				local tipY = y + math.sin(angle) * (radius + 6)
				love.graphics.line(spikeX, spikeY, tipX, tipY)
			end
		end
	else
		-- Default circle
		love.graphics.circle(mode, x, y, radius)
	end
end

-- Draw enemy shape with health-based fill
function RenderSystem:drawEnemyShapeWithHealth(x, y, radius, enemyType, hpPct)
	if hpPct <= 0 then return end

	if enemyType == "runner" then
		self:drawTriangleWithHealth(x, y, radius, hpPct)
	elseif enemyType == "swarm" then
		self:drawCircleWithHealth(x, y, radius, hpPct)
	elseif enemyType == "tank" then
		self:drawSquareWithHealth(x, y, radius, hpPct)
	elseif enemyType == "shield" then
		self:drawHexagonWithHealth(x, y, radius, hpPct)
	elseif enemyType == "boss" then
		self:drawPolygonWithHealth(x, y, radius, 12, hpPct)
	else
		self:drawCircleWithHealth(x, y, radius, hpPct)
	end
end

-- Draw a regular polygon
function RenderSystem:drawRegularPolygon(x, y, radius, sides, rotation, mode)
	mode = mode or "fill"
	rotation = rotation or 0

	local points = {}
	for i = 0, sides - 1 do
		local angle = (i / sides) * 2 * math.pi + rotation
		table.insert(points, x + math.cos(angle) * radius)
		table.insert(points, y + math.sin(angle) * radius)
	end

	love.graphics.polygon(mode, points)
end

-- Health-based shape drawing methods
function RenderSystem:drawCircleWithHealth(x, y, radius, hpPct)
	if hpPct >= 1 then
		love.graphics.circle("fill", x, y, radius)
	else
		self:drawFilledPie(x, y, radius, hpPct)
	end
end

function RenderSystem:drawTriangleWithHealth(x, y, radius, hpPct)
	if hpPct >= 1 then
		self:drawRegularPolygon(x, y, radius, 3, -math.pi/2, "fill")
	else
		-- For triangles, we'll use a simpler approach - scale the triangle
		local scale = math.sqrt(hpPct)
		self:drawRegularPolygon(x, y, radius * scale, 3, -math.pi/2, "fill")
	end
end

function RenderSystem:drawSquareWithHealth(x, y, radius, hpPct)
	if hpPct >= 1 then
		self:drawRegularPolygon(x, y, radius, 4, math.pi/4, "fill")
	else
		-- Scale square based on health
		local scale = math.sqrt(hpPct)
		self:drawRegularPolygon(x, y, radius * scale, 4, math.pi/4, "fill")
	end
end

function RenderSystem:drawHexagonWithHealth(x, y, radius, hpPct)
	if hpPct >= 1 then
		self:drawRegularPolygon(x, y, radius, 6, 0, "fill")
	else
		local scale = math.sqrt(hpPct)
		self:drawRegularPolygon(x, y, radius * scale, 6, 0, "fill")
	end
end

function RenderSystem:drawPolygonWithHealth(x, y, radius, sides, hpPct)
	if hpPct >= 1 then
		self:drawRegularPolygon(x, y, radius, sides, 0, "fill")
	else
		local scale = math.sqrt(hpPct)
		self:drawRegularPolygon(x, y, radius * scale, sides, 0, "fill")
	end
end

-- Draw shield indicator
function RenderSystem:drawShield(x, y, radius, shield)
	local shieldPct = math.max(0, math.min(1, shield.current / (shield.max or 1)))

	-- Interpolate shield color from full to low
	local r = (1 - shieldPct) * self.colors.shieldLow[1] + shieldPct * self.colors.shieldFull[1]
	local g = (1 - shieldPct) * self.colors.shieldLow[2] + shieldPct * self.colors.shieldFull[2]
	local b = (1 - shieldPct) * self.colors.shieldLow[3] + shieldPct * self.colors.shieldFull[3]

	love.graphics.setColor(r, g, b, 0.8)

	-- Draw shield as rotating arcs
	if shield.angle and shield.arc then
		self:drawShieldArcs(x, y, radius + 3, shield.angle, shield.arc, 3)
	else
		-- Fallback: simple ring
		love.graphics.circle("line", x, y, radius + 3)
	end
end

-- Draw shield arcs (rotating directional shields)
function RenderSystem:drawShieldArcs(x, y, radius, angle, arc, numArcs)
	numArcs = numArcs or 3
	local arcSize = arc * math.pi / 180  -- Convert to radians
	local angleRad = angle * math.pi / 180

	for i = 0, numArcs - 1 do
		local startAngle = angleRad + (i * 2 * math.pi / numArcs) - arcSize / 2
		local endAngle = startAngle + arcSize
		self:drawArc(x, y, radius, startAngle, endAngle, 2)
	end
end

-- Draw an arc
function RenderSystem:drawArc(x, y, radius, startAngle, endAngle, thickness)
	thickness = thickness or 1
	local segments = math.max(8, math.floor((endAngle - startAngle) * radius / 4))

	for i = 0, segments - 1 do
		local a1 = startAngle + (i / segments) * (endAngle - startAngle)
		local a2 = startAngle + ((i + 1) / segments) * (endAngle - startAngle)

		local x1, y1 = x + math.cos(a1) * radius, y + math.sin(a1) * radius
		local x2, y2 = x + math.cos(a2) * radius, y + math.sin(a2) * radius

		love.graphics.setLineWidth(thickness)
		love.graphics.line(x1, y1, x2, y2)
	end
	love.graphics.setLineWidth(1)
end

-- Draw a filled pie representing a percentage (0..1)
function RenderSystem:drawFilledPie(cx, cy, r, pct)
    if pct <= 0 then return end
    if pct >= 1 then
        love.graphics.circle("fill", cx, cy, r)
        return
    end
    local segments = math.max(12, math.floor(r * 2))
    local angle = pct * 2 * math.pi
    local points = {cx, cy}
    for i = 0, segments do
        local a = (i / segments) * angle - math.pi / 2
        table.insert(points, cx + math.cos(a) * r)
        table.insert(points, cy + math.sin(a) * r)
    end
    love.graphics.polygon("fill", points)
end

return RenderSystem


