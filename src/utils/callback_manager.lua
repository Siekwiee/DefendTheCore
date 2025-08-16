---@class CallbackManager : Object
---@field callbacks table<string, function> Table of registered callbacks
CallbackManager = Object:extend()

function CallbackManager:init()
    self.callbacks = {}
end

---Register a callback function with a name
---@param name string The name to register the callback under
---@param callback function The callback function to register
function CallbackManager:register(name, callback)
    self.callbacks[name] = callback
end

---Execute a registered callback by name
---@param name string The name of the callback to execute
---@param ... any Arguments to pass to the callback
function CallbackManager:execute(name, ...)
    local callback = self.callbacks[name]
    if callback then
        callback(...)
    else
        print("Callback not found: " .. name)
    end
end

---Update an existing callback with a new function
---@param name string The name of the callback to update
---@param newCallback function The new callback function
function CallbackManager:updateCallback(name, newCallback)
    self.callbacks[name] = newCallback
end

-- TODO: needs testing
---Update the name of an existing callback
---@param name string The current name of the callback
---@param newName string The new name for the callback
function CallbackManager:updateCallbackName(name, newName)
    local tmp = self.callbacks[name]
    self.callbacks[name] = nil
    self.callbacks[newName] = tmp
end
