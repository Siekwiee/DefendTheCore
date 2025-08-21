local BaseManager = require "src.managers.base_manager"

---@class UpgradeSystem : BaseManager
---@field activeUpgrades table<string, boolean> Currently active upgrades
---@field upgradeStacks table<string, number> Stack counts for stackable upgrades
---@field synergies table Active synergies
---@field tags table<string, boolean> Upgrade tags for synergy tracking
---@field maxStacks number Maximum allowed stacks
---@field stackableUpgrades table<string> List of stackable upgrade IDs
UpgradeSystem = BaseManager:extend()

function UpgradeSystem:init(config)
    config = config or {}
    config.debug = config.debug or false

    BaseManager:init("UpgradeSystem", config)

    -- Track active upgrades and synergies
    self.activeUpgrades = {}
    self.upgradeStacks = {} -- Track how many times each stackable upgrade has been taken
    self.synergies = {}
    self.tags = {}  -- For synergy tracking

    -- Maximum stacks allowed for stackable upgrades
    self.maxStacks = 5

    -- Define which upgrades are stackable
    self.stackableUpgrades = {
        "damage_boost",
        "fire_rate",
        "projectile_speed",
        "movement_speed" -- Add movement speed to stackable list
    }

    -- Upgrade definitions from GDD
    self.upgrades = {
        -- Basic stat upgrades
        damage_boost = {
            name = "+Damage",
            desc = "Increase weapon damage by 1.",
            rarity = "common",
            tags = {},
            apply = function(weapon) weapon.damage = weapon.damage + 1 end
        },
        
        fire_rate = {
            name = "+Fire Rate", 
            desc = "Fire 15% faster.",
            rarity = "common",
            tags = {},
            apply = function(weapon) weapon.fireRate = weapon.fireRate * 1.15 end
        },
        
        projectile_speed = {
            name = "+Projectile Speed",
            desc = "Shots travel 20% faster.",
            rarity = "common",
            tags = {},
            apply = function(weapon) weapon.projectileSpeed = weapon.projectileSpeed * 1.2 end
        },

        movement_speed = {
            name = "+Movement Speed",
            desc = "Move 15% faster.",
            rarity = "common",
            tags = {},
            apply = function(weapon)
                -- This will be applied to player in the run state
                -- For now, just mark it as taken
            end
        },
        
        -- Weapon form changes
        rail_coil = {
            name = "Rail Coil",
            desc = "Convert shots to rail rounds (high pierce, long charge). -20% fire rate.",
            rarity = "rare",
            tags = {"ballistics", "pierce"},
            apply = function(weapon)
                weapon.type = "rail"
                weapon.fireRate = weapon.fireRate * 0.8
                weapon.pierceCount = weapon.pierceCount + 3
                weapon.chargeTime = 0.5
                weapon.damageType = "pierce"
            end
        },
        
        prisma_lens = {
            name = "Prisma Lens", 
            desc = "Beams now split on kill into 2 minor beams.",
            rarity = "uncommon",
            tags = {"beam", "status"},
            requires = {"beam"},
            apply = function(weapon)
                weapon.beamSplit = true
                weapon.splitCount = 2
            end
        },
        
        flux_capacitor = {
            name = "Flux Capacitor",
            desc = "Overheat system: +40% fire rate until heat cap, then 2s cooldown. +10% base fire rate.",
            rarity = "rare", 
            tags = {"heat", "fireRate"},
            apply = function(weapon)
                weapon.hasOverheat = true
                weapon.maxHeat = 100
                weapon.currentHeat = 0
                weapon.overheatBonus = 1.4
                weapon.fireRate = weapon.fireRate * 1.1
            end
        },
        
        interference_mesh = {
            name = "Interference Mesh",
            desc = "+20% energy damage; shots apply 10% slow (stacking to 40% briefly).",
            rarity = "uncommon",
            tags = {"energy", "status"},
            apply = function(weapon)
                if weapon.damageType == "energy" then
                    weapon.damage = weapon.damage * 1.2
                end
                weapon.appliesSlow = true
                weapon.slowAmount = 0.1
                weapon.slowStacks = 4
            end
        },
        
        fragmentation_core = {
            name = "Fragmentation Core", 
            desc = "Kills cause micro-shrapnel (explosive, small AoE).",
            rarity = "uncommon",
            tags = {"explosive", "onKill"},
            apply = function(weapon)
                weapon.onKillExplosion = true
                weapon.explosionRadius = 25
                weapon.explosionDamage = weapon.damage * 0.5
            end
        },
        
        deflectors = {
            name = "Deflectors",
            desc = "15% chance to ricochet at 70% damage; +1 projectile on ricochet.",
            rarity = "rare",
            tags = {"ballistics", "ricochet"},
            apply = function(weapon)
                weapon.ricochetChance = 0.15
                weapon.ricochetDamage = 0.7
                weapon.ricochetCount = 1
            end
        },
        
        harmonic_resonator = {
            name = "Harmonic Resonator",
            desc = "Every 10th shot is guaranteed crit and chains to 3 targets.",
            rarity = "epic",
            tags = {"crit", "chain"},
            apply = function(weapon)
                weapon.critEveryN = 10
                weapon.critChainCount = 3
                weapon.critMultiplier = 2.0
            end
        },
        
        entropy_tax = {
            name = "Entropy Tax",
            desc = "+30% damage, -30% range; if enemies within danger radius, gain +15% damage more.",
            rarity = "rare",
            tags = {"risk", "damage"},
            apply = function(weapon)
                weapon.damage = weapon.damage * 1.3
                weapon.range = weapon.range * 0.7
                weapon.dangerBonus = true
                weapon.dangerRadius = 100
                weapon.dangerDamageBonus = 1.15
            end
        }
    }
    
    -- Synergy definitions
    self.synergyDefinitions = {
        beam_suite = {
            name = "Beam Suite",
            description = "Beams ramp damage over time and carve lines through grouped foes.",
            requiredTags = {"beam"},
            requiredCount = 2,
            bonus = function(weapon)
                weapon.beamRampDamage = true
                weapon.beamPenetration = true
            end
        },
        
        ballistics_suite = {
            name = "Ballistics Suite", 
            description = "Pinpoint sniping with lethal ricochets.",
            requiredTags = {"ballistics", "pierce"},
            requiredCount = 2,
            bonus = function(weapon)
                weapon.ballisticsBonus = true
                weapon.critChance = (weapon.critChance or 0) + 0.25
                weapon.ricochetDamage = (weapon.ricochetDamage or 0.7) + 0.2
            end
        },
        
        status_suite = {
            name = "Status Suite",
            description = "Slow, mark, and chain crits.",
            requiredTags = {"status"},
            requiredCount = 3,
            bonus = function(weapon)
                weapon.statusMastery = true
                weapon.slowDuration = (weapon.slowDuration or 2) + 1
                weapon.critChainCount = (weapon.critChainCount or 0) + 2
            end
        }
    }
