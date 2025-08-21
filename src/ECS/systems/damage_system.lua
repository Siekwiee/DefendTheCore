---@class DamageSystem : Object
DamageSystem = Object:extend()

function DamageSystem:init()
    -- Damage type definitions from GDD
    self.damageTypes = {
        kinetic = {
            name = "Kinetic",
            color = {0.8, 0.8, 0.9, 1},
            description = "Good vs unarmored, weak vs shielded"
        },
        pierce = {
            name = "Pierce", 
            color = {1.0, 0.9, 0.3, 1},
            description = "Ignores partial armor, reduces on hit"
        },
        energy = {
            name = "Energy",
            color = {0.3, 0.7, 1.0, 1}, 
            description = "Strong vs shielded, weak vs heavy"
        },
        explosive = {
            name = "Explosive",
            color = {1.0, 0.5, 0.1, 1},
            description = "AoE damage with falloff"
        },
        true_damage = {
            name = "True",
            color = {1.0, 0.2, 1.0, 1},
            description = "Bypasses all mitigation"
        }
    }
    
    -- Enemy resistances and armor types
    self.enemyProfiles = {
        runner = {
            armor = 0,
            resistances = {
                kinetic = 1.0,    -- Normal damage
                pierce = 1.2,     -- Weak to pierce
                energy = 0.8,     -- Resistant to energy
                explosive = 1.1,  -- Slightly weak to explosive
                true_damage = 1.0
            },
            armorType = "unarmored"
        },
        swarm = {
            armor = 0,
            resistances = {
                kinetic = 1.0,
                pierce = 0.7,     -- Resistant to pierce (too small)
                energy = 1.0,
                explosive = 1.5,  -- Very weak to AoE
                true_damage = 1.0
            },
            armorType = "unarmored"
        },
        tank = {
            armor = 0.3,          -- 30% damage reduction
            resistances = {
                kinetic = 0.7,    -- Resistant to kinetic
                pierce = 1.0,     -- Normal pierce
                energy = 1.3,     -- Weak to energy
                explosive = 0.9,  -- Slightly resistant to explosive
                true_damage = 1.0
            },
            armorType = "heavy"
        },
        shield = {
            armor = 0.1,
            resistances = {
                kinetic = 0.6,    -- Very resistant to kinetic
                pierce = 1.1,     -- Slightly weak to pierce
                energy = 1.4,     -- Very weak to energy
                explosive = 1.0,
                true_damage = 1.0
            },
            armorType = "shielded",
            hasDirectionalShield = true
        },
        boss = {
            armor = 0.4,          -- Heavy armor
            resistances = {
                kinetic = 0.8,
                pierce = 1.0,
                energy = 1.2,
                explosive = 0.7,  -- Resistant to explosive
                true_damage = 1.0
            },
            armorType = "heavy"
        }
    }
end

-- Calculate damage after resistances and armor
function DamageSystem:calculateDamage(baseDamage, damageType, enemyType, hasShield)
    local profile = self.enemyProfiles[enemyType] or self.enemyProfiles.runner
    
    -- Apply damage type resistance
    local resistance = profile.resistances[damageType] or 1.0
    local damage = baseDamage * resistance
    
    -- Apply armor reduction (except for true damage)
    if damageType ~= "true_damage" then
        local armorReduction = profile.armor or 0
        
        -- Pierce damage ignores partial armor
        if damageType == "pierce" and armorReduction < 0.5 then
            armorReduction = 0
        end
        
        damage = damage * (1 - armorReduction)
    end
    
    -- Shield interaction
    if hasShield and profile.hasDirectionalShield then
        if damageType == "kinetic" then
            damage = damage * 0.3  -- Shields very effective vs kinetic
        elseif damageType == "energy" then
            damage = damage * 1.2  -- Energy overloads shields
        end
    end
    
    return math.max(0, damage)
end

-- Get damage type effectiveness description
function DamageSystem:getEffectiveness(damageType, enemyType)
    local profile = self.enemyProfiles[enemyType] or self.enemyProfiles.runner
    local resistance = profile.resistances[damageType] or 1.0
    
    if resistance >= 1.3 then
        return "very_effective"
    elseif resistance >= 1.1 then
        return "effective"
    elseif resistance >= 0.9 then
        return "normal"
    elseif resistance >= 0.7 then
        return "resistant"
    else
        return "very_resistant"
    end
end

-- Get color for damage type
function DamageSystem:getDamageTypeColor(damageType)
    local typeData = self.damageTypes[damageType]
    return typeData and typeData.color or {1, 1, 1, 1}
end

-- Create explosive damage in area
function DamageSystem:createExplosion(world, x, y, baseDamage, radius, damageType)
    damageType = damageType or "explosive"
    
    -- Find all entities in explosion radius
    local targets = {}
    for _, entity in pairs(world.entities) do
        local transform = entity:getComponent("transform")
        local combat = entity:getComponent("combat")
        
        if transform and combat and combat.faction == "enemy" then
            local distance = math.sqrt((transform.x - x)^2 + (transform.y - y)^2)
            if distance <= radius then
                table.insert(targets, {entity = entity, distance = distance})
            end
        end
    end
    
    -- Apply damage with falloff
    for _, target in ipairs(targets) do
        local falloff = 1 - (target.distance / radius)
        local damage = baseDamage * falloff
        
        local enemy = target.entity:getComponent("enemy")
        local enemyType = enemy and enemy.kind or "runner"
        local shield = target.entity:getComponent("shield")
        local hasShield = shield and shield.current and shield.current > 0
        
        local finalDamage = self:calculateDamage(damage, damageType, enemyType, hasShield)
        
        local combat = target.entity:getComponent("combat")
        if combat then
            combat.hp = combat.hp - finalDamage
        end
    end
    
    return #targets  -- Return number of targets hit
end

-- Pierce damage that reduces as it hits targets
function DamageSystem:createPierceShot(world, startX, startY, dirX, dirY, baseDamage, maxTargets)
    maxTargets = maxTargets or 3
    local damage = baseDamage
    local targetsHit = 0
    
    -- Simple raycast to find targets in line
    local step = 10
    local maxDistance = 400
    local currentX, currentY = startX, startY
    
    for i = 1, maxDistance, step do
        currentX = startX + dirX * i
        currentY = startY + dirY * i
        
        -- Check for entity at this position
        for _, entity in pairs(world.entities) do
            local transform = entity:getComponent("transform")
            local combat = entity:getComponent("combat")
            local collider = entity:getComponent("circle_collider")
            
            if transform and combat and collider and combat.faction == "enemy" then
                local distance = math.sqrt((transform.x - currentX)^2 + (transform.y - currentY)^2)
                if distance <= collider.radius then
                    -- Hit this target
                    local enemy = entity:getComponent("enemy")
                    local enemyType = enemy and enemy.kind or "runner"
                    local shield = entity:getComponent("shield")
                    local hasShield = shield and shield.current and shield.current > 0
                    
                    local finalDamage = self:calculateDamage(damage, "pierce", enemyType, hasShield)
                    combat.hp = combat.hp - finalDamage
                    
                    targetsHit = targetsHit + 1
                    damage = damage * 0.7  -- Reduce damage for next target
                    
                    if targetsHit >= maxTargets then
                        break
                    end
                end
            end
        end
        
        if targetsHit >= maxTargets then
            break
        end
    end
    
    return targetsHit
end

return DamageSystem
