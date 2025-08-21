local BaseManager = require "src.managers.base_manager"

---@class WaveManager : BaseManager
---@field currentWave integer Current wave number
---@field isActive boolean Whether wave spawning is active
---@field spawnTimer number Timer for spawn intervals
---@field spawnInterval number Time between spawns
---@field remaining integer Number of enemies remaining to spawn
---@field intermission number Time remaining in intermission
---@field spawnCallback fun(kind:string)? Callback for spawning enemies
---@field spawnList table? List of enemy types to spawn
---@field spawnIndex integer Current position in spawn list
WaveManager = BaseManager:extend()

function WaveManager:init(config)
    config = config or {}
    config.debug = config.debug or false

    BaseManager:init("WaveManager", config)

    -- Wave management state
    self.currentWave = self:getConfig("startingWave", 1)
    self.isActive = false
    self.spawnTimer = 0
    self.spawnInterval = self:getConfig("defaultSpawnInterval", 1.0)
    self.remaining = 0
    self.intermission = 0
    self.spawnCallback = config.spawnCallback
    self.spawnList = nil
    self.spawnIndex = 1
end

function WaveManager:setSpawnCallback(cb)
    self.spawnCallback = cb
end

function WaveManager:update(dt)
    if not self:isActive() then return end

    if not self.isActive then
        if self.intermission > 0 then
            self.intermission = math.max(0, self.intermission - dt)
        end
        return
    end

    if self.remaining > 0 then
        self.spawnTimer = self.spawnTimer + dt
        if self.spawnTimer >= self.spawnInterval then
            self.spawnTimer = self.spawnTimer - self.spawnInterval
            self:spawnOne()
            self.remaining = self.remaining - 1
        end
    end
end

function WaveManager:beginWave(n)
    self.currentWave = n
    local cfg = self:_makeConfig(n)
    self.spawnInterval = cfg.interval
    self.remaining = cfg.total
    self.spawnList = cfg.list
    self.spawnIndex = 1
    self.spawnTimer = 0
    self.isActive = true
    self.intermission = 0
end

function WaveManager:endWave()
    self.isActive = false
    self.intermission = 2.0
end

function WaveManager:getIntermission()
    return self.intermission
end

function WaveManager:spawnOne()
    if not self:isActive() then
        self:logError("Cannot spawn: WaveManager is not active", "warning")
        return false
    end

    if not self.spawnCallback then
        self:logError("No spawn callback set", "warning")
        return false
    end

    if not self.spawnList or #self.spawnList == 0 then
        self:logError("No spawn list configured", "warning")
        return false
    end

    local kind = self.spawnList[((self.spawnIndex - 1) % #self.spawnList) + 1]
    self.spawnIndex = self.spawnIndex + 1
    self.spawnCallback(kind)

    if self.config.debug then
        print(string.format("[WaveManager] Spawned enemy: %s", kind))
    end

    return true
end

-- Build the wave config: spawn list, interval, total count
function WaveManager:_makeConfig(n)
    local list = {}
    local function add(kind, count)
        for i = 1, count do table.insert(list, kind) end
    end

    -- Composition ramps with wave
    if n < 3 then
        add("runner", 6 + n * 2)
    elseif n < 5 then
        add("runner", 6 + n)
        add("swarm", 4 + n)
    elseif n < 7 then
        add("runner", 6)
        add("swarm", 6 + n)
        add("tank", 2 + math.floor(n/2))
    elseif n < 9 then
        add("runner", 6)
        add("swarm", 8)
        add("tank", 4)
        add("shield", 2)
    elseif n == 10 then
        add("boss", 1)
        add("runner", 8)
        add("swarm", 10)
    else
        -- Post-10: scale up
        add("runner", 8 + math.floor(n*0.5))
        add("swarm", 10 + math.floor(n*0.5))
        add("tank", 4 + math.floor(n*0.3))
        add("shield", 2 + math.floor(n*0.2))
        if n % 10 == 0 then add("boss", 1) end
    end

    local total = #list
    local baseInterval = 1.2
    local interval = math.max(0.25, baseInterval - (n-1) * 0.05)
    return { list = list, interval = interval, total = total }
end

---Get wave manager statistics
---@return table stats Wave manager statistics
function WaveManager:getStats()
    return {
        currentWave = self.currentWave,
        isActive = self.isActive,
        remaining = self.remaining,
        intermission = self.intermission,
        spawnTimer = self.spawnTimer,
        spawnInterval = self.spawnInterval,
        spawnListSize = self.spawnList and #self.spawnList or 0,
        spawnIndex = self.spawnIndex,
        enabled = self.isEnabled,
        initialized = self.initialized
    }
end

---Set default spawn interval
---@param interval number New default spawn interval
---@return boolean success Whether setting was successful
function WaveManager:setDefaultSpawnInterval(interval)
    if interval <= 0 then
        self:logError("Spawn interval must be positive", "warning")
        return false
    end
    self.spawnInterval = interval
    if self.config.debug then
        print(string.format("[WaveManager] Default spawn interval set to %.2f seconds", interval))
    end
    return true
end

---Get current wave configuration
---@return table? config Current wave configuration
function WaveManager:getCurrentWaveConfig()
    if not self.isActive then return nil end
    return {
        wave = self.currentWave,
        remaining = self.remaining,
        total = self.spawnList and #self.spawnList or 0,
        interval = self.spawnInterval
    }
end

---Skip current wave and move to next
function WaveManager:skipWave()
    if not self:isActive() then
        self:logError("Cannot skip: WaveManager is not active", "warning")
        return false
    end

    self:endWave()
    if self.config.debug then
        print(string.format("[WaveManager] Skipped wave %d", self.currentWave))
    end
    return true
end

return WaveManager


