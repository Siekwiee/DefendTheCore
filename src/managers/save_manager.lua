local BaseManager = require "src.managers.base_manager"

---@class SaveManager : BaseManager
---@field saveFileName string Save file name
---@field defaultProfile table Default profile template
---@field currentProfile table? Currently loaded profile
SaveManager = BaseManager:extend()

function SaveManager:init(config)
    config = config or {}
    config.debug = config.debug or false

    BaseManager:init("SaveManager", config)

    -- Save system specific configuration
    self.saveFileName = self:getConfig("saveFileName", "defendthecore_save.json")
    self.currentProfile = nil

    -- Initialize default profile template
    self:createDefaultProfile()
end

function SaveManager:setupDefaults()
    -- Create default profile template
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

            -- Permanent upgrades with levels (0 = not purchased, 1+ = level)
            permanentUpgrades = {},

            -- Inventory items (start with empty inventory)
            inventory = {},

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

function SaveManager:createDefaultProfile()
    self:setupDefaults()
end

function SaveManager:getDefaultProfile()
    -- Return a deep copy to avoid reference issues
    return self:deepCopy(self.defaultProfile)
end

function SaveManager:deepCopy(original)
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

function SaveManager:saveExists()
    return love.filesystem.getInfo(self.saveFileName) ~= nil
end

---Save profile to file
---@param profile table Profile to save
---@return boolean success Whether save was successful
---@return string? error Error message if save failed
function SaveManager:save(profile)
    if not profile then
        self:logError("Attempted to save nil profile", "warning")
        return false, "Profile is nil"
    end

    if not self:isActive() then
        self:logError("Cannot save: SaveManager is not active", "warning")
        return false, "SaveManager is not active"
    end

    -- Ensure version is set
    profile.version = profile.version or "1.0"
    profile.lastSaved = os.date("%Y-%m-%d %H:%M:%S")

    local success, result = pcall(function()
        local json = self:encodeJSON(profile)
        return love.filesystem.write(self.saveFileName, json)
    end)

    if success and result then
        if self.config.debug then
            print("[SaveSystem] Save successful")
        end
        return true
    else
        self:logError("Save failed: " .. tostring(result), "warning")
        return false, tostring(result)
    end
end

---Load profile from file
---@return table profile Loaded profile or default profile if loading fails
function SaveManager:load()
    if not self:isActive() then
        self:logError("Cannot load: SaveManager is not active", "warning")
        return self:getDefaultProfile()
    end

    if not self:saveExists() then
        if self.config.debug then
            print("[SaveSystem] No save file found, creating default profile")
        end
        return self:getDefaultProfile()
    end

    local success, result = pcall(function()
        local data = love.filesystem.read(self.saveFileName)
        return self:decodeJSON(data)
    end)

    if success and result then
        -- Validate and merge with defaults to handle version differences
        local profile = self:validateAndMergeProfile(result)
        if self.config.debug then
            print("[SaveSystem] Load successful")
        end
        return profile
    else
        self:logError("Load failed: " .. tostring(result) .. ", using default profile", "warning")
        return self:getDefaultProfile()
    end
end

function SaveManager:validateAndMergeProfile(loadedProfile)
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

function SaveManager:mergeTable(target, source)
    for k, v in pairs(source) do
        if type(v) == "table" and type(target[k]) == "table" then
            self:mergeTable(target[k], v)
        else
            target[k] = v
        end
    end
end

-- Simple JSON encoder (basic implementation)
function SaveManager:encodeJSON(data)
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
function SaveManager:decodeJSON(str)
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

function SaveManager:parseObject(s, pos)
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

function SaveManager:parseArray(s, pos)
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

function SaveManager:parseString(s, pos)
    pos = pos + 1 -- skip opening '"'
    local endPos = s:find('"', pos)
    local str = s:sub(pos, endPos - 1)
    return str, endPos + 1
end

function SaveManager:parseNumber(s, pos)
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
function SaveManager:addCredits(amount)
    if _G.Game and _G.Game.PROFILE then
        _G.Game.PROFILE.player.credits = (_G.Game.PROFILE.player.credits or 0) + amount
    end
end

function SaveManager:addParts(amount)
    if _G.Game and _G.Game.PROFILE then
        _G.Game.PROFILE.player.parts = (_G.Game.PROFILE.player.parts or 0) + amount
    end
end

function SaveManager:addCores(amount)
    if _G.Game and _G.Game.PROFILE then
        _G.Game.PROFILE.player.cores = (_G.Game.PROFILE.player.cores or 0) + amount
    end
