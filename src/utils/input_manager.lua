local BaseManager = require "src.managers.base_manager"

---@class InputManager : BaseManager
---@field keys table<string, boolean> Current key states
---@field keysPressed table<string, boolean> Keys pressed this frame
---@field keysReleased table<string, boolean> Keys released this frame
---@field mouseX number Current mouse X position
---@field mouseY number Current mouse Y position
---@field mouseDeltaX number Mouse movement delta X
---@field mouseDeltaY number Mouse movement delta Y
---@field mouseButtons table<number, boolean> Current mouse button states
---@field mouseButtonsPressed table<number, boolean> Mouse buttons pressed this frame
---@field mouseButtonsReleased table<number, boolean> Mouse buttons released this frame
---@field listeners table<string, function[]> Event listeners
InputManager = BaseManager:extend()

---Initialize the input manager
function InputManager:init(config)
    config = config or {}
    config.debug = config.debug or false

    BaseManager:init("InputManager", config)

    -- Ensure all state tables are initialized
    self.keys = self.keys or {}
    self.keysPressed = self.keysPressed or {}
    self.keysReleased = self.keysReleased or {}
    self.mouseButtons = self.mouseButtons or {}
    self.mouseButtonsPressed = self.mouseButtonsPressed or {}
    self.mouseButtonsReleased = self.mouseButtonsReleased or {}
    self.listeners = self.listeners or {}
    self.mouseX = 0
    self.mouseY = 0
end

---Update the input manager (call this every frame)
---@param dt number Delta time
function InputManager:update(dt)
    if not self:isActive() then return end
    -- Update mouse position and calculate delta
    local newMouseX, newMouseY = love.mouse.getPosition()
    self.mouseDeltaX = newMouseX - self.mouseX
    self.mouseDeltaY = newMouseY - self.mouseY
    self.mouseX = newMouseX
    self.mouseY = newMouseY
end

---Clear frame-based input states (call this at the END of the frame)
function InputManager:endFrame()
    -- Clear frame-based states after everything has been processed
    self.keysPressed = {}
    self.keysReleased = {}
    self.mouseButtonsPressed = {}
    self.mouseButtonsReleased = {}
end

-- === KEYBOARD FUNCTIONS ===

---Check if a key is currently held down
---@param key string The key to check
---@return boolean isDown True if the key is currently pressed
function InputManager:isKeyDown(key)
    return self.keys[key] or false
end

---Check if a key was just pressed this frame
---@param key string The key to check
---@return boolean wasPressed True if the key was pressed this frame
function InputManager:isKeyPressed(key)
    return self.keysPressed[key] or false
end

---Check if a key was just released this frame
---@param key string The key to check
---@return boolean wasReleased True if the key was released this frame
function InputManager:isKeyReleased(key)
    return self.keysReleased[key] or false
end

---Handle key press events (called by love.keypressed)
---@param key string The key that was pressed
---@param scancode string The scancode of the key
---@param isrepeat boolean Whether this is a key repeat
function InputManager:keypressed(key, scancode, isrepeat)
    if not isrepeat then
        self.keys[key] = true
        self.keysPressed[key] = true
        self:dispatchEvent("keypressed", {key = key, scancode = scancode, isrepeat = isrepeat})
    end
end

---Handle key release events (called by love.keyreleased)
---@param key string The key that was released
---@param scancode string The scancode of the key
function InputManager:keyreleased(key, scancode)
    self.keys[key] = false
    self.keysReleased[key] = true
    self:dispatchEvent("keyreleased", {key = key, scancode = scancode})
end

-- === MOUSE FUNCTIONS ===

---Check if a mouse button is currently held down
---@param button number The mouse button (1=left, 2=right, 3=middle)
---@return boolean isDown True if the button is currently pressed
function InputManager:isMouseDown(button)
    return self.mouseButtons[button] or false
end

---Check if a mouse button was just pressed this frame
---@param button number The mouse button (1=left, 2=right, 3=middle)
---@return boolean wasPressed True if the button was pressed this frame
function InputManager:isMousePressed(button)
    return self.mouseButtonsPressed[button] or false
end

---Check if a mouse button was just released this frame
---@param button number The mouse button (1=left, 2=right, 3=middle)
---@return boolean wasReleased True if the button was released this frame
function InputManager:isMouseReleased(button)
    return self.mouseButtonsReleased[button] or false
end

---Get current mouse position
---@return number x, number y Mouse coordinates
function InputManager:getMousePosition()
    return self.mouseX, self.mouseY
end

---Get mouse movement delta
---@return number deltaX, number deltaY Mouse movement since last frame
function InputManager:getMouseDelta()
    return self.mouseDeltaX, self.mouseDeltaY
end

---Handle mouse press events (called by love.mousepressed)
---@param x number Mouse X position
---@param y number Mouse Y position
---@param button number Mouse button that was pressed
---@param istouch boolean Whether this is a touch event
function InputManager:mousepressed(x, y, button, istouch)
    self.mouseButtons[button] = true
    self.mouseButtonsPressed[button] = true
    self:dispatchEvent("mousepressed", {x = x, y = y, button = button, istouch = istouch})
end

