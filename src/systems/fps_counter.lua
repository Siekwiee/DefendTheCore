---@class FPSCounter : Object
FPSCounter = Object:extend()

function FPSCounter:init()
    self.enabled = true
    self.frameCount = 0
    self.timeAccumulator = 0
    self.currentFPS = 0
    self.updateInterval = 0.5  -- Update FPS display every 0.5 seconds
    
    -- Position in top-right corner
    self.x = love.graphics.getWidth() - 80
    self.y = 10
    
    -- Visual styling
    self.font = love.graphics.getFont()
    self.backgroundColor = {0, 0, 0, 0.7}
    self.textColor = {1, 1, 1, 0.9}
    self.padding = 8
end

function FPSCounter:update(dt)
    if not self.enabled then return end
    
    self.frameCount = self.frameCount + 1
    self.timeAccumulator = self.timeAccumulator + dt
    
    if self.timeAccumulator >= self.updateInterval then
        self.currentFPS = math.floor(self.frameCount / self.timeAccumulator + 0.5)
        self.frameCount = 0
        self.timeAccumulator = 0
    end
end

function FPSCounter:draw()
    if not self.enabled then return end
    
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

function FPSCounter:toggle()
    self.enabled = not self.enabled
end

function FPSCounter:setEnabled(enabled)
    self.enabled = enabled
end

function FPSCounter:isEnabled()
    return self.enabled
end

function FPSCounter:resize(w, h)
    -- Update position when screen resizes
    local fpsText = "FPS: " .. tostring(self.currentFPS)
    local textWidth = self.font:getWidth(fpsText)
    self.x = w - textWidth - self.padding * 2 - 10
end

return FPSCounter
