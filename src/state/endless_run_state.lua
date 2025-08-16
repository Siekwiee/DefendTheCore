require "src.ECS.components.ui"
require "src.ECS.components.transformable"

---@class EndlessGameState : Object
local EndlessGameState = Object:extend()

local function clamp(v, a, b) if v < a then return a elseif v > b then return b else return v end end
local function dist2(x1,y1,x2,y2) local dx,dy=x2-x1,y2-y1 return dx*dx+dy*dy end

function EndlessGameState:init()
    self.name = "EndlessRun"
    self.colors = { bg={0.02,0.02,0.03,1}, hud={0.09,0.10,0.14,0.85}, text={1,1,1,1}, muted={0.8,0.85,0.9,1},
        button={0.15,0.17,0.22,1}, buttonHover={0.22,0.25,0.32,1}, buttonPress={0.10,0.12,0.16,1} }

    -- Overlay UI only (no background fill)
    local w,h = love.graphics.getWidth(), love.graphics.getHeight()
    self.ui = UIBox({ background = { color = {0,0,0,0}, drawMode = "none" } })
    self.ui:resize(w,h)

    -- Track last window size for resize-aware clamping
    self.lastW, self.lastH = w, h

    -- Gameplay state
    self:resetRun()
    self:registerCallbacks()
    self:buildLayout(w,h)
end

function EndlessGameState:resetRun()
    local w,h = love.graphics.getWidth(), love.graphics.getHeight()
    self.player = { x=w*0.5, y=h*0.5, r=12, speed=240, maxHp=100, hp=100, shootCd=0.18, shootT=0 }
    self.bulletDamage = 1
    self.bullets, self.enemies = {}, {}
    -- Wave/difficulty state
    self.wave = { number = 1, duration = 30, time = 0 }
    self.timeSurvived, self.gameOver = 0, false
    -- Spawn accumulator (enemies per second)
    self.spawnAcc = 0
    -- Auto-fire/auto-aim upgrade flags (refreshed on enter)
    self.autoFireActive = _G.Game.SaveSystem and _G.Game.SaveSystem:hasPermanentUpgrade("auto_fire") or false
    self.autoAimActive  = _G.Game.SaveSystem and _G.Game.SaveSystem:hasPermanentUpgrade("auto_aim")  or false
end

function EndlessGameState:getDifficulty()
    local t = self.timeSurvived
    local wv = self.wave.number
    -- Enemies per second scales with time and wave
    local spawnRate = 0.6 + 0.12*wv + 0.005*t
    local speedMul = 1.0 + 0.05*wv + 0.003*t
    local hpMul    = 1.0 + 0.15*wv + 0.006*t
    local dmgMul   = 1.0 + 0.10*wv + 0.004*t
    return spawnRate, speedMul, hpMul, dmgMul
end

function EndlessGameState:enter()
    if self.ui and (not self.ui.inputListeners or next(self.ui.inputListeners)==nil) then self.ui:setupInputListeners() end
    -- Always start a fresh run when entering this state
    self:resetRun()
    -- Refresh auto flags after reset (in case of changes while in hub)
    self.autoFireActive = _G.Game.SaveSystem and _G.Game.SaveSystem:hasPermanentUpgrade("auto_fire") or false
    self.autoAimActive  = _G.Game.SaveSystem and _G.Game.SaveSystem:hasPermanentUpgrade("auto_aim")  or false
    if _G.Game.PROFILE and _G.Game.PROFILE.player then
        _G.Game.PROFILE.player.totalRuns = (_G.Game.PROFILE.player.totalRuns or 0) + 1
    end
end

function EndlessGameState:exit()
    if self.ui then self.ui:destroy() end
end

function EndlessGameState:onEscape()
    _G.Game.StateManager:switchState("MainHub")
end

local function findNearestEnemy(enemies, px, py)
    local best,bd2=nil,math.huge
    for _,e in ipairs(enemies) do
        local d2 = (e.x-px)*(e.x-px)+(e.y-py)*(e.y-py)
        if d2 < bd2 then bd2=d2; best=e end
    end
    return best
end

