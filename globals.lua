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
}