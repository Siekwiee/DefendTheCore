---@class WaveManager : Object
---@field currentWave integer
---@field isActive boolean
---@field spawnTimer number
---@field spawnInterval number
---@field remaining integer
---@field intermission number
---@field spawnCallback fun(kind:string)
WaveManager = Object:extend()

function WaveManager:init(args)
    self.currentWave = 1
    self.isActive = false
    self.spawnTimer = 0
    self.spawnInterval = 1.0
    self.remaining = 0
    self.intermission = 0
    self.spawnCallback = args and args.spawnCallback
end

function WaveManager:setSpawnCallback(cb)
    self.spawnCallback = cb
end

function WaveManager:update(dt)
    if not self.isActive then
        if self.intermission > 0 then
            self.intermission = self.intermission - dt
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
    if not self.spawnCallback then return end
    if not self.spawnList or #self.spawnList == 0 then return end
    local kind = self.spawnList[((self.spawnIndex - 1) % #self.spawnList) + 1]
    self.spawnIndex = self.spawnIndex + 1
    self.spawnCallback(kind)
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

return WaveManager