function EndlessGameState:update(dt)
    if self.ui then self.ui:update(dt) end
    if self.gameOver then
        local imgr = _G.Game.InputManager
        if imgr:isKeyPressed("return") then _G.Game.StateManager:switchState("MainHub") end
        if imgr:isKeyPressed("r") then self:resetRun() end
        return
    end

    local im = _G.Game.InputManager
    local w,h = love.graphics.getWidth(), love.graphics.getHeight()

    -- If window resized since last frame, clamp player to new bounds without adding movement-induced drift
    if (w ~= self.lastW) or (h ~= self.lastH) then
        self.player.x = clamp(self.player.x, self.player.r, w-self.player.r)
        self.player.y = clamp(self.player.y, self.player.r, h-self.player.r)
        self.lastW, self.lastH = w, h
    end

    -- Movement
    local dx,dy=0,0
    if im:isKeyDown("w") or im:isKeyDown("up") then dy=dy-1 end
    if im:isKeyDown("s") or im:isKeyDown("down") then dy=dy+1 end
    if im:isKeyDown("a") or im:isKeyDown("left") then dx=dx-1 end
    if im:isKeyDown("d") or im:isKeyDown("right") then dx=dx+1 end
    if dx~=0 or dy~=0 then local len=math.sqrt(dx*dx+dy*dy); dx,dy=dx/len,dy/len end
    self.player.x = clamp(self.player.x + dx*self.player.speed*dt, self.player.r, w-self.player.r)
    self.player.y = clamp(self.player.y + dy*self.player.speed*dt, self.player.r, h-self.player.r)

    -- Shooting (auto-fire and auto-aim upgrades respected)
    self.player.shootT = math.max(0, self.player.shootT - dt)
    local mx,my = im:getMousePosition()
    local wantFire = im:isMouseDown(1) or im:isKeyDown("space") or self.autoFireActive
    if wantFire and self.player.shootT<=0 then
        local ang
        if self.autoAimActive then
            local tgt = findNearestEnemy(self.enemies, self.player.x, self.player.y)
            if tgt then ang = math.atan2(tgt.y - self.player.y, tgt.x - self.player.x) end
        end
        if not ang then ang = math.atan2(my - self.player.y, mx - self.player.x) end
        local spd = 420
        table.insert(self.bullets, {x=self.player.x, y=self.player.y, vx=math.cos(ang)*spd, vy=math.sin(ang)*spd, r=4, dmg=self.bulletDamage})
        self.player.shootT = self.player.shootCd
    end

    -- Wave progression
    self.wave.time = self.wave.time + dt
    if self.wave.time >= self.wave.duration then
        self.wave.number = self.wave.number + 1
        self.wave.time = 0
        -- Optionally shorten/adjust later; keep constant for now
    end

    -- Difficulty modifiers
    local spawnRate, speedMul, hpMul, dmgMul = self:getDifficulty()

    -- Spawns via accumulator
    self.spawnAcc = self.spawnAcc + spawnRate * dt
    while self.spawnAcc >= 1 do
        self.spawnAcc = self.spawnAcc - 1
        -- Spawn at edges
        local side = love.math.random(4)
        local ex,ey
        if side==1 then ex,ey = -20, love.math.random(0,h) elseif side==2 then ex,ey = w+20, love.math.random(0,h)
        elseif side==3 then ex,ey = love.math.random(0,w), -20 else ex,ey = love.math.random(0,w), h+20 end
        -- Enemy type selection with wave-weighted probabilities
        local wpSwift = clamp(0.2 + 0.02*self.wave.number, 0, 0.6)
        local wpBrute = clamp(0.1 + 0.03*self.wave.number, 0, 0.5)
        local r = love.math.random()
        local etype
        if r < wpSwift then etype = "swift"
        elseif r < wpSwift + wpBrute then etype = "brute"
        else etype = "grunt" end
        local base = (etype=="swift") and {r=10, speed=130, hp=1, dmg=8, color={1,0.7,0.3,1}} or
                     (etype=="brute") and {r=18, speed=60,  hp=3, dmg=15,color={0.9,0.2,0.6,1}} or
                                          {r=14, speed=80,  hp=1, dmg=10,color={1,0.3,0.3,1}}
        local e = { x=ex, y=ey, r=base.r, speed=base.speed*speedMul, hp=math.max(1, math.floor(base.hp*hpMul+0.5)), dmg=math.floor(base.dmg*dmgMul+0.5), color=base.color }
        table.insert(self.enemies, e)
    end

    -- Update bullets
    for i=#self.bullets,1,-1 do local b=self.bullets[i]
        b.x = b.x + b.vx*dt; b.y = b.y + b.vy*dt
        if b.x<-50 or b.x>w+50 or b.y<-50 or b.y>h+50 then table.remove(self.bullets,i) end
    end

    -- Update enemies and collisions
    for ei=#self.enemies,1,-1 do local e=self.enemies[ei]
        local ang = math.atan2(self.player.y - e.y, self.player.x - e.x)
        e.x = e.x + math.cos(ang)*e.speed*dt; e.y = e.y + math.sin(ang)*e.speed*dt
        -- Bullet hits
        local removeEnemy=false
        for bi=#self.bullets,1,-1 do local b=self.bullets[bi]
            if dist2(e.x,e.y,b.x,b.y) < (e.r+b.r)*(e.r+b.r) then
                e.hp = e.hp - (b.dmg or 1)
                table.remove(self.bullets,bi)
                if e.hp <= 0 then removeEnemy=true; break end
            end
        end
        if removeEnemy then table.remove(self.enemies,ei) goto continue end
        -- Player hit
        if dist2(e.x,e.y,self.player.x,self.player.y) < (e.r+self.player.r)*(e.r+self.player.r) then
            self.player.hp = self.player.hp - (e.dmg or 10); table.remove(self.enemies,ei)
            if self.player.hp <= 0 then self.player.hp=0; self.gameOver=true
                local t = self.timeSurvived
                local p = _G.Game.PROFILE and _G.Game.PROFILE.player
                if p then p.bestSurvivalTime = math.max(p.bestSurvivalTime or 0, t); _G.Game.SaveSystem:save(_G.Game.PROFILE) end
                break
            end
        end
        ::continue::
    end

    -- Timer
    self.timeSurvived = self.timeSurvived + dt