---Handle mouse release events (called by love.mousereleased)
---@param x number Mouse X position
---@param y number Mouse Y position
---@param button number Mouse button that was released
---@param istouch boolean Whether this is a touch event
function InputManager:mousereleased(x, y, button, istouch)
    self.mouseButtons[button] = false
    self.mouseButtonsReleased[button] = true
    self:dispatchEvent("mousereleased", {x = x, y = y, button = button, istouch = istouch})
end

---Handle mouse movement events (called by love.mousemoved)
---@param x number New mouse X position
---@param y number New mouse Y position
---@param dx number Mouse delta X
---@param dy number Mouse delta Y
---@param istouch boolean Whether this is a touch event
function InputManager:mousemoved(x, y, dx, dy, istouch)
    -- Mouse position is already updated in update(), but we dispatch the event
    self:dispatchEvent("mousemoved", {x = x, y = y, dx = dx, dy = dy, istouch = istouch})
end

-- === EVENT SYSTEM ===

---Register an event listener
---@param eventType string The type of event to listen for
---@param callback function The callback function to call
function InputManager:addEventListener(eventType, callback)
    if not self.listeners[eventType] then
        self.listeners[eventType] = {}
    end
    table.insert(self.listeners[eventType], callback)
end

---Remove an event listener
---@param eventType string The type of event
---@param callback function The callback function to remove
function InputManager:removeEventListener(eventType, callback)
    if not self.listeners[eventType] then return end
    
    for i, listener in ipairs(self.listeners[eventType]) do
        if listener == callback then
            table.remove(self.listeners[eventType], i)
            break
        end
    end
end

---Dispatch an event to all registered listeners
---@param eventType string The type of event to dispatch
---@param eventData table Event data to pass to listeners
function InputManager:dispatchEvent(eventType, eventData)
    local list = self.listeners[eventType]
    if not list then return end

    -- Iterate over a snapshot so listeners added/removed during dispatch
    -- do not receive the current event (prevents click-through on state switch)
    local snapshot = {}
    for i = 1, #list do snapshot[i] = list[i] end

    for i = 1, #snapshot do
        local callback = snapshot[i]
        if callback then callback(eventData) end
    end
end

-- === CONVENIENCE FUNCTIONS ===

---Check if any key is currently pressed
---@return boolean anyKeyDown True if any key is currently pressed
function InputManager:isAnyKeyDown()
    for _, pressed in pairs(self.keys) do
        if pressed then return true end
    end
    return false
end

---Check if any mouse button is currently pressed
---@return boolean anyButtonDown True if any mouse button is currently pressed
function InputManager:isAnyMouseDown()
    for _, pressed in pairs(self.mouseButtons) do
        if pressed then return true end
    end
    return false
end

---Get all keys that are currently pressed
---@return string[] pressedKeys Array of currently pressed key names
function InputManager:getPressedKeys()
    local pressed = {}
    for key, isPressed in pairs(self.keys) do
        if isPressed then
            table.insert(pressed, key)
        end
    end
    return pressed
end

---Get all mouse buttons that are currently pressed
---@return number[] pressedButtons Array of currently pressed mouse button numbers
function InputManager:getPressedMouseButtons()
    local pressed = {}
    for button, isPressed in pairs(self.mouseButtons) do
        if isPressed then
            table.insert(pressed, button)
        end
    end
    return pressed
end

---Handle screen resize
---@param w number New screen width
---@param h number New screen height
function InputManager:resize(w, h)
    if not self:isActive() then return end

    -- Update mouse position bounds if needed
    self.mouseX = math.min(self.mouseX, w)
    self.mouseY = math.min(self.mouseY, h)

    if self.config.debug then
        print(string.format("[InputManager] Screen resized to %dx%d", w, h))
    end
end

---Get current input statistics
---@return table stats Input manager statistics
function InputManager:getStats()
    local keyCount = 0
    for _ in pairs(self.keys) do keyCount = keyCount + 1 end

    local listenerCount = 0
    for _, listeners in pairs(self.listeners) do
        listenerCount = listenerCount + #listeners
    end

    return {
        activeKeys = keyCount,
        mouseX = self.mouseX,
        mouseY = self.mouseY,
        mouseDeltaX = self.mouseDeltaX,
        mouseDeltaY = self.mouseDeltaY,
        listenerCount = listenerCount,
        enabled = self.isEnabled,
        initialized = self.initialized
    }
end

---Check if any input is active
---@return boolean hasInput Whether any input is currently active
function InputManager:hasActiveInput()
    -- Check for active keys
    for _, pressed in pairs(self.keys) do
        if pressed then return true end
    end

    -- Check for active mouse buttons
    for _, pressed in pairs(self.mouseButtons) do
        if pressed then return true end
    end

    return false
end

---Clear all input states
function InputManager:clearAllInput()
    if not self:isActive() then return end

    self.keys = {}
    self.keysPressed = {}
    self.keysReleased = {}
    self.mouseButtons = {}
    self.mouseButtonsPressed = {}
    self.mouseButtonsReleased = {}
    self.mouseDeltaX = 0
    self.mouseDeltaY = 0

    if self.config.debug then
        print("[InputManager] Cleared all input states")
    end
end 