---@class SaveSystem : Object
SaveSystem = Object:extend()

function SaveSystem:init()
    self.saveFileName = "defendthecore_save.json"
    self.defaultProfile = {
        version = "1.0",
        settings = {
            showFPS = true,
            audio = {
                master = 0.8,
                sfx = 0.9,
                music = 0.5,
            }
        },
        player = {
            -- Resources
            credits = 500, -- start with some credits for testing purchases
            parts = 0,
            cores = 0,
            
            -- Progression
            totalRuns = 0,
            bestSurvivalTime = 0,
            totalEnemiesKilled = 0,
            bossesDefeated = 0,
            
            -- Permanent upgrades unlocked in hub
            permanentUpgrades = {},
            
            -- Inventory items
            inventory = {
                { id = "mod_speed", name = "Speed Mod", equipped = false },
                { id = "mod_damage", name = "Damage Mod", equipped = true },
            },

            -- Statistics
            stats = {
                damageDealt = 0,
                damageTaken = 0,
                projectilesFired = 0,
                upgradesChosen = 0,
            }
        }
    }
end

function SaveSystem:getDefaultProfile()
    -- Return a deep copy to avoid reference issues
    return self:deepCopy(self.defaultProfile)
end

function SaveSystem:deepCopy(original)
    local copy = {}
    for k, v in pairs(original) do
        if type(v) == "table" then
            copy[k] = self:deepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

function SaveSystem:saveExists()
    return love.filesystem.getInfo(self.saveFileName) ~= nil
end

function SaveSystem:save(profile)
    if not profile then
        print("[SaveSystem] Warning: Attempted to save nil profile")
        return false
    end
    
    -- Ensure version is set
    profile.version = profile.version or "1.0"
    
    local success, result = pcall(function()
        local json = self:encodeJSON(profile)
        return love.filesystem.write(self.saveFileName, json)
    end)
    
    if success and result then
        print("[SaveSystem] Save successful")
        return true
    else
        print("[SaveSystem] Save failed: " .. tostring(result))
        return false
    end
end

function SaveSystem:load()
    if not self:saveExists() then
        print("[SaveSystem] No save file found, creating default profile")
        return self:getDefaultProfile()
    end
    
    local success, result = pcall(function()
        local data = love.filesystem.read(self.saveFileName)
        return self:decodeJSON(data)
    end)
    
    if success and result then
        -- Validate and merge with defaults to handle version differences
        local profile = self:validateAndMergeProfile(result)
        print("[SaveSystem] Load successful")
        return profile
    else
        print("[SaveSystem] Load failed: " .. tostring(result) .. ", using default profile")
        return self:getDefaultProfile()
    end
end

function SaveSystem:validateAndMergeProfile(loadedProfile)
    local profile = self:getDefaultProfile()
    
    -- Merge loaded data with defaults (preserves new fields in updates)
    if loadedProfile.settings then
        self:mergeTable(profile.settings, loadedProfile.settings)
    end
    
    if loadedProfile.player then
        self:mergeTable(profile.player, loadedProfile.player)
    end
    
    -- Preserve version info
    profile.version = loadedProfile.version or "1.0"
    
    return profile
end

function SaveSystem:mergeTable(target, source)
    for k, v in pairs(source) do
        if type(v) == "table" and type(target[k]) == "table" then
            self:mergeTable(target[k], v)
        else
            target[k] = v
        end
    end
end

-- Simple JSON encoder (basic implementation)
function SaveSystem:encodeJSON(data)
    if type(data) == "table" then
        local isArray = true
        local maxIndex = 0
        for k, v in pairs(data) do
            if type(k) ~= "number" then
                isArray = false
                break
            end
            maxIndex = math.max(maxIndex, k)
        end
        
        if isArray then
            local result = "["
            for i = 1, maxIndex do
                if i > 1 then result = result .. "," end
                result = result .. self:encodeJSON(data[i])
            end
            return result .. "]"
        else
            local result = "{"
            local first = true
            for k, v in pairs(data) do
                if not first then result = result .. "," end
                first = false
                result = result .. '"' .. tostring(k) .. '":' .. self:encodeJSON(v)
            end
            return result .. "}"
        end
    elseif type(data) == "string" then
        return '"' .. data:gsub('"', '\\"') .. '"'
    elseif type(data) == "number" then
        return tostring(data)
    elseif type(data) == "boolean" then
        return data and "true" or "false"
    else
        return "null"
    end
end

-- Simple JSON decoder (basic implementation)
function SaveSystem:decodeJSON(str)
    -- Remove whitespace
    str = str:gsub("%s+", "")
    
    local function parseValue(s, pos)
        local char = s:sub(pos, pos)
        if char == "{" then
            return self:parseObject(s, pos)
        elseif char == "[" then
            return self:parseArray(s, pos)
        elseif char == '"' then
            return self:parseString(s, pos)
        elseif char:match("[%d%-]") then
            return self:parseNumber(s, pos)
        elseif s:sub(pos, pos + 3) == "true" then
            return true, pos + 4
        elseif s:sub(pos, pos + 4) == "false" then
            return false, pos + 5
        elseif s:sub(pos, pos + 3) == "null" then
            return nil, pos + 4
        end
    end
    
    self.parseValue = parseValue
    local result, _ = parseValue(str, 1)
    return result