end

function EndlessGameState:draw()
    -- Background
    love.graphics.clear(self.colors.bg)
    -- Gameplay
    -- Bullets
    love.graphics.setColor(0.9,0.9,1.0,1)
    for _,b in ipairs(self.bullets) do love.graphics.circle("fill", b.x, b.y, b.r) end
    -- Enemies (colored per type)
    for _,e in ipairs(self.enemies) do love.graphics.setColor(e.color); love.graphics.circle("fill", e.x, e.y, e.r) end
    -- Player
    love.graphics.setColor(0.4,1,0.6,1)
    love.graphics.circle("fill", self.player.x, self.player.y, self.player.r)

    -- HUD
    local w = love.graphics.getWidth()
    love.graphics.setColor(self.colors.hud)
    love.graphics.rectangle("fill", 0,0, w, 40)
    love.graphics.setColor(self.colors.text)
    love.graphics.print(string.format("Time: %.1fs", self.timeSurvived), 12, 12)
    love.graphics.print(string.format("Wave: %d", self.wave.number), 120, 12)
    -- HP bar
    local bw,bh = 200, 14; local x,y = w- bw - 12, 12
    love.graphics.setColor(0.2,0.2,0.25,1); love.graphics.rectangle("fill", x, y, bw, bh)
    local pct = self.player.hp / self.player.maxHp
    love.graphics.setColor(0.3,0.9,0.4,1); love.graphics.rectangle("fill", x, y, bw*math.max(0,pct), bh)
    love.graphics.setColor(self.colors.text); love.graphics.print("HP", x-28, y-1)

    if self.gameOver then
        local ww,hh = love.graphics.getWidth(), love.graphics.getHeight()
        love.graphics.setColor(0,0,0,0.6); love.graphics.rectangle("fill", 0,0, ww,hh)
        love.graphics.setColor(1,1,1,1)
        local msg = string.format("Game Over\nSurvived %.1f seconds\nPress Enter / R to Restart\nEsc / button to Exit to Hub", self.timeSurvived)
        love.graphics.printf(msg, 0, hh*0.4, ww, "center")
        -- Restart hint box
        love.graphics.setColor(self.colors.hud); love.graphics.rectangle("fill", ww*0.5-80, hh*0.55, 160, 36)
        love.graphics.setColor(self.colors.text); love.graphics.printf("Restart (R)", ww*0.5-80, hh*0.56, 160, "center")
    end

    -- Overlay UI (Exit button)
    if self.ui then self.ui:draw() end
    love.graphics.setColor(1,1,1,1)
end

function EndlessGameState:resize(w, h)
    if self.ui then self.ui:resize(w,h); self:layout(w,h) end
    -- Preserve relative position across resize, then clamp
    local prevW, prevH = self.lastW or w, self.lastH or h
    local fx = (prevW > 0) and (self.player.x / prevW) or 0.5
    local fy = (prevH > 0) and (self.player.y / prevH) or 0.5
    self.player.x = fx * w
    self.player.y = fy * h
    self.player.x = clamp(self.player.x, self.player.r, w - self.player.r)
    self.player.y = clamp(self.player.y, self.player.r, h - self.player.r)
    self.lastW, self.lastH = w, h
end

function EndlessGameState:registerCallbacks()
    local cm = _G.Game.CallbackManager
    cm:register("endless:buttonHover", function(el, isH) if not el or not el.background then return end el.background.color = isH and self.colors.buttonHover or self.colors.button end)
    cm:register("endless:buttonPress", function(el) if not el or not el.background then return end el.background.color = self.colors.buttonPress end)
    cm:register("endless:buttonRelease", function(el) if not el or not el.background then return end el.background.color = el.isHovered and self.colors.buttonHover or self.colors.button end)
    cm:register("endless:backToHub", function() _G.Game.StateManager:switchState("MainHub") end)
end

function EndlessGameState:buildLayout(w, h)
    self.ui:clear()
    self.btnBack = UIElement({ elementName="endless_back", x=24, y=h-24, width=220, height=42, pivotX=0, pivotY=1,
        text="Exit to Hub", fontSize=18, textColor=self.colors.text,
        background={ color=self.colors.button, drawMode="fill" }, callbackName="endless:backToHub",
        hoverCallbackName="endless:buttonHover", pressCallbackName="endless:buttonPress", releaseCallbackName="endless:buttonRelease",
        zIndex=2, isFocusable=true })
    self.ui:addElement(self.btnBack)
    for i,e in ipairs(self.ui.elements) do if e.isFocusable then self.ui:setFocusByIndex(i) break end end
end

function EndlessGameState:layout(w, h)
    if self.btnBack then self.btnBack:setPosition(24, h-24); self.btnBack:setSize(220, 42) end
end

return EndlessGameState

