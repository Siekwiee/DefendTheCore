---@class AudioSystem : Object
AudioSystem = Object:extend()

function AudioSystem:init()
    self.sounds = {}
    self.volume = 0.7
    self.sfxVolume = 0.8
    self.musicVolume = 0.5

    -- Generate procedural sounds (multiple variations where useful)
    self:generateSounds()
end

function AudioSystem:generateSounds()
    -- Generate simple procedural sounds using LÖVE's audio
    -- These are basic placeholder sounds - in a real game you'd load audio files
    
    -- Create simple tones for different events
    self.sounds = {
        shoot = self:createTone(520, 0.06, "square"),      -- Tighter shooting tone
        hit1 = self:createTone(320, 0.05, "triangle"),     -- Crisp impact
        hit2 = self:createTone(380, 0.04, "triangle"),     -- Slight variant
        hit3 = self:createTone(290, 0.06, "triangle"),     -- Slight variant
        explosion = self:createNoise(0.25),                 -- Snappier death
        core_hit = self:createTone(140, 0.35, "sine"),      -- Core damage
        upgrade = self:createChord({523, 659, 784}, 0.25),  -- Shorter pickup
        wave_start = self:createTone(330, 0.4, "triangle"), -- Wave start
        synergy = self:createChord({440, 554, 659, 831}, 0.5) -- Synergy activation
    }
end

function AudioSystem:createTone(frequency, duration, waveform)
    -- Create a simple procedural tone
    local sampleRate = 44100
    local samples = math.floor(sampleRate * duration)
    local soundData = love.sound.newSoundData(samples, sampleRate, 16, 1)
    
    waveform = waveform or "sine"
    
    for i = 0, samples - 1 do
        local t = i / sampleRate
        local value = 0
        
        if waveform == "sine" then
            value = math.sin(2 * math.pi * frequency * t)
        elseif waveform == "square" then
            value = math.sin(2 * math.pi * frequency * t) > 0 and 1 or -1
        elseif waveform == "sawtooth" then
            value = 2 * (t * frequency - math.floor(t * frequency + 0.5))
        elseif waveform == "triangle" then
            local phase = (t * frequency) % 1
            value = phase < 0.5 and (4 * phase - 1) or (3 - 4 * phase)
        end
        
        -- Apply envelope (fade in/out)
        local envelope = 1
        local fadeTime = duration * 0.1
        if t < fadeTime then
            envelope = t / fadeTime
        elseif t > duration - fadeTime then
            envelope = (duration - t) / fadeTime
        end
        
        value = value * envelope * 0.3  -- Reduce volume
        soundData:setSample(i, value)
    end
    
    return love.audio.newSource(soundData, "static")
end

function AudioSystem:createChord(frequencies, duration)
    -- Create a chord by mixing multiple frequencies
    local sampleRate = 44100
    local samples = math.floor(sampleRate * duration)
    local soundData = love.sound.newSoundData(samples, sampleRate, 16, 1)
    
    for i = 0, samples - 1 do
        local t = i / sampleRate
        local value = 0
        
        -- Mix all frequencies
        for _, freq in ipairs(frequencies) do
            value = value + math.sin(2 * math.pi * freq * t) / #frequencies
        end
        
        -- Apply envelope
        local envelope = 1
        local fadeTime = duration * 0.1
        if t < fadeTime then
            envelope = t / fadeTime
        elseif t > duration - fadeTime then
            envelope = (duration - t) / fadeTime
        end
        
        value = value * envelope * 0.2
        soundData:setSample(i, value)
    end
    
    return love.audio.newSource(soundData, "static")
end

function AudioSystem:createNoise(duration)
    -- Create noise for explosion effects
    local sampleRate = 44100
    local samples = math.floor(sampleRate * duration)
    local soundData = love.sound.newSoundData(samples, sampleRate, 16, 1)
    
    for i = 0, samples - 1 do
        local t = i / sampleRate
        local value = (love.math.random() - 0.5) * 2  -- White noise
        
        -- Apply low-pass filter for more pleasant noise
        if i > 0 then
            local prevValue = soundData:getSample(i - 1)
            value = value * 0.3 + prevValue * 0.7
        end
        
        -- Apply envelope
        local envelope = math.exp(-t * 3)  -- Exponential decay
        value = value * envelope * 0.2
        
        soundData:setSample(i, value)
    end
    
    return love.audio.newSource(soundData, "static")
end

function AudioSystem:playSound(soundName, volume, pitch)
    local sound = self.sounds[soundName]
    if not sound then return end
    
    volume = volume or 1.0
    pitch = pitch or 1.0
    
    -- Clone the source to allow multiple simultaneous plays
    local source = sound:clone()
    source:setVolume(volume * self.sfxVolume * self.volume)
    source:setPitch(pitch)
    source:play()
    
    return source
end

function AudioSystem:playShoot(weaponType)
    local pitch = 1.0
    local volume = 0.6
    
    -- Vary sound based on weapon type
    if weaponType == "rail" then
        pitch = 0.7
        volume = 0.8
    elseif weaponType == "beam" then
        pitch = 1.2
        volume = 0.4
    elseif weaponType == "shotgun" then
        pitch = 0.8
        volume = 0.7
    elseif weaponType == "burst" then
        pitch = 1.1
        volume = 0.5
    end
    
    self:playSound("shoot", volume, pitch)
end

function AudioSystem:playHit(damageType, effectiveness)
    -- Base volume/pitch by effectiveness
    local pitch = 1.0
    local volume = 0.45
    if effectiveness == "very_effective" then
        pitch = 1.25; volume = 0.75
    elseif effectiveness == "effective" then
        pitch = 1.1; volume = 0.6
    elseif effectiveness == "resistant" then
        pitch = 0.9; volume = 0.35
    elseif effectiveness == "very_resistant" then
        pitch = 0.75; volume = 0.25
    end

    -- Slight randomization for variation
    pitch = pitch * (0.95 + love.math.random() * 0.1)

    -- Pick a random hit variant
    local variant = (love.math.random(3))
    local name = (variant == 1 and "hit1") or (variant == 2 and "hit2") or "hit3"
    self:playSound(name, volume, pitch)
end

function AudioSystem:playExplosion(size)
    local volume = math.min(1.0, 0.4 + size * 0.1)
    local pitch = math.max(0.5, 1.0 - size * 0.1)
    self:playSound("explosion", volume, pitch)
end

function AudioSystem:playCoreHit()
    self:playSound("core_hit", 0.8, 0.8)
end

function AudioSystem:playUpgrade()
    self:playSound("upgrade", 0.6, 1.0)
end

function AudioSystem:playWaveStart()
    self:playSound("wave_start", 0.7, 1.0)
end

function AudioSystem:playSynergy()
    self:playSound("synergy", 0.8, 1.0)
end

function AudioSystem:setVolume(volume)
    self.volume = math.max(0, math.min(1, volume))
end

function AudioSystem:setSFXVolume(volume)
    self.sfxVolume = math.max(0, math.min(1, volume))
end

function AudioSystem:setMusicVolume(volume)
    self.musicVolume = math.max(0, math.min(1, volume))
end

-- Update method for any time-based audio effects
function AudioSystem:update(dt)
    -- Could be used for music management, audio ducking, etc.
end

return AudioSystem
