_G.Game = {
    VERSION = "0.0.1",
    GAME_NAME = "Defend the Core",
    
    -- Feature flags
    DEBUG = true, -- Debug mode

    -- Time
    SEED = os.time(),
    TIMERS = {
        TOTAL = 0,
        BACKGROUND = 0,
    },

    SETTINGS = {
        language = "en",
        showFPS = true,
        audio = {
            master = 0.8,
            sfx = 0.9,
            music = 0.5,
        }
    },

    -- Constants
    CONSTANTS = {
        UI = {
            DEFAULT_BACKGROUND = {
                color = {0, 0, 0, 0},
                drawMode = "none"
            }
        }
    },
    -- Colours
    
    -- Initialize managers
    StateManager = StateManager(),
    InputManager = InputManager(),
    CallbackManager = CallbackManager(),
    SaveSystem = nil, -- Will be initialized in main.lua
    PROFILE = nil, -- Will be loaded from save system
}