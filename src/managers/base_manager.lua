---@class BaseManager : Object
---@field name string Manager name for identification
---@field isEnabled boolean Whether the manager is enabled
---@field config table Configuration settings
---@field initialized boolean Whether the manager has been initialized
BaseManager = Object:extend()

---Initialize the base manager
---@param name string Manager name
---@param config table? Optional configuration
function BaseManager:init(name, config)
    self.name = name or "BaseManager"
    self.isEnabled = true
    self.config = config or {}
    self.initialized = false

    -- Default configuration
    self.config.debug = self.config.debug or false
    self.config.autoInit = self.config.autoInit or true

    if self.config.debug then
        print(string.format("[BaseManager] %s created with autoInit=%s", self.name, tostring(self.config.autoInit)))
    end

    if self.config.autoInit then
        self:initialize()
    end
end

---Initialize the manager (override in subclasses)
function BaseManager:initialize()
    if self.initialized then return end

    if self.config.debug then
        print(string.format("[BaseManager] Initializing %s", self.name))
    end

    self:setupDefaults()
    self:validateConfiguration()

    self.initialized = true

    if self.config.debug then
        print(string.format("[BaseManager] %s initialized successfully", self.name))
    end
end

---Setup default values (override in subclasses)
function BaseManager:setupDefaults()
    -- Override in subclasses
end

---Validate configuration (override in subclasses)
function BaseManager:validateConfiguration()
    -- Override in subclasses
end

---Update method called every frame
---@param dt number Delta time
function BaseManager:update(dt)
    if not self.isEnabled or not self.initialized then return end
    -- Override in subclasses
end

---Enable the manager
function BaseManager:enable()
    self.isEnabled = true
    if self.config.debug then
        print(string.format("[BaseManager] %s enabled", self.name))
    end
end

---Disable the manager
function BaseManager:disable()
    self.isEnabled = false
    if self.config.debug then
        print(string.format("[BaseManager] %s disabled", self.name))
    end
end

---Toggle manager enabled state
function BaseManager:toggle()
    if self.isEnabled then
        self:disable()
    else
        self:enable()
    end
end

---Check if manager is enabled
---@return boolean
function BaseManager:isActive()
    return (self.initialized == true) and (self.isEnabled == true)
end

---Get manager status information
---@return table
function BaseManager:getStatus()
    return {
        name = self.name,
        enabled = self.isEnabled,
        initialized = self.initialized,
        config = self.config
    }
end

---Clean up resources (override in subclasses)
function BaseManager:destroy()
    self.isEnabled = false
    self.initialized = false
    if self.config.debug then
        print(string.format("[BaseManager] %s destroyed", self.name))
    end
end

---Handle errors consistently
---@param message string Error message
---@param level string? Error level ("error", "warning", "info")
function BaseManager:logError(message, level)
    level = level or "error"
    local prefix = string.format("[%s:%s] ", self.name, level:upper())
    if level == "error" then
        error(prefix .. message)
    else
        print(prefix .. message)
    end
end

---Safely get configuration value with fallback
---@param key string Configuration key
---@param default any Default value if key doesn't exist
---@return any
function BaseManager:getConfig(key, default)
    if self.config and self.config[key] ~= nil then
        return self.config[key]
    end
    return default
end

---Update configuration value
---@param key string Configuration key
---@param value any New value
function BaseManager:setConfig(key, value)
    if not self.config then
        self.config = {}
    end
    self.config[key] = value
end

return BaseManager
