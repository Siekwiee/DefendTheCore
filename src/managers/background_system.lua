local BaseManager = require "src.managers.base_manager"

---@class BackgroundSystem : BaseManager
---@field time number Animation time
---@field gridSize number Grid size for background elements
---@field stars table Background stars
---@field nebulaClouds table Nebula cloud data
BackgroundSystem = BaseManager:extend()

function BackgroundSystem:init(config)
    config = config or {}
    config.debug = config.debug or false

    BaseManager:init("BackgroundSystem", config)

    self.time = 0
    self.gridSize = self:getConfig("gridSize", 40)
    self.stars = {}
    self.nebulaClouds = {}
    
    -- Generate starfield
    for i = 1, 150 do
        table.insert(self.stars, {
            x = love.math.random(0, love.graphics.getWidth()),
            y = love.math.random(0, love.graphics.getHeight()),
            brightness = love.math.random() * 0.8 + 0.2,
            twinkleSpeed = love.math.random() * 2 + 1,
            size = love.math.random() * 1.5 + 0.5
        })
    end
    
    -- Generate nebula clouds
    for i = 1, 8 do
        table.insert(self.nebulaClouds, {
            x = love.math.random(-100, love.graphics.getWidth() + 100),
            y = love.math.random(-100, love.graphics.getHeight() + 100),
            radius = love.math.random(80, 200),
            color = {
                love.math.random() * 0.3 + 0.1,
                love.math.random() * 0.2 + 0.05,
                love.math.random() * 0.4 + 0.2,
                0.1
            },
            driftSpeed = love.math.random() * 10 + 5
        })
    end
    
    -- Colors for the sci-fi atmosphere
    self.colors = {
        background = {0.02, 0.02, 0.05, 1},  -- Deep space blue
        grid = {0.1, 0.15, 0.3, 0.3},        -- Subtle blue grid
        gridPulse = {0.2, 0.4, 0.8, 0.6},    -- Brighter grid pulse
        star = {0.9, 0.95, 1.0, 1},          -- White stars
        coreField = {0.1, 0.3, 0.6, 0.1}     -- Core energy field
    }
end

function BackgroundSystem:update(dt)
    self.time = self.time + dt
    
    -- Drift nebula clouds
    for _, cloud in ipairs(self.nebulaClouds) do
        cloud.x = cloud.x + cloud.driftSpeed * dt
        -- Wrap around screen
        if cloud.x > love.graphics.getWidth() + cloud.radius then
            cloud.x = -cloud.radius
        end
    end
end

function BackgroundSystem:draw(coreX, coreY)
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    
    -- Background gradient
    self:drawGradientBackground(w, h)
    
    -- Nebula clouds
    self:drawNebulaClouds()
    
    -- Starfield
    self:drawStarfield()
    
    -- Grid overlay
    self:drawGrid(w, h)
    
    -- Core energy field
    if coreX and coreY then
        self:drawCoreField(coreX, coreY)
    end
end

function BackgroundSystem:drawGradientBackground(w, h)
    -- Create a subtle gradient from deep blue to black
    love.graphics.setColor(self.colors.background)
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    -- Add some depth with a radial gradient effect
    love.graphics.setColor(0.05, 0.08, 0.15, 0.5)
    local centerX, centerY = w * 0.5, h * 0.5
    for i = 1, 5 do
        local radius = (i / 5) * math.max(w, h) * 0.7
        local alpha = (1 - i / 5) * 0.1
        love.graphics.setColor(0.05, 0.08, 0.15, alpha)
        love.graphics.circle("fill", centerX, centerY, radius)
    end
end

function BackgroundSystem:drawNebulaClouds()
    for _, cloud in ipairs(self.nebulaClouds) do
        love.graphics.setColor(cloud.color)
        -- Draw multiple overlapping circles for cloud effect
        for j = 1, 3 do
            local offsetX = math.sin(self.time * 0.5 + j) * 20
            local offsetY = math.cos(self.time * 0.3 + j) * 15
            love.graphics.circle("fill", cloud.x + offsetX, cloud.y + offsetY, cloud.radius * (0.8 + j * 0.1))
        end
    end
end

function BackgroundSystem:drawStarfield()
    for _, star in ipairs(self.stars) do
        local twinkle = math.sin(self.time * star.twinkleSpeed) * 0.3 + 0.7
        love.graphics.setColor(self.colors.star[1], self.colors.star[2], self.colors.star[3], star.brightness * twinkle)
        love.graphics.circle("fill", star.x, star.y, star.size)
    end
end

function BackgroundSystem:drawGrid(w, h)
    -- Animated grid lines
    local pulse = math.sin(self.time * 2) * 0.3 + 0.7
    love.graphics.setColor(self.colors.grid[1], self.colors.grid[2], self.colors.grid[3], self.colors.grid[4] * pulse)
    
    -- Vertical lines
    for x = 0, w, self.gridSize do
        love.graphics.line(x, 0, x, h)
    end
    
    -- Horizontal lines
    for y = 0, h, self.gridSize do
        love.graphics.line(0, y, w, y)
    end
    
    -- Highlight some grid intersections with pulses
    love.graphics.setColor(self.colors.gridPulse[1], self.colors.gridPulse[2], self.colors.gridPulse[3], self.colors.gridPulse[4] * pulse * 0.5)
    for x = 0, w, self.gridSize * 3 do
        for y = 0, h, self.gridSize * 3 do
            local distance = math.sqrt((x - w/2)^2 + (y - h/2)^2)
            local delay = distance * 0.01
            local localPulse = math.sin(self.time * 3 - delay) * 0.5 + 0.5
            if localPulse > 0.7 then
                love.graphics.circle("fill", x, y, 2)
            end
        end
    end
end

function BackgroundSystem:drawCoreField(coreX, coreY)
    -- Energy field around the core
    love.graphics.setColor(self.colors.coreField)
    local fieldRadius = 150 + math.sin(self.time * 2) * 20
    love.graphics.circle("fill", coreX, coreY, fieldRadius)
    
    -- Energy rings
    for i = 1, 3 do
        local ringRadius = 100 + i * 30 + math.sin(self.time * (2 + i * 0.5)) * 10
        local alpha = (0.2 - i * 0.05) * (math.sin(self.time * 2 + i) * 0.5 + 0.5)
        love.graphics.setColor(0.2, 0.5, 1.0, alpha)
        love.graphics.circle("line", coreX, coreY, ringRadius)
    end
end

function BackgroundSystem:resize(w, h)
    -- Regenerate stars for new screen size
    self.stars = {}
    for i = 1, 150 do
        table.insert(self.stars, {
            x = love.math.random(0, w),
            y = love.math.random(0, h),
            brightness = love.math.random() * 0.8 + 0.2,
            twinkleSpeed = love.math.random() * 2 + 1,
            size = love.math.random() * 1.5 + 0.5
        })
    end
    
    -- Adjust nebula clouds
    for _, cloud in ipairs(self.nebulaClouds) do
        if cloud.x > w then cloud.x = love.math.random(-100, w) end
        if cloud.y > h then cloud.y = love.math.random(-100, h) end
    end
end

return BackgroundSystem
