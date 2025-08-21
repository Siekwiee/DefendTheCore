local BaseManager = require "src.managers.base_manager"

---@class ResourceSpawner : BaseManager
---@field items table Active spawned items
---@field coreSpawnTimer number Timer for core spawns
---@field coreSpawnInterval number Interval between core spawns
---@field brownBoxSpawnTimer number Timer for brown box spawns
---@field brownBoxSpawnInterval number Interval between brown box spawns
---@field itemTypes table Definitions for different item types
ResourceSpawner = BaseManager:extend()

function ResourceSpawner:init(config)
    config = config or {}
    config.debug = config.debug or false

    BaseManager:init("ResourceSpawner", config)

    -- Core spawning configuration
    self.coreSpawnTimer = 0
    self.coreSpawnInterval = self:getConfig("coreSpawnInterval", 75)
    self.brownBoxSpawnTimer = 0
    self.brownBoxSpawnInterval = self:getConfig("brownBoxSpawnInterval", 150)

    -- Initialize default item types and settings
    self:setupDefaults()
end

function ResourceSpawner:setupDefaults()
    -- Item type definitions
    self.itemTypes = {
        credits = {
            color = {1, 1, 0.3, 1}, -- Yellow
            radius = 6,
            lifetime = 30,
            valueRange = {5, 15},
            hasGlow = false,
            autoPickup = true,
            description = "Currency for purchases"
        },
        parts = {
            color = {0.3, 0.8, 1, 1}, -- Blue
            radius = 10,
            lifetime = 45,
            valueRange = {1, 1},
            hasGlow = true,
            autoPickup = true,
            description = "Rare crafting materials"
        },
        cores = {
            color = {1, 0.3, 1, 1}, -- Magenta
            radius = 12,
            lifetime = 60,
            valueRange = {1, 1},
            hasGlow = true,
            autoPickup = true,
            description = "Ultra-rare progression items"
        },
        health = {
            color = {0.3, 1, 0.3, 1}, -- Green
            radius = 8,
            lifetime = 20,
            valueRange = {50, 70},
            hasGlow = true,
            autoPickup = true,
            description = "Restores player health"
        },
        inventory_item = {
            color = {0.8, 0.3, 1, 1}, -- Purple
            radius = 9,
            lifetime = 60,
            valueRange = {1, 1},
            hasGlow = true,
            autoPickup = false, -- Require manual pickup for equipment
            description = "Equipment upgrade"
        },
        brown_box = {
            color = {0.6, 0.4, 0.2, 1}, -- Brown
            radius = 10,
            lifetime = 45,
            valueRange = {1, 1},
            hasGlow = true,
            autoPickup = true,
            description = "Mystery box with random loot"
        }
    }
    
    -- Spawn probability settings
    self.spawnRates = {
        onEnemyDeath = {
            credits = 0.15,    -- 15% chance
            parts = 0.03,      -- 3% chance
            health = 0.08,     -- 8% chance (conditional on low health)
            inventory_item = 0.005, -- 0.5% chance
            brown_box = 0.03   -- 3% chance for brown box (rare but rewarding)
        }
    }

    -- Configurable loot table for brown boxes (focused on equipment)
    self.brownBoxLootTable = {
        {type = "inventory_item", weight = 60}, -- Primary reward: equipment items
        {type = "credits", weight = 20, valueRange = {25, 50}}, -- Reduced weight, higher value
        {type = "parts", weight = 10, valueRange = {2, 4}}, -- Reduced weight, higher value
        {type = "cores", weight = 10, valueRange = {1, 2}}, -- Increased weight and value
        -- Easy to add more items here
        -- {type = "new_item", weight = 5, valueRange = {1, 3}},
    }

    -- Configurable duplicate conversion settings
    self.duplicateItemCreditValue = 50 -- Credits given for duplicate items from brown boxes
    self.duplicateDirectItemCreditValue = 30 -- Credits given for duplicate direct item drops
end

