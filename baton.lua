local baton = {}

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

function baton.new(config)
	local player = setmetatable({}, Player)
	player:_init(config)
	return player
end

return baton