end

function SaveSystem:parseObject(s, pos)
    local obj = {}
    pos = pos + 1 -- skip '{'
    
    if s:sub(pos, pos) == "}" then
        return obj, pos + 1
    end
    
    while true do
        local key, newPos = self:parseString(s, pos)
        pos = newPos
        
        -- Skip ':'
        pos = pos + 1
        
        local value
        value, pos = self.parseValue(s, pos)
        obj[key] = value
        
        local char = s:sub(pos, pos)
        if char == "}" then
            return obj, pos + 1
        elseif char == "," then
            pos = pos + 1
        end
    end
end

function SaveSystem:parseArray(s, pos)
    local arr = {}
    pos = pos + 1 -- skip '['
    
    if s:sub(pos, pos) == "]" then
        return arr, pos + 1
    end
    
    local index = 1
    while true do
        local value
        value, pos = self.parseValue(s, pos)
        arr[index] = value
        index = index + 1
        
        local char = s:sub(pos, pos)
        if char == "]" then
            return arr, pos + 1
        elseif char == "," then
            pos = pos + 1
        end
    end
end

function SaveSystem:parseString(s, pos)
    pos = pos + 1 -- skip opening '"'
    local endPos = s:find('"', pos)
    local str = s:sub(pos, endPos - 1)
    return str, endPos + 1
end

function SaveSystem:parseNumber(s, pos)
    local endPos = pos
    while endPos <= #s do
        local char = s:sub(endPos, endPos)
        if not char:match("[%d%.%-]") then
            break
        end
        endPos = endPos + 1
    end
    local numStr = s:sub(pos, endPos - 1)
    return tonumber(numStr), endPos
end

-- Utility methods for game systems
function SaveSystem:addCredits(amount)
    if _G.Game and _G.Game.PROFILE then
        _G.Game.PROFILE.player.credits = (_G.Game.PROFILE.player.credits or 0) + amount
    end
end

function SaveSystem:spendCredits(amount)
    if _G.Game and _G.Game.PROFILE then
        local current = _G.Game.PROFILE.player.credits or 0
        if current >= amount then
            _G.Game.PROFILE.player.credits = current - amount
            return true
        end
    end
    return false
end

function SaveSystem:getCredits()
    if _G.Game and _G.Game.PROFILE then
        return _G.Game.PROFILE.player.credits or 0
    end
    return 0
end

function SaveSystem:unlockPermanentUpgrade(upgradeId)
    if _G.Game and _G.Game.PROFILE then
        local upgrades = _G.Game.PROFILE.player.permanentUpgrades
        if not upgrades[upgradeId] then
            upgrades[upgradeId] = true
            return true
        end
    end
    return false
end

function SaveSystem:hasPermanentUpgrade(upgradeId)
    if _G.Game and _G.Game.PROFILE then
        return _G.Game.PROFILE.player.permanentUpgrades[upgradeId] == true
    end
    return false
end

-- Inventory helpers
function SaveSystem:getInventory()
    if _G.Game and _G.Game.PROFILE then
        _G.Game.PROFILE.player.inventory = _G.Game.PROFILE.player.inventory or {}
        return _G.Game.PROFILE.player.inventory
    end
    return {}
end

function SaveSystem:getEquippedCount()
    local inv = self:getInventory()
    local count = 0
    for _, item in ipairs(inv) do
        if item.equipped then count = count + 1 end
    end
    return count
end

function SaveSystem:hasItem(itemId)
    local inv = self:getInventory()
    for _, item in ipairs(inv) do
        if item.id == itemId then return true end
    end
    return false
end

function SaveSystem:addItemById(itemId, name)
    -- Avoid duplicates: if already exists, do nothing (or extend later with stacks)
    if self:hasItem(itemId) then return false end
    local inv = self:getInventory()
    table.insert(inv, { id = itemId, name = name or itemId, equipped = false })
    return true
end

function SaveSystem:toggleEquip(itemId, maxEquipped)
    local inv = self:getInventory()
    local equippedCount = self:getEquippedCount()
    for _, item in ipairs(inv) do
        if item.id == itemId then
            if item.equipped then
                item.equipped = false
                return true, "UNEQUIPPED"
            else
                if equippedCount >= (maxEquipped or 8) then
                    return false, "LIMIT_REACHED"
                end
                item.equipped = true
                return true, "EQUIPPED"
            end
        end
    end
    return false, "NOT_FOUND"
end

---Delete save file and reset in-memory profile to defaults
---@return boolean ok, string|nil err
function SaveSystem:deleteSave()
    local ok = true
    local err
    if love.filesystem.getInfo(self.saveFileName) then
        ok, err = love.filesystem.remove(self.saveFileName)
        if not ok then
            print("[SaveSystem] Delete failed: " .. tostring(err))
            return false, err
        end
    end
    -- Reset current profile to defaults for immediate testing
    if _G.Game then
        _G.Game.PROFILE = self:getDefaultProfile()
    end
    print("[SaveSystem] Save deleted. Profile reset to defaults.")
    return true
end

return SaveSystem
