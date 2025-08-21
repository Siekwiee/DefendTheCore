local BaseManager = require "src.managers.base_manager"

---@class FPSCounter : BaseManager
---@field frameCount number Number of frames counted
---@field timeAccumulator number Time accumulated for FPS calculation
---@field currentFPS number Current calculated FPS
---@field updateInterval number How often to update FPS display (seconds)
---@field x number X position on screen
---@field y number Y position on screen
---@field backgroundColor table Background color {r,g,b,a}
---@field textColor table Text color {r,g,b,a}
---@field padding number Padding around the text
FPSCounter = BaseManager:extend()

function FPSCounter:init(config)
    config = config or {}
    config.debug = config.debug or false

    BaseManager:init("FPSCounter", config)

    -- FPS calculation variables
    self.frameCount = 0
    self.timeAccumulator = 0
    self.currentFPS = 0
    self.updateInterval = self:getConfig("updateInterval", 0.5)

    -- Positioning and styling
    self.x = self:getConfig("x", love.graphics.getWidth() - 80)
    self.y = self:getConfig("y", 10)
    self.padding = self:getConfig("padding", 8)
end

function FPSCounter:setupDefaults()
    -- Set up default visual styling
    self.font = love.graphics.getFont()
    self.backgroundColor = self:getConfig("backgroundColor", {0, 0, 0, 0.7})
    self.textColor = self:getConfig("textColor", {1, 1, 1, 0.9})
end

function FPSCounter:update(dt)
    if not self:isActive() then return end

    self.frameCount = self.frameCount + 1
    self.timeAccumulator = self.timeAccumulator + dt

    if self.timeAccumulator >= self.updateInterval then
        self.currentFPS = math.floor(self.frameCount / self.timeAccumulator + 0.5)
        self.frameCount = 0
        self.timeAccumulator = 0
    end
end

function FPSCounter:draw()
    if not self:isActive() then return end

    local fpsText = "FPS: " .. tostring(self.currentFPS)
    local textWidth = self.font:getWidth(fpsText)
    local textHeight = self.font:getHeight()

    -- Update position for current screen size
    self.x = love.graphics.getWidth() - textWidth - self.padding * 2 - 10

    -- Draw background
    love.graphics.setColor(self.backgroundColor)
    love.graphics.rectangle("fill",
        self.x - self.padding,
        self.y - self.padding,
        textWidth + self.padding * 2,
        textHeight + self.padding * 2
    )

    -- Draw text
    love.graphics.setColor(self.textColor)
    love.graphics.print(fpsText, self.x, self.y)

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

---Toggle FPS counter visibility
function FPSCounter:toggle()
    if self.enabled then
        self:disable()
    else
        self:enable()
    end
end

---Check if FPS counter is enabled
---@return boolean
function FPSCounter:isEnabled()
    return self.isEnabled
end

---Handle screen resize
---@param w number New screen width
---@param h number New screen height
function FPSCounter:resize(w, h)
    if not self:isActive() then return end

    local fpsText = "FPS: " .. tostring(self.currentFPS)
    local textWidth = self.font:getWidth(fpsText)
    self.x = w - textWidth - self.padding * 2 - 10
end

---Get current FPS value
---@return number fps Current FPS
function FPSCounter:getCurrentFPS()
    return self.currentFPS
end

---Set update interval for FPS calculation
---@param interval number Update interval in seconds
function FPSCounter:setUpdateInterval(interval)
    self.updateInterval = math.max(0.1, interval)  -- Minimum 0.1 seconds
    if self.config.debug then
        print(string.format("[FPSCounter] Update interval set to %.2f seconds", self.updateInterval))
    end
end

---Get FPS counter statistics
---@return table stats FPS statistics
function FPSCounter:getStats()
    return {
        currentFPS = self.currentFPS,
        frameCount = self.frameCount,
        timeAccumulator = self.timeAccumulator,
        updateInterval = self.updateInterval,
        enabled = self.isEnabled,
        initialized = self.initialized
    }
end

return FPSCounter
