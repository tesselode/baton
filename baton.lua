local baton = {}

local function parseSource(source)
	return source:match '(.+):(.+)'
end

local sf = {kbm = {}, joy = {}}

function sf.kbm.key(key)
	return love.keyboard.isDown(key) and 1 or 0
end

function sf.joy.button(joystick, button)
	if tonumber(button) then
		return joystick:isDown(tonumber(button)) and 1 or 0
	else
		return joystick:isGamepadDown(button) and 1 or 0
	end
end

local Player = {}
Player.__index = Player

function Player:_loadConfig(config)
	assert(config, 'No config table provided')
	assert(config.controls, 'No controls specified')
	config.pairs = config.pairs or {}
	config.deadzone = config.deadzone or .5
	config.useSquareDeadzone = config.useSquareDeadzone or false
	self.config = config
end

function Player:_initControls()
	self._controls = {}
	for controlName, sources in pairs(self.config.controls) do
		self._controls[controlName] = {
			sources = sources,
			rawValue = 0,
			value = 0,
			downCurrent = false,
			downPrevious = false,
			pressed = false,
			released = false,
		}
	end
end

function Player:_initPairs()
	self._pairs = {}
	for pairName, controls in pairs(self.config.pairs) do
		self._pairs[pairName] = {
			controls = controls,
			rawX = 0,
			rawY = 0,
			x = 0,
			y = 0,
			downCurrent = false,
			downPrevious = false,
			pressed = false,
			released = false,
		}
	end
end

function Player:_init(config)
	self:_loadConfig(config)
	self:_initControls()
	self:_initPairs()
end

function Player:_setActiveDevice()
	for _, control in pairs(self._controls) do
		for _, source in ipairs(control.sources) do
			local type, value = parseSource(source)
			if sf.kbm[type] and sf.kbm[type](value) > self.config.deadzone then
				self._activeDevice = 'kbm'
				return
			elseif self.config.joystick and sf.joy[type] and sf.joy[type](self.config.joystick, value) > self.config.deadzone then
				self._activeDevice = 'joy'
			end
		end
	end
end

function Player:update()
	self:_setActiveDevice()
end

function baton.new(config)
	local player = setmetatable({}, Player)
	player:_init(config)
	return player
end

return baton