-- LÖVE2D Configuration File for Dirty Trading
-- Controls window settings, modules, and game configuration

function love.conf(t)
    -- Game identity
    t.identity = "DefendTheCore"
    t.version = "11.3"
    t.console = true -- Enable console for debugging
    
    -- Window settings
    t.window.title = "Defend The Core a game with one tower and one goal"
    t.window.icon = nil -- No icon for now
    t.window.width = 1920
    t.window.height = 1080
    t.window.minwidth = 1280
    t.window.minheight = 720
    t.window.resizable = true
    t.window.fullscreen = false
    t.window.fullscreentype = "desktop"
    t.window.vsync = false
    t.window.msaa = 0 -- No MSAA for performance
    t.window.depth = nil
    t.window.stencil = nil
    t.window.display = 1
    
    -- Modules
    t.modules.audio = true
    t.modules.data = true
    t.modules.event = true
    t.modules.font = true
    t.modules.graphics = true
    t.modules.image = true
    t.modules.joystick = false -- No joystick needed
    t.modules.keyboard = true
    t.modules.math = true
    t.modules.mouse = true
    t.modules.physics = false -- No physics needed
    t.modules.sound = true
    t.modules.system = true
    t.modules.timer = true
    t.modules.touch = false -- No touch needed
    t.modules.video = false -- No video needed
    t.modules.window = true
    
    -- File system
    t.window.x = nil -- Center window
    t.window.y = nil -- Center window
end 
