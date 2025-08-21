require "src.ECS.components.object"
require "src.ECS.components.transformable"
require "src.state.state_manager"
require "src.utils.input_manager"
require "src.state.main_menu_state"
require "src.utils.callback_manager"

require "globals"
---@type InputManager
local inputManager = _G.Game.InputManager
---@type StateManager
local stateManager = _G.Game.StateManager

---LÖVE initialization callback
function love.load()
    print("Game Version: ".._G.Game.VERSION)
    love.math.setRandomSeed(_G.Game.SEED)

    -- Initialize save system and load profile
    local SaveManager = require("src.managers.save_manager")
    _G.Game.SaveSystem = SaveManager()
    _G.Game.PROFILE = _G.Game.SaveSystem:load()

    -- Apply loaded settings to global settings
    if _G.Game.PROFILE.settings then
        for k, v in pairs(_G.Game.PROFILE.settings) do
            _G.Game.SETTINGS[k] = v
        end
    end

    -- Register states
    stateManager:registerState("MainMenu", MainMenuState())
    stateManager:registerState("Options", require("src.state.options_state")())
    stateManager:registerState("MainHub", require("src.state.main_hub_state")())
    stateManager:registerState("Inventory", require("src.state.inventory_state")())
    stateManager:registerState("Upgrades", require("src.state.upgrades_state")())
    stateManager:registerState("EndlessRun", require("src.state.endless_run_state")())

    -- Switch to main menu
    stateManager:switchState("MainMenu")
end

---LÖVE update callback
---@param dt number Delta time in seconds
function love.update(dt)
    if inputManager then
        inputManager:update(dt)
    end
    if stateManager then
        stateManager:update(dt)
    end
    -- Clear frame-based input states at the END of the frame
    if inputManager then
        inputManager:endFrame()
    end
end

---LÖVE draw callback
function love.draw()
    if stateManager then
        stateManager:draw()
    end
end

-- === INPUT CALLBACKS ===

function love.keypressed(key, scancode, isrepeat)
    if inputManager then
        inputManager:keypressed(key, scancode, isrepeat)
    end
end

function love.keyreleased(key, scancode)
    if inputManager then
        inputManager:keyreleased(key, scancode)
    end
end

function love.mousepressed(x, y, button, istouch)
    if inputManager then
        inputManager:mousepressed(x, y, button, istouch)
    end
end

function love.mousereleased(x, y, button, istouch)
    if inputManager then
        inputManager:mousereleased(x, y, button, istouch)
    end
end

function love.mousemoved(x, y, dx, dy, istouch)
    if inputManager then
        inputManager:mousemoved(x, y, dx, dy, istouch)
    end
end

function love.resize(w, h)
    if stateManager then
        stateManager:resize(w, h)
    end
end

---LÖVE quit callback
---@return boolean? prevent_quit Return true to prevent quitting
function love.quit()
    -- Save profile before quitting
    if _G.Game.SaveSystem and _G.Game.PROFILE then
        -- Update settings in profile before saving
        _G.Game.PROFILE.settings = _G.Game.SETTINGS
        _G.Game.SaveSystem:save(_G.Game.PROFILE)
    end

    if stateManager then
        stateManager:exit()
    end
end