end

function UpgradeSystem:generateUpgradeChoices(count, playerLevel)
    count = count or 3
    playerLevel = playerLevel or 1

    local choices = {}
    local availableUpgrades = {}

    -- Get all available upgrades (not taken yet)
    for id, upgrade in pairs(self.upgrades) do
        if self:canTakeUpgrade(id, upgrade) then
            table.insert(availableUpgrades, {id = id, upgrade = upgrade})
        end
    end

    -- If we don't have enough unique upgrades, allow repeats of basic ones
    if #availableUpgrades < count then
        local basicUpgrades = {"damage_boost", "fire_rate", "projectile_speed"}
        for _, basicId in ipairs(basicUpgrades) do
            local upgrade = self.upgrades[basicId]
            if upgrade then
                table.insert(availableUpgrades, {id = basicId, upgrade = upgrade})
            end
        end
    end

    -- Shuffle the available upgrades for true randomness
    for i = #availableUpgrades, 2, -1 do
        local j = love.math.random(i)
        availableUpgrades[i], availableUpgrades[j] = availableUpgrades[j], availableUpgrades[i]
    end

    -- Avoid offering duplicates in the same draft
    local pickedIds = {}

    -- Select the first 'count' upgrades from shuffled list
    local i, offered = 1, 0
    while offered < count and i <= #availableUpgrades do
        local choice = availableUpgrades[i]
        if not pickedIds[choice.id] then
            -- Check if this is a stackable upgrade and add stack info
            local isStackable = false
            for _, stackableId in ipairs(self.stackableUpgrades) do
                if choice.id == stackableId then
                    isStackable = true
                    break
                end
            end

            local displayName = choice.upgrade.name
            local displayDesc = choice.upgrade.desc

            if isStackable then
                local currentStacks = self.upgradeStacks[choice.id] or 0
                displayName = choice.upgrade.name .. " (" .. (currentStacks + 1) .. "/" .. self.maxStacks .. ")"
                if currentStacks > 0 then
                    displayDesc = choice.upgrade.desc .. " [Stack " .. (currentStacks + 1) .. "]"
                end
            end

            table.insert(choices, {
                id = choice.id,
                name = displayName,
                desc = displayDesc,
                rarity = choice.upgrade.rarity,
                tags = choice.upgrade.tags,
                stackCount = isStackable and (self.upgradeStacks[choice.id] or 0) or nil
            })
            pickedIds[choice.id] = true
            offered = offered + 1
        end
        i = i + 1
    end

    -- If we still don't have enough (due to very small pools), fill with stackable upgrades but ensure no duplicates in same draft
    while offered < count do
        local id = self.stackableUpgrades[love.math.random(1, #self.stackableUpgrades)]
        if not pickedIds[id] then
            local upgrade = self.upgrades[id]
            local currentStacks = self.upgradeStacks[id] or 0

            -- Only offer if not at max stacks
            if currentStacks < self.maxStacks then
                local displayName = upgrade.name .. " (" .. (currentStacks + 1) .. "/" .. self.maxStacks .. ")"
                local displayDesc = upgrade.desc
                if currentStacks > 0 then
                    displayDesc = upgrade.desc .. " [Stack " .. (currentStacks + 1) .. "]"
                end

                table.insert(choices, {
                    id = id,
                    name = displayName,
                    desc = displayDesc,
                    rarity = upgrade.rarity,
                    tags = upgrade.tags,
                    stackCount = currentStacks
                })
                pickedIds[id] = true
                offered = offered + 1
            end
        end
    end

    return choices
end

function UpgradeSystem:canTakeUpgrade(id, upgrade)
    -- Check if this upgrade is stackable
    local isStackable = false
    for _, stackableId in ipairs(self.stackableUpgrades) do
        if id == stackableId then
            isStackable = true
            break
        end
    end

    if isStackable then
        -- Check if we've reached the stack limit
        local currentStacks = self.upgradeStacks[id] or 0
        if currentStacks >= self.maxStacks then
            return false
        end
    else
        -- Check if already taken (only for non-stackable upgrades)
        if self.activeUpgrades[id] then
            return false
        end
    end

    -- Check requirements
    if upgrade.requires then
        for _, req in ipairs(upgrade.requires) do
            if not self.tags[req] then
                return false
            end
        end
    end

    return true
end

function UpgradeSystem:getUpgradeWeight(upgrade, playerLevel)
    local rarityWeights = {
        common = 10,
        uncommon = 6,
        rare = 3,
        epic = 1
    }
    
    local baseWeight = rarityWeights[upgrade.rarity] or 5
    
    -- Adjust weight based on synergies
    local synergyBonus = 0
    for _, tag in ipairs(upgrade.tags) do
        if self.tags[tag] then
            synergyBonus = synergyBonus + 2  -- Boost synergistic upgrades
        end
    end
    
    return math.max(1, baseWeight + synergyBonus)
end

function UpgradeSystem:applyUpgrade(upgradeId, weaponSystem)
    local upgrade = self.upgrades[upgradeId]
    if not upgrade then return false end

    -- Check if this upgrade is stackable
    local isStackable = false
    for _, stackableId in ipairs(self.stackableUpgrades) do
        if upgradeId == stackableId then
            isStackable = true
            break
        end
    end

    if isStackable then
        -- Increment stack count
        self.upgradeStacks[upgradeId] = (self.upgradeStacks[upgradeId] or 0) + 1
    else
        -- Mark as taken for non-stackable upgrades
        self.activeUpgrades[upgradeId] = true
    end

    -- Add tags
    for _, tag in ipairs(upgrade.tags) do
        self.tags[tag] = (self.tags[tag] or 0) + 1
    end

    -- Apply the upgrade
    if upgrade.apply and weaponSystem then
        upgrade.apply(weaponSystem.weapon)
    end

    -- Check for new synergies
    self:checkSynergies(weaponSystem)

    return true
end

function UpgradeSystem:checkSynergies(weaponSystem)
    for synergyId, synergy in pairs(self.synergyDefinitions) do
        if not self.synergies[synergyId] then
            local hasAllTags = true
            local totalCount = 0
            
            for _, tag in ipairs(synergy.requiredTags) do
                local count = self.tags[tag] or 0
                if count == 0 then
                    hasAllTags = false
                    break
                end
                totalCount = totalCount + count
            end
            
            if hasAllTags and totalCount >= synergy.requiredCount then
                -- Activate synergy
                self.synergies[synergyId] = true
                if synergy.bonus and weaponSystem then
                    synergy.bonus(weaponSystem.weapon)
                end
                
                -- Notify player of synergy activation
                return synergyId, synergy
            end
        end
    end
    
    return nil
end

function UpgradeSystem:getActiveSynergies()
    local active = {}
    for synergyId, _ in pairs(self.synergies) do
        local synergy = self.synergyDefinitions[synergyId]
        if synergy then
            table.insert(active, {
                id = synergyId,
                name = synergy.name,
                description = synergy.description
            })
        end
    end
    return active
end

function UpgradeSystem:getTags()
    return self.tags
end

function UpgradeSystem:getActiveUpgrades()
    return self.activeUpgrades
end

-- Reset for new run
function UpgradeSystem:reset()
    self.activeUpgrades = {}
    self.upgradeStacks = {} -- Reset stacks for new run
    self.synergies = {}
    self.tags = {}
end

return UpgradeSystem
