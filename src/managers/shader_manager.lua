---@class ShaderManager : Object
ShaderManager = Object:extend()

function ShaderManager:init()
    self.shaders = {}
    self.effects = {}
    self.time = 0
    
    -- Load shaders
    self:loadShaders()
end

function ShaderManager:loadShaders()
    -- Glow shader for core and special effects
    local glowVertexCode = [[
        vec4 position(mat4 transform_projection, vec4 vertex_position) {
            return transform_projection * vertex_position;
        }
    ]]
    
    local glowFragmentCode = [[
        uniform float time;
        uniform vec3 glowColor;
        uniform float intensity;
        
        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
            vec4 texcolor = Texel(texture, texture_coords);
            
            // Pulsing glow effect
            float pulse = 0.8 + 0.2 * sin(time * 3.0);
            vec3 glow = glowColor * intensity * pulse;
            
            return vec4(texcolor.rgb + glow, texcolor.a) * color;
        }
    ]]
    
    -- Damage flash shader
    local flashVertexCode = [[
        vec4 position(mat4 transform_projection, vec4 vertex_position) {
            return transform_projection * vertex_position;
        }
    ]]
    
    local flashFragmentCode = [[
        uniform float flashIntensity;
        uniform vec3 flashColor;
        
        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
            vec4 texcolor = Texel(texture, texture_coords);
            vec3 flash = mix(texcolor.rgb, flashColor, flashIntensity);
            return vec4(flash, texcolor.a) * color;
        }
    ]]
    
    -- Screen shake/distortion shader
    local distortVertexCode = [[
        vec4 position(mat4 transform_projection, vec4 vertex_position) {
            return transform_projection * vertex_position;
        }
    ]]
    
    local distortFragmentCode = [[
        uniform float time;
        uniform float intensity;
        uniform vec2 screenSize;
        
        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
            vec2 offset = vec2(
                sin(time * 20.0 + screen_coords.y * 0.01) * intensity,
                cos(time * 15.0 + screen_coords.x * 0.01) * intensity
            ) / screenSize;
            
            vec2 distorted_coords = texture_coords + offset;
            return Texel(texture, distorted_coords) * color;
        }
    ]]
    
    -- Try to compile shaders, fall back gracefully if they fail
    local success, err
    
    success, err = pcall(function()
        self.shaders.glow = love.graphics.newShader(glowFragmentCode, glowVertexCode)
    end)
    if not success then
        print("Warning: Failed to load glow shader: " .. tostring(err))
    end
    
    success, err = pcall(function()
        self.shaders.flash = love.graphics.newShader(flashFragmentCode, flashVertexCode)
    end)
    if not success then
        print("Warning: Failed to load flash shader: " .. tostring(err))
    end
    
    success, err = pcall(function()
        self.shaders.distort = love.graphics.newShader(distortFragmentCode, distortVertexCode)
    end)
    if not success then
        print("Warning: Failed to load distort shader: " .. tostring(err))
    end
end

function ShaderManager:update(dt)
    self.time = self.time + dt
    
    -- Update active effects
    for i = #self.effects, 1, -1 do
        local effect = self.effects[i]
        effect.duration = effect.duration - dt
        
        if effect.duration <= 0 then
            table.remove(self.effects, i)
        else
            -- Update effect properties
            if effect.type == "flash" then
                effect.intensity = effect.intensity * 0.95  -- Fade out
            elseif effect.type == "shake" then
                effect.intensity = effect.intensity * 0.9   -- Decay
            end
        end
    end
end

-- Add a visual effect
function ShaderManager:addEffect(effectType, duration, properties)
    local effect = {
        type = effectType,
        duration = duration,
        intensity = properties.intensity or 1.0,
        color = properties.color or {1, 1, 1},
        target = properties.target  -- Entity or screen coordinates
    }
    
    table.insert(self.effects, effect)
end

-- Apply glow shader with parameters
function ShaderManager:applyGlow(color, intensity)
    if not self.shaders.glow then return false end
    
    love.graphics.setShader(self.shaders.glow)
    self.shaders.glow:send("time", self.time)
    self.shaders.glow:send("glowColor", color or {0.6, 0.9, 1.0})
    self.shaders.glow:send("intensity", intensity or 0.3)
    return true
end

-- Apply damage flash shader
function ShaderManager:applyFlash(color, intensity)
    if not self.shaders.flash then return false end
    
    love.graphics.setShader(self.shaders.flash)
    self.shaders.flash:send("flashColor", color or {1, 0.2, 0.2})
    self.shaders.flash:send("flashIntensity", intensity or 0.5)
    return true
end

-- Apply screen distortion
function ShaderManager:applyDistortion(intensity)
    if not self.shaders.distort then return false end
    
    love.graphics.setShader(self.shaders.distort)
    self.shaders.distort:send("time", self.time)
    self.shaders.distort:send("intensity", intensity or 0.002)
    self.shaders.distort:send("screenSize", {love.graphics.getWidth(), love.graphics.getHeight()})
    return true
end

-- Clear current shader
function ShaderManager:clearShader()
    love.graphics.setShader()
end

-- Get active effects of a specific type
function ShaderManager:getEffects(effectType)
    local results = {}
    for _, effect in ipairs(self.effects) do
        if effect.type == effectType then
            table.insert(results, effect)
        end
    end
    return results
end

-- Check if any screen shake effects are active
function ShaderManager:getScreenShakeIntensity()
    local totalIntensity = 0
    for _, effect in ipairs(self.effects) do
        if effect.type == "shake" then
            totalIntensity = totalIntensity + effect.intensity
        end
    end
    return math.min(totalIntensity, 1.0)  -- Cap at 1.0
end

-- Trigger common effects
function ShaderManager:flashDamage(target, intensity)
    self:addEffect("flash", 0.2, {
        intensity = intensity or 0.7,
        color = {1, 0.3, 0.3},
        target = target
    })
end

function ShaderManager:screenShake(intensity, duration)
    self:addEffect("shake", duration or 0.3, {
        intensity = intensity or 0.5
    })
end

return ShaderManager