end

function SaveManager:spendCredits(amount)
    if _G.Game and _G.Game.PROFILE then
        local current = _G.Game.PROFILE.player.credits or 0
        if current >= amount then
            _G.Game.PROFILE.player.credits = current - amount
            return true
        end
    end
    return false
end

function SaveManager:getCredits()
    if _G.Game and _G.Game.PROFILE then
        return _G.Game.PROFILE.player.credits or 0
    end
    return 0
end

function SaveManager:unlockPermanentUpgrade(upgradeId)
    if _G.Game and _G.Game.PROFILE then
        local upgrades = _G.Game.PROFILE.player.permanentUpgrades
        local currentLevel = upgrades[upgradeId] or 0
        upgrades[upgradeId] = currentLevel + 1
        return true
    end
    return false
end

function SaveManager:hasPermanentUpgrade(upgradeId)
    if _G.Game and _G.Game.PROFILE then
        local level = _G.Game.PROFILE.player.permanentUpgrades[upgradeId] or 0
        return level > 0
    end
    return false
end

function SaveManager:getPermanentUpgradeLevel(upgradeId)
    if _G.Game and _G.Game.PROFILE then
        local level = _G.Game.PROFILE.player.permanentUpgrades[upgradeId]
        -- Handle legacy boolean values from old save format
        if level == true then
            -- Convert old boolean format to level 1 and update the save
            _G.Game.PROFILE.player.permanentUpgrades[upgradeId] = 1
            -- Save the updated profile to migrate old format
            if _G.Game.PROFILE then
                self:save(_G.Game.PROFILE)
            end
            return 1
        elseif level == false or level == nil then
            return 0
        else
            return level
        end
    end
    return 0
end

function SaveManager:canUpgrade(upgradeId, maxLevel)
    if _G.Game and _G.Game.PROFILE then
        local currentLevel = self:getPermanentUpgradeLevel(upgradeId)
        return currentLevel < maxLevel
    end
    return false
end

-- Inventory helpers
function SaveManager:getInventory()
    if _G.Game and _G.Game.PROFILE then
        _G.Game.PROFILE.player.inventory = _G.Game.PROFILE.player.inventory or {}
        return _G.Game.PROFILE.player.inventory
    end
    return {}
end

function SaveManager:getEquippedCount()
    local inv = self:getInventory()
    local count = 0
    for _, item in ipairs(inv) do
        if item.equipped then count = count + 1 end
    end
    return count
end

function SaveManager:hasItem(itemId)
    local inv = self:getInventory()
    for _, item in ipairs(inv) do
        if item.id == itemId then return true end
    end
    return false
end

function SaveManager:addItemById(itemId, name)
    -- Avoid duplicates: if already exists, do nothing (or extend later with stacks)
    if self:hasItem(itemId) then return false end
    local inv = self:getInventory()
    table.insert(inv, { id = itemId, name = name or itemId, equipped = false })
    return true
end

function SaveManager:toggleEquip(itemId, maxEquipped)
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
---@return boolean success Whether deletion was successful
---@return string? error Error message if deletion failed
function SaveManager:deleteSave()
    if not self:isActive() then
        self:logError("Cannot delete: SaveManager is not active", "warning")
        return false, "SaveManager is not active"
    end

    local ok = true
    local err
    if love.filesystem.getInfo(self.saveFileName) then
        ok, err = love.filesystem.remove(self.saveFileName)
        if not ok then
            self:logError("Delete failed: " .. tostring(err), "warning")
            return false, err
        end
    end

    -- Reset current profile to defaults for immediate testing
    if _G.Game then
        _G.Game.PROFILE = self:getDefaultProfile()
    end

    if self.config.debug then
        print("[SaveManager] Save deleted. Profile reset to defaults.")
    end
    return true
end

---Get current profile
---@return table? profile Current loaded profile
function SaveManager:getCurrentProfile()
    return self.currentProfile
end

---Set current profile
---@param profile table Profile to set as current
---@return boolean success Whether setting was successful
function SaveManager:setCurrentProfile(profile)
    if not profile then
        self:logError("Cannot set nil profile", "warning")
        return false
    end
    self.currentProfile = profile
    return true
end

---Reset profile to defaults
---@return table newProfile New default profile
function SaveManager:resetProfile()
    self.currentProfile = self:getDefaultProfile()
    if self.config.debug then
        print("[SaveManager] Profile reset to defaults")
    end
    return self.currentProfile
end

return SaveManager
