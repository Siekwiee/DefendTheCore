---@class UpgradeUI : Object
UpgradeUI = Object:extend()

function UpgradeUI:init(runState)
	self.runState = runState
	self.visible = false

	require "src.ECS.components.ui"

	local w, h = love.graphics.getWidth(), love.graphics.getHeight()
	self.ui = UIBox({ background = { color = {0, 0, 0, 0.5}, drawMode = "fill" } })
	self.ui:resize(w, h)

	self:registerCallbacks()
	self:buildLayout(w, h)
end

function UpgradeUI:registerCallbacks()
	local cm = _G.Game.CallbackManager
	cm:register("upgrade:pick", function(element, args)
		if not (args and args.id) then return end
		self.runState:applyUpgrade(args.id)
		self:hide()
		self.runState:startNextWave()
	end)
	cm:register("upgrade:close", function()
		self:hide()
		self.runState:startNextWave()
	end)
end

function UpgradeUI:buildLayout(w, h)
	self.ui:clear()

	-- Title
	self.title = UIElement({
		elementName = "upgrade_title",
		x = w * 0.5,
		y = h * 0.18,
		width = math.min(900, w * 0.9),
		height = 60,
		pivotX = 0.5,
		pivotY = 0.5,
		text = "Choose an Upgrade",
		fontSize = 36,
		textColor = {1,1,1,1},
		background = { color = {0,0,0,0}, drawMode = "none" },
		zIndex = 1,
	})
	self.ui:addElement(self.title)

	-- Generate choices
	self.choices = self.runState:generateUpgradeChoices(3)

	local cardWidth, cardHeight = 300, 160
	local spacing = 24
	local totalWidth = cardWidth * #self.choices + spacing * (#self.choices - 1)
	local startX = (w - totalWidth) * 0.5 + cardWidth * 0.5
	local y = h * 0.45

	for i, choice in ipairs(self.choices) do
		local card = UIElement({
			elementName = "upgrade_card_"..i,
			x = startX + (i-1) * (cardWidth + spacing),
			y = y,
			width = cardWidth,
			height = cardHeight,
			pivotX = 0.5,
			pivotY = 0.5,
			text = choice.name .. "\n\n" .. choice.desc,
			fontSize = 18,
			textColor = {1,1,1,1},
			wrap = true,
			textAlign = "left",
			textVAlign = "top",
			padding = {l = 16, t = 16, r = 16, b = 16},
			background = { color = {0.11, 0.16, 0.22, 1}, drawMode = "fill" },
			hoverColor = {0.16, 0.22, 0.30, 1},
			pressColor = {0.10, 0.14, 0.20, 1},
			callbackName = "upgrade:pick",
			callbackArgs = { id = choice.id },
			isFocusable = true,
			zIndex = 2,
		})
		self.ui:addElement(card)
	end

	-- Close/Skip button
	local skip = UIElement({
		elementName = "upgrade_skip",
		x = w * 0.5,
		y = y + cardHeight * 0.5 + 48,
		width = 220,
		height = 48,
		pivotX = 0.5,
		pivotY = 0.5,
		text = "Skip / Next Wave",
		fontSize = 20,
		textColor = {1,1,1,1},
		background = { color = {0.15, 0.20, 0.26, 1}, drawMode = "fill" },
		hoverColor = {0.20, 0.26, 0.34, 1},
		pressColor = {0.12, 0.16, 0.22, 1},
		callbackName = "upgrade:close",
		isFocusable = true,
		zIndex = 2,
	})
	self.ui:addElement(skip)
end

function UpgradeUI:resize(w, h)
	if not self.ui then return end
	self.ui:resize(w, h)
	self:buildLayout(w, h)
end

function UpgradeUI:show()
	self.visible = true
	-- Regenerate choices each time we show the UI to avoid repeats
	local w, h = love.graphics.getWidth(), love.graphics.getHeight()
	self:buildLayout(w, h)
end

function UpgradeUI:hide()
	self.visible = false
end

function UpgradeUI:update(dt)
	if not self.visible then return end
	self.ui:update(dt)
end

function UpgradeUI:draw()
	if not self.visible then return end
	self.ui:draw()
end

return UpgradeUI


