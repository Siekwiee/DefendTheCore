---@class RunState : Object
RunState = Object:extend()

function RunState:init()
    self.name = "Run"
    self.time = 0
end

function RunState:enter()
    -- Placeholder
end

function RunState:exit()
    -- Placeholder
end

function RunState:update(dt)
    self.time = self.time + dt
end

function RunState:draw()
    love.graphics.clear(0.02, 0.02, 0.03, 1)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Run state placeholder — press Esc to return", 40, 40)
end

function RunState:onEscape()
    _G.Game.StateManager:switchState("MainMenu")
end

function RunState:resize(w, h)
    -- Placeholder for future layout/rescale
end


