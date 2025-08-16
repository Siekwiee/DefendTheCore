---@class WeaponSystem : Object
WeaponSystem = Object:extend()

function WeaponSystem:init()
    self.time = 0
    self.fireCooldown = 0
    self.fireInterval = 0.25
    
    -- Current weapon configuration
    self.weapon = {
        type = "projectile",  -- projectile, beam, rail, shotgun, burst
        damage = 1,
        damageType = "kinetic",
        fireRate = 1.0,       -- Multiplier
        projectileSpeed = 380,
        range = 300,
        pierceCount = 0,
        burstCount = 1,
        spreadAngle = 0,      -- For shotgun
        chargeTime = 0,       -- For rail
        beamDuration = 0,     -- For beam
        explosiveRadius = 0   -- For explosive shots
    }
    
    -- Weapon mode definitions
    self.weaponModes = {
        projectile = {
            name = "Projectile",
            description = "Standard energy bolts",
            fireFunction = "fireProjectile"
        },
        beam = {
            name = "Beam",
            description = "Continuous energy beam",
            fireFunction = "fireBeam"
        },
        rail = {
            name = "Rail",
            description = "High-pierce charged shots",
            fireFunction = "fireRail"
        },
        shotgun = {
            name = "Shotgun",
            description = "Multiple spread projectiles",
            fireFunction = "fireShotgun"
        },
        burst = {
            name = "Burst",
            description = "Rapid-fire bursts",
            fireFunction = "fireBurst"
        }
    }
    
    -- Active effects
    self.activeBeams = {}
    self.chargingShots = {}
    self.burstQueue = {}
    
    -- Systems references
    self.world = nil
    self.damageSystem = nil
    self.particleSystem = nil
end

function WeaponSystem:setWorld(world)
    self.world = world
end

function WeaponSystem:setDamageSystem(damageSystem)
    self.damageSystem = damageSystem
end

function WeaponSystem:setParticleSystem(particleSystem)
    self.particleSystem = particleSystem
end

function WeaponSystem:update(dt)
    self.time = self.time + dt
    self.fireCooldown = self.fireCooldown - dt
    
    -- Update active beams
    self:updateBeams(dt)
    
    -- Update charging shots
    self:updateChargingShots(dt)
    
    -- Process burst queue
    self:processBurstQueue(dt)
end

function WeaponSystem:canFire()
    return self.fireCooldown <= 0
end

function WeaponSystem:fire(coreX, coreY, targetX, targetY)
    if not self:canFire() then return false end
    
    local mode = self.weaponModes[self.weapon.type]
    if not mode then return false end
    
    -- Calculate direction
    local dx, dy = targetX - coreX, targetY - coreY
    local len = math.sqrt(dx*dx + dy*dy) + 1e-6
    local dirX, dirY = dx/len, dy/len
    
    -- Call appropriate firing function
    local success = self[mode.fireFunction](self, coreX, coreY, dirX, dirY)
    
    if success then
        self.fireCooldown = self.fireInterval / self.weapon.fireRate
        return true
    end
    
    return false
end

-- Projectile firing mode
function WeaponSystem:fireProjectile(x, y, dirX, dirY)
    if not self.world then return false end
    
    local Entity = require "src.ECS.Entity"
    local Transform = require "src.ECS.components.transform"
    local Velocity = require "src.ECS.components.velocity"
    local Collider = require "src.ECS.components.circle_collider"
    local Combat = require "src.ECS.components.combat"
    
    local e = Entity:new()
    e:addComponent(Transform({x = x, y = y}))
    e:addComponent(Velocity({
        vx = dirX * self.weapon.projectileSpeed,
        vy = dirY * self.weapon.projectileSpeed
    }))
    e:addComponent(Collider({radius = 4}))
    e:addComponent(Combat({
        faction = "player",
        hp = 1,
        maxHp = 1,
        contactDamage = self.weapon.damage,
        damageType = self.weapon.damageType,
        diesOnHit = true
    }))
    
    self.world:addEntity(e)
    return true
