local BaseManager = require "src.managers.base_manager"

---@class CallbackManager : BaseManager
---@field callbacks table<string, function> Table of registered callbacks
CallbackManager = BaseManager:extend()

function CallbackManager:init(config)
    config = config or {}
    config.debug = config.debug or false

    BaseManager:init("CallbackManager", config)

    -- Ensure callbacks table is initialized
    if not self.callbacks then
        self.callbacks = {}
    end
end

function CallbackManager:setupDefaults()
    self.callbacks = {}
    if self.config and self.config.debug then
        print("[CallbackManager] setupDefaults called, callbacks initialized")
    end
end

---Register a callback function with a name
---@param name string The name to register the callback under
---@param callback function The callback function to register
function CallbackManager:register(name, callback)
    if not self:isActive() then
        self:logError("Cannot register callback: CallbackManager is not active", "warning")
        return false
    end

    if not name or name == "" then
        self:logError("Cannot register callback: name is required", "warning")
        return false
    end

    if type(callback) ~= "function" then
        self:logError("Cannot register callback: callback must be a function", "warning")
        return false
    end

    self.callbacks[name] = callback

    if self.config.debug then
        print(string.format("[CallbackManager] Registered callback: %s", name))
    end

    return true
end

---Execute a registered callback by name
---@param name string The name of the callback to execute
---@param ... any Arguments to pass to the callback
---@return boolean success Whether execution was successful
---@return any result The result of the callback execution
function CallbackManager:execute(name, ...)
    if not self:isActive() then
        self:logError("Cannot execute callback: CallbackManager is not active", "warning")
        return false
    end

    local callback = self.callbacks[name]
    if callback then
        local success, result = pcall(callback, ...)
        if success then
            if self.config.debug then
                print(string.format("[CallbackManager] Executed callback: %s", name))
            end
            return true, result
        else
            self:logError("Error executing callback '" .. name .. "': " .. tostring(result), "warning")
            return false, result
        end
    else
        self:logError("Callback not found: " .. name, "warning")
        return false
    end
end

---Update an existing callback with a new function
---@param name string The name of the callback to update
---@param newCallback function The new callback function
---@return boolean success Whether the update was successful
function CallbackManager:updateCallback(name, newCallback)
    if not self:isActive() then
        self:logError("Cannot update callback: CallbackManager is not active", "warning")
        return false
    end

    if not name or not self.callbacks[name] then
        self:logError("Cannot update callback: callback '" .. (name or "nil") .. "' does not exist", "warning")
        return false
    end

    if type(newCallback) ~= "function" then
        self:logError("Cannot update callback: newCallback must be a function", "warning")
        return false
    end

    self.callbacks[name] = newCallback

    if self.config.debug then
        print(string.format("[CallbackManager] Updated callback: %s", name))
    end

    return true
end

---Update the name of an existing callback
---@param name string The current name of the callback
---@param newName string The new name for the callback
---@return boolean success Whether the rename was successful
function CallbackManager:updateCallbackName(name, newName)
    if not self:isActive() then
        self:logError("Cannot rename callback: CallbackManager is not active", "warning")
        return false
    end

    if not name or not self.callbacks[name] then
        self:logError("Cannot rename callback: callback '" .. (name or "nil") .. "' does not exist", "warning")
        return false
    end

    if not newName or newName == "" then
        self:logError("Cannot rename callback: newName is required", "warning")
        return false
    end

    local callback = self.callbacks[name]
    self.callbacks[name] = nil
    self.callbacks[newName] = callback

    if self.config.debug then
        print(string.format("[CallbackManager] Renamed callback: %s -> %s", name, newName))
    end

    return true
end

---Get all registered callback names
---@return table<string> names List of callback names
function CallbackManager:getCallbackNames()
    local names = {}
    for name, _ in pairs(self.callbacks) do
        table.insert(names, name)
    end
    return names
end

---Check if a callback exists
---@param name string Callback name to check
---@return boolean exists Whether the callback exists
function CallbackManager:hasCallback(name)
    return self.callbacks[name] ~= nil
end

---Get callback manager statistics
---@return table stats Callback manager statistics
function CallbackManager:getStats()
    local callbackCount = 0
    for _ in pairs(self.callbacks) do callbackCount = callbackCount + 1 end

    return {
        callbackCount = callbackCount,
        enabled = self.isEnabled,
        initialized = self.initialized
    }
end
