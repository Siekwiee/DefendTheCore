---@class StateManager : Object
---@field states table<string, table> Table of available states
---@field currentState table? Current state table
---@field currentStateName string? Name of current state
---@field totalTime number Total time elapsed
---@field dt number Delta time
StateManager = Object:extend()

---Initialize a new StateManager
function StateManager:init()
    self.states = {}
    self.currentState = nil
    self.currentStateName = nil
end

---Register a state with the manager
---@param name string Name of state
---@param state table State to register
function StateManager:registerState(name, state)
    if name and state then
        -- Clean up old state if it exists
        if self.states[name] and self.states[name].exit then
            self.states[name]:exit()
        end
        self.states[name] = state
    else
        error("State name and state are required to register a state")
    end
end

---Switch to a different state
---@param stateName string Name of the state registered
function StateManager:switchState(stateName)
    if self.states[stateName] == nil then
        error("State name not found in registered states please register a stage before switching to it")
    else
        if self.currentState ~= nil and self.currentState.exit then
            self.currentState:exit()
        end
        self.currentState = self.states[stateName]
        self.currentStateName = stateName
        if self.currentState.enter then
            self.currentState:enter()
        end
        -- Ensure new state is aware of current window size -- TODO: new code from AI please test if needed
        if self.currentState.resize then
            local w, h = love.graphics.getWidth(), love.graphics.getHeight()
            self.currentState:resize(w, h)
        end
    end
end

---Get the current state
---@return table? currentState
function StateManager:getCurrentState()
    return self.currentState
end

---Get the current state name
---@return string? currentStateName
function StateManager:getCurrentStateName()
    return self.currentStateName
end

---Update the current state
---@param dt number Delta time
function StateManager:update(dt)
    if self.currentState and self.currentState.update then
        self.currentState:update(dt)
    end
    
    -- Forward important input events to the current state
    if self.currentState then
        -- Check for escape key to go back to main menu (common pattern)
        if _G.Game.InputManager:isKeyPressed("escape") and self.currentStateName ~= "MainMenu" then
            if self.currentState.onEscape then
                self.currentState:onEscape()
            else
                -- Default behavior: return to main menu
                self:switchState("MainMenu")
            end
        end
        
        -- Forward other input events if the state wants to handle them
        if self.currentState.handleInput then
            self.currentState:handleInput(_G.Game.InputManager)
        end
    end
end

function StateManager:resize(w, h)
    if self.currentState and self.currentState.resize then
        self.currentState:resize(w, h)
    end
end

---Draw the current state
function StateManager:draw()
    if self.currentState and self.currentState.draw then
        self.currentState:draw()
    end
end

---Exit the state manager
function StateManager:exit()
    print("Quitting game because StateManager exited")
    love.event.quit()
end