end

-- Beam firing mode
function WeaponSystem:fireBeam(x, y, dirX, dirY)
    local beam = {
        startX = x,
        startY = y,
        dirX = dirX,
        dirY = dirY,
        duration = self.weapon.beamDuration or 0.5,
        damage = self.weapon.damage,
        damageType = self.weapon.damageType,
        lastDamageTime = 0,
        damageInterval = 0.1  -- Damage every 0.1 seconds
    }
    
    table.insert(self.activeBeams, beam)
    return true
end

-- Rail firing mode (piercing charged shot)
function WeaponSystem:fireRail(x, y, dirX, dirY)
    if self.weapon.chargeTime > 0 then
        -- Start charging
        local charge = {
            x = x,
            y = y,
            dirX = dirX,
            dirY = dirY,
            chargeTime = self.weapon.chargeTime,
            currentCharge = 0
        }
        table.insert(self.chargingShots, charge)
    else
        -- Instant rail shot
        self:executeRailShot(x, y, dirX, dirY)
    end
    return true
end

-- Shotgun firing mode
function WeaponSystem:fireShotgun(x, y, dirX, dirY)
    local pelletCount = 5
    local spread = self.weapon.spreadAngle or math.pi/6  -- 30 degrees
    
    for i = 1, pelletCount do
        local angle = math.atan2(dirY, dirX) + (i - 3) * spread / pelletCount
        local pelletDirX = math.cos(angle)
        local pelletDirY = math.sin(angle)
        
        -- Create individual pellet
        self:createPellet(x, y, pelletDirX, pelletDirY)
    end
    
    return true
end

-- Burst firing mode
function WeaponSystem:fireBurst(x, y, dirX, dirY)
    local burstCount = self.weapon.burstCount or 3
    local burstDelay = 0.05  -- Time between burst shots
    
    for i = 1, burstCount do
        table.insert(self.burstQueue, {
            x = x,
            y = y,
            dirX = dirX,
            dirY = dirY,
            delay = (i - 1) * burstDelay,
            currentDelay = (i - 1) * burstDelay
        })
    end
    
    return true
end

-- Helper functions
function WeaponSystem:createPellet(x, y, dirX, dirY)
    if not self.world then return end
    
    local Entity = require "src.ECS.Entity"
    local Transform = require "src.ECS.components.transform"
    local Velocity = require "src.ECS.components.velocity"
    local Collider = require "src.ECS.components.circle_collider"
    local Combat = require "src.ECS.components.combat"
    
    local e = Entity:new()
    e:addComponent(Transform({x = x, y = y}))
    e:addComponent(Velocity({
        vx = dirX * self.weapon.projectileSpeed * 0.8,  -- Slightly slower
        vy = dirY * self.weapon.projectileSpeed * 0.8
    }))
    e:addComponent(Collider({radius = 2}))  -- Smaller pellets
    e:addComponent(Combat({
        faction = "player",
        hp = 1,
        maxHp = 1,
        contactDamage = self.weapon.damage * 0.6,  -- Less damage per pellet
        damageType = self.weapon.damageType,
        diesOnHit = true
    }))
    
    self.world:addEntity(e)
end

function WeaponSystem:executeRailShot(x, y, dirX, dirY)
    if self.damageSystem and self.world then
        local damage = self.weapon.damage * 2  -- Rail shots do more damage
        local maxTargets = self.weapon.pierceCount + 1
        local targetsHit = self.damageSystem:createPierceShot(
            self.world, x, y, dirX, dirY, damage, maxTargets
        )
        
        -- Visual effect for rail shot
        if self.particleSystem then
            self.particleSystem:emit("rail_trail", x, y, math.atan2(dirY, dirX), 1.0)
        end
        
        return targetsHit > 0
    end
    return false
end

