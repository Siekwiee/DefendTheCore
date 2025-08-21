---@class ParticleSystem : Object
ParticleSystem = Object:extend()

function ParticleSystem:init()
    self.particles = {}
    self.time = 0
    
    -- Particle type definitions
    self.particleTypes = {
        explosion = {
            count = 8,
            speed = {80, 150},
            life = {0.3, 0.6},
            size = {2, 4},
            color = {{1, 0.8, 0.2, 1}, {1, 0.3, 0.1, 0}},
            gravity = 0,
            drag = 0.95
        },
        impact = {
            count = 4,
            speed = {40, 80},
            life = {0.2, 0.4},
            size = {1, 3},
            color = {{1, 1, 1, 1}, {0.8, 0.8, 0.8, 0}},
            gravity = 0,
            drag = 0.9
        },
        trail = {
            count = 1,
            speed = {0, 0},
            life = {0.1, 0.2},
            size = {1, 2},
            color = {{0.7, 0.9, 1, 0.8}, {0.4, 0.6, 0.8, 0}},
            gravity = 0,
            drag = 1.0
        },
        death = {
            count = 12,
            speed = {60, 120},
            life = {0.4, 0.8},
            size = {1, 3},
            color = {{1, 0.4, 0.4, 1}, {0.6, 0.2, 0.2, 0}},
            gravity = 50,
            drag = 0.98
        },
        rail_trail = {
            count = 20,
            speed = {20, 40},
            life = {0.3, 0.6},
            size = {1, 2},
            color = {{1, 0.9, 0.3, 1}, {0.8, 0.6, 0.1, 0}},
            gravity = 0,
            drag = 0.95
        }
    }
end

function ParticleSystem:update(dt)
    self.time = self.time + dt
    
    -- Update all particles
    for i = #self.particles, 1, -1 do
        local p = self.particles[i]
        
        -- Update physics
        p.vx = p.vx * p.drag
        p.vy = p.vy * p.drag + p.gravity * dt
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        
        -- Update life
        p.life = p.life - dt
        p.age = p.age + dt
        
        -- Update size and color based on age
        local t = p.age / p.maxLife
        p.currentSize = p.startSize * (1 - t * 0.5)  -- Shrink over time
        
        -- Interpolate color
        local startColor = p.startColor
        local endColor = p.endColor
        p.currentColor = {
            startColor[1] + (endColor[1] - startColor[1]) * t,
            startColor[2] + (endColor[2] - startColor[2]) * t,
            startColor[3] + (endColor[3] - startColor[3]) * t,
            startColor[4] + (endColor[4] - startColor[4]) * t
        }
        
        -- Remove dead particles
        if p.life <= 0 then
            table.remove(self.particles, i)
        end
    end
end

function ParticleSystem:draw()
    for _, p in ipairs(self.particles) do
        love.graphics.setColor(p.currentColor)
        love.graphics.circle("fill", p.x, p.y, p.currentSize)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

-- Emit particles of a specific type
function ParticleSystem:emit(particleType, x, y, direction, intensity)
    local config = self.particleTypes[particleType]
    if not config then return end
    
    intensity = intensity or 1.0
    direction = direction or 0
    
    local count = math.floor(config.count * intensity)
    
    for i = 1, count do
        local particle = self:createParticle(config, x, y, direction, intensity)
        table.insert(self.particles, particle)
    end
end

-- Create a single particle
function ParticleSystem:createParticle(config, x, y, direction, intensity)
    local speed = love.math.random() * (config.speed[2] - config.speed[1]) + config.speed[1]
    local life = love.math.random() * (config.life[2] - config.life[1]) + config.life[1]
    local size = love.math.random() * (config.size[2] - config.size[1]) + config.size[1]
    
    -- Random angle around direction
    local angle = direction + (love.math.random() - 0.5) * math.pi
    
    local particle = {
        x = x,
        y = y,
        vx = math.cos(angle) * speed * intensity,
        vy = math.sin(angle) * speed * intensity,
        life = life,
        maxLife = life,
        age = 0,
        startSize = size * intensity,
        currentSize = size * intensity,
        startColor = config.color[1],
        endColor = config.color[2],
        currentColor = config.color[1],
        gravity = config.gravity or 0,
        drag = config.drag or 1.0
    }
    
    return particle
end

-- Convenience methods for common effects
function ParticleSystem:explode(x, y, intensity)
    self:emit("explosion", x, y, 0, intensity or 1.0)
end

function ParticleSystem:impact(x, y, direction, intensity)
    self:emit("impact", x, y, direction or 0, intensity or 1.0)
end

function ParticleSystem:trail(x, y, intensity)
    self:emit("trail", x, y, 0, intensity or 1.0)
end

function ParticleSystem:death(x, y, intensity)
    self:emit("death", x, y, 0, intensity or 1.0)
end

-- Get particle count for performance monitoring
function ParticleSystem:getParticleCount()
    return #self.particles
end

-- Clear all particles
function ParticleSystem:clear()
    self.particles = {}
end

-- Add custom particle type
function ParticleSystem:addParticleType(name, config)
    self.particleTypes[name] = config
end

return ParticleSystem