function ResourceSpawner:update(dt, playerHealth, playerMaxHealth)
    if not self:isActive() then return end

    if not playerHealth or not playerMaxHealth then
        self:logError("Player health parameters are required", "warning")
        return
    end

    -- Update core spawn timer
    self.coreSpawnTimer = self.coreSpawnTimer + dt

    -- Update brown box spawn timer
    self.brownBoxSpawnTimer = self.brownBoxSpawnTimer + dt

    -- Update all items
    for i = #self.items, 1, -1 do
        local item = self.items[i]
        item.lifetime = item.lifetime - dt
        item.bobTime = item.bobTime + dt * 3 -- Bobbing animation

        -- Remove expired items
        if item.lifetime <= 0 then
            table.remove(self.items, i)
        end
    end
end

function ResourceSpawner:spawnItem(itemType, x, y, customValue)
    local typeDef = self.itemTypes[itemType]
    if not typeDef then
        print("Warning: Unknown item type: " .. tostring(itemType))
        return
    end
    
    local item = {
        type = itemType,
        x = x, y = y,
        r = typeDef.radius,
        color = typeDef.color,
        lifetime = typeDef.lifetime,
        bobTime = 0,
        hasGlow = typeDef.hasGlow,
        autoPickup = typeDef.autoPickup,
        value = customValue or love.math.random(typeDef.valueRange[1], typeDef.valueRange[2])
    }
    
    -- Special handling for inventory items
    if itemType == "inventory_item" then
        local itemPool = require("src.data.items")
        item.itemData = itemPool[love.math.random(#itemPool)]
    end
    
    table.insert(self.items, item)
    return item
end

function ResourceSpawner:handleEnemyDeath(enemyX, enemyY, playerHealth, playerMaxHealth)
    local healthPercent = playerHealth / playerMaxHealth
    local roll = love.math.random()

    -- Check each spawn type with individual rolls for better distribution
    if roll < self.spawnRates.onEnemyDeath.brown_box then
        -- Brown box (rare but rewarding)
        self:spawnItem("brown_box", enemyX, enemyY)
    elseif roll < (self.spawnRates.onEnemyDeath.brown_box + self.spawnRates.onEnemyDeath.credits) then
        -- Credits (common)
        self:spawnItem("credits", enemyX, enemyY)
    elseif healthPercent < 0.5 and roll < (self.spawnRates.onEnemyDeath.brown_box + self.spawnRates.onEnemyDeath.credits + self.spawnRates.onEnemyDeath.health) then
        -- Health orbs (only when health is low)
        self:spawnItem("health", enemyX, enemyY)
    elseif roll < (self.spawnRates.onEnemyDeath.brown_box + self.spawnRates.onEnemyDeath.credits + self.spawnRates.onEnemyDeath.parts) then
        -- Parts (rare)
        self:spawnItem("parts", enemyX, enemyY)
    elseif roll < (self.spawnRates.onEnemyDeath.brown_box + self.spawnRates.onEnemyDeath.credits + self.spawnRates.onEnemyDeath.inventory_item) then
        -- Direct inventory items (very rare)
        self:spawnItem("inventory_item", enemyX, enemyY)
    end
end

function ResourceSpawner:checkCoreSpawn()
    if self.coreSpawnTimer >= self.coreSpawnInterval then
        self.coreSpawnTimer = 0
        -- Increase interval to make cores progressively rarer
        self.coreSpawnInterval = self.coreSpawnInterval + 5
        return true
    end
    return false
end

function ResourceSpawner:checkBrownBoxSpawn()
    if self.brownBoxSpawnTimer >= self.brownBoxSpawnInterval then
        self.brownBoxSpawnTimer = 0
        -- Keep interval constant for consistent brown box spawns
        return true
    end
    return false
end

function ResourceSpawner:findSafeSpawnPosition(playerX, playerY, screenWidth, screenHeight, minDistance)
    minDistance = minDistance or 100
    local attempts = 0
    local x, y
    
    repeat
        x = love.math.random(50, screenWidth - 50)
        y = love.math.random(50, screenHeight - 50)
        attempts = attempts + 1
        local distance = math.sqrt((x - playerX)^2 + (y - playerY)^2)
    until distance > minDistance or attempts > 10
    
    return x, y
end

function ResourceSpawner:rollBrownBoxLoot()
    -- Calculate total weight
    local totalWeight = 0
    for _, loot in ipairs(self.brownBoxLootTable) do
        totalWeight = totalWeight + loot.weight
    end

    -- Roll for loot
    local roll = love.math.random() * totalWeight
    local currentWeight = 0

    for _, loot in ipairs(self.brownBoxLootTable) do
        currentWeight = currentWeight + loot.weight
        if roll <= currentWeight then
            local value = nil
            if loot.valueRange then
                value = love.math.random(loot.valueRange[1], loot.valueRange[2])
            end
            return loot.type, value
        end
    end

    -- Fallback to credits
    return "credits", 10
end

function ResourceSpawner:checkItemCollision(playerX, playerY, playerRadius)
    local collectedItems = {}
    
    for i = #self.items, 1, -1 do
        local item = self.items[i]
        local pickupRadius = item.r + playerRadius + 5 -- Extra pickup range
        local distance = math.sqrt((item.x - playerX)^2 + (item.y - playerY)^2)
        
        if distance < pickupRadius then
            table.insert(collectedItems, item)
            table.remove(self.items, i)
        end
    end
    
    return collectedItems
end

function ResourceSpawner:collectItem(item)
    local profile = _G.Game.PROFILE
    if not profile then return false end
    
    local result = { success = false, message = "", value = item.value }
    
    if item.type == "credits" then
        _G.Game.SaveSystem:addCredits(item.value)
        result.success = true
        result.message = string.format("Collected %d credits!", item.value)
        
    elseif item.type == "parts" then
        _G.Game.SaveSystem:addParts(item.value)
        result.success = true
        result.message = string.format("Collected %d parts!", item.value)
        
    elseif item.type == "cores" then
        _G.Game.SaveSystem:addCores(item.value)
        result.success = true
        result.message = string.format("Collected %d cores!", item.value)
        
    elseif item.type == "health" then
        result.success = true
        result.message = string.format("Restored %d health!", item.value)
        result.healthRestore = item.value
        
    elseif item.type == "inventory_item" and item.itemData then
        local added = _G.Game.SaveSystem:addItemById(item.itemData.id, item.itemData.name)
        if added then
            result.success = true
            result.message = string.format("Found new item: %s!", item.itemData.name)
            result.newItem = item.itemData
        else
            -- Convert duplicate to credits using configurable amount
            _G.Game.SaveSystem:addCredits(self.duplicateDirectItemCreditValue)
            result.success = true
            result.message = string.format("Already have %s, got %d credits instead!", item.itemData.name, self.duplicateDirectItemCreditValue)
            result.value = self.duplicateDirectItemCreditValue
        end

    elseif item.type == "brown_box" then
        -- Roll for random loot from brown box
        local lootType, lootValue = self:rollBrownBoxLoot()

        if lootType == "credits" then
            _G.Game.SaveSystem:addCredits(lootValue)
            result.success = true
            result.message = string.format("Brown box contained %d credits!", lootValue)
            result.value = lootValue
        elseif lootType == "parts" then
            _G.Game.SaveSystem:addParts(lootValue)
            result.success = true
            result.message = string.format("Brown box contained %d parts!", lootValue)
            result.value = lootValue
        elseif lootType == "cores" then
            _G.Game.SaveSystem:addCores(lootValue)
            result.success = true
            result.message = string.format("Brown box contained %d cores!", lootValue)
            result.value = lootValue
        elseif lootType == "inventory_item" then
            local itemPool = require("src.data.items")
            local randomItem = itemPool[love.math.random(#itemPool)]
            local added = _G.Game.SaveSystem:addItemById(randomItem.id, randomItem.name)
            if added then
                result.success = true
                result.message = string.format("Brown box contained: %s!", randomItem.name)
                result.newItem = randomItem
            else
                -- Convert duplicate to credits using configurable amount
                _G.Game.SaveSystem:addCredits(self.duplicateItemCreditValue)
                result.success = true
                result.message = string.format("Brown box had %s (duplicate), got %d credits instead!", randomItem.name, self.duplicateItemCreditValue)
                result.value = self.duplicateItemCreditValue
            end
        end
    end
    
    -- Play pickup sound
    if result.success and _G.Game.AudioSystem then
        _G.Game.AudioSystem:playUpgrade()
    end
    
    -- Save progress
    if result.success and profile then
        _G.Game.SaveSystem:save(profile)
    end
    
    return result
end

function ResourceSpawner:draw()
    for _, item in ipairs(self.items) do
        love.graphics.setColor(item.color)
        
        -- Bobbing effect
        local bobOffset = math.sin(item.bobTime) * 2
        local drawY = item.y + bobOffset
        
        -- Draw glow effect for valuable items
        if item.hasGlow then
            love.graphics.setColor(item.color[1], item.color[2], item.color[3], 0.3)
            love.graphics.circle("fill", item.x, drawY, item.r + 3)
            love.graphics.setColor(item.color)
        end
        
        -- Draw main item
        love.graphics.circle("fill", item.x, drawY, item.r)
        
        -- Draw pickup indicator for manual pickup items
        if not item.autoPickup then
            love.graphics.setColor(1, 1, 1, 0.8)
            love.graphics.circle("line", item.x, drawY, item.r + 8)
        end
    end
end

function ResourceSpawner:getItemCount()
    return #self.items
end

function ResourceSpawner:clear()
    self.items = {}
    self.coreSpawnTimer = 0
    self.coreSpawnInterval = 75
    self.brownBoxSpawnTimer = 0
    self.brownBoxSpawnInterval = 150
end

-- Helper functions for configuring duplicate conversion values
function ResourceSpawner:setDuplicateItemCreditValue(value)
    self.duplicateItemCreditValue = value
end

function ResourceSpawner:setDuplicateDirectItemCreditValue(value)
    self.duplicateDirectItemCreditValue = value
end

function ResourceSpawner:getDuplicateItemCreditValue()
    return self.duplicateItemCreditValue
end

function ResourceSpawner:getDuplicateDirectItemCreditValue()
    return self.duplicateDirectItemCreditValue
end

---Get resource spawner statistics
---@return table stats Spawner statistics
function ResourceSpawner:getStats()
    local itemCounts = {}
    for _, item in ipairs(self.items) do
        itemCounts[item.type] = (itemCounts[item.type] or 0) + 1
    end

    return {
        totalItems = #self.items,
        itemCounts = itemCounts,
        coreSpawnTimer = self.coreSpawnTimer,
        coreSpawnInterval = self.coreSpawnInterval,
        brownBoxSpawnTimer = self.brownBoxSpawnTimer,
        brownBoxSpawnInterval = self.brownBoxSpawnInterval,
        enabled = self.isEnabled,
        initialized = self.initialized
    }
end

---Set core spawn interval
---@param interval number New spawn interval in seconds
---@return boolean success Whether setting was successful
function ResourceSpawner:setCoreSpawnInterval(interval)
    if interval <= 0 then
        self:logError("Core spawn interval must be positive", "warning")
        return false
    end
    self.coreSpawnInterval = interval
    if self.config.debug then
        print(string.format("[ResourceSpawner] Core spawn interval set to %.1f seconds", interval))
    end
    return true
end

---Set brown box spawn interval
---@param interval number New spawn interval in seconds
---@return boolean success Whether setting was successful
function ResourceSpawner:setBrownBoxSpawnInterval(interval)
    if interval <= 0 then
        self:logError("Brown box spawn interval must be positive", "warning")
        return false
    end
    self.brownBoxSpawnInterval = interval
    if self.config.debug then
        print(string.format("[ResourceSpawner] Brown box spawn interval set to %.1f seconds", interval))
    end
    return true
end

return ResourceSpawner