function WeaponSystem:updateBeams(dt)
    for i = #self.activeBeams, 1, -1 do
        local beam = self.activeBeams[i]
        beam.duration = beam.duration - dt
        beam.lastDamageTime = beam.lastDamageTime + dt
        
        -- Apply beam damage
        if beam.lastDamageTime >= beam.damageInterval then
            self:applyBeamDamage(beam)
            beam.lastDamageTime = 0
        end
        
        -- Remove expired beams
        if beam.duration <= 0 then
            table.remove(self.activeBeams, i)
        end
    end
end

function WeaponSystem:updateChargingShots(dt)
    for i = #self.chargingShots, 1, -1 do
        local charge = self.chargingShots[i]
        charge.currentCharge = charge.currentCharge + dt
        
        if charge.currentCharge >= charge.chargeTime then
            -- Fire the charged shot
            self:executeRailShot(charge.x, charge.y, charge.dirX, charge.dirY)
            table.remove(self.chargingShots, i)
        end
    end
end

function WeaponSystem:processBurstQueue(dt)
    for i = #self.burstQueue, 1, -1 do
        local burst = self.burstQueue[i]
        burst.currentDelay = burst.currentDelay - dt
        
        if burst.currentDelay <= 0 then
            -- Fire this burst shot
            self:fireProjectile(burst.x, burst.y, burst.dirX, burst.dirY)
            table.remove(self.burstQueue, i)
        end
    end
end

function WeaponSystem:applyBeamDamage(beam)
    if not self.world or not self.damageSystem then return end
    
    -- Find targets along beam path
    local range = self.weapon.range or 300
    local endX = beam.startX + beam.dirX * range
    local endY = beam.startY + beam.dirY * range
    
    -- Simple beam collision detection
    for _, entity in pairs(self.world.entities) do
        local transform = entity:getComponent("transform")
        local combat = entity:getComponent("combat")
        local collider = entity:getComponent("circle_collider")
        
        if transform and combat and collider and combat.faction == "enemy" then
            -- Check if entity intersects with beam line
            local distance = self:pointToLineDistance(
                transform.x, transform.y,
                beam.startX, beam.startY,
                endX, endY
            )
            
            if distance <= collider.radius then
                local enemy = entity:getComponent("enemy")
                local enemyType = enemy and enemy.kind or "runner"
                local shield = entity:getComponent("shield")
                local hasShield = shield and shield.current and shield.current > 0
                
                local finalDamage = self.damageSystem:calculateDamage(
                    beam.damage, beam.damageType, enemyType, hasShield
                )
                
                combat.hp = combat.hp - finalDamage
            end
        end
    end
end

function WeaponSystem:pointToLineDistance(px, py, x1, y1, x2, y2)
    local A = px - x1
    local B = py - y1
    local C = x2 - x1
    local D = y2 - y1
    
    local dot = A * C + B * D
    local lenSq = C * C + D * D
    
    if lenSq == 0 then
        return math.sqrt(A * A + B * B)
    end
    
    local param = dot / lenSq
    
    local xx, yy
    if param < 0 then
        xx, yy = x1, y1
    elseif param > 1 then
        xx, yy = x2, y2
    else
        xx = x1 + param * C
        yy = y1 + param * D
    end
    
    local dx = px - xx
    local dy = py - yy
    return math.sqrt(dx * dx + dy * dy)
end

-- Weapon configuration
function WeaponSystem:setWeaponType(weaponType)
    if self.weaponModes[weaponType] then
        self.weapon.type = weaponType
        return true
    end
    return false
end

function WeaponSystem:upgradeWeapon(upgradeType, value)
    if self.weapon[upgradeType] ~= nil then
        if upgradeType == "fireRate" or upgradeType == "projectileSpeed" then
            self.weapon[upgradeType] = self.weapon[upgradeType] * value
        else
            self.weapon[upgradeType] = self.weapon[upgradeType] + value
        end
        return true
    end
    return false
end

function WeaponSystem:getWeaponInfo()
    return {
        type = self.weapon.type,
        damage = self.weapon.damage,
        damageType = self.weapon.damageType,
        fireRate = self.weapon.fireRate,
        description = self.weaponModes[self.weapon.type].description
    }
end

return WeaponSystem
