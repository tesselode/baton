local baton = {
	_VERSION = 'Baton v1.0',
	_DESCRIPTION = 'Input library for LÖVE.',
	_URL = 'https://github.com/tesselode/baton',
	_LICENSE = [[
		MIT License

		Copyright (c) 2018 Andrew Minnich

		Permission is hereby granted, free of charge, to any person obtaining a copy
		of this software and associated documentation files (the "Software"), to deal
		in the Software without restriction, including without limitation the rights
		to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
		copies of the Software, and to permit persons to whom the Software is
		furnished to do so, subject to the following conditions:

		The above copyright notice and this permission notice shall be included in all
		copies or substantial portions of the Software.

		THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
		IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
		FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
		AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
		LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
		OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
		SOFTWARE.
	]]
}

local function parseSource(source)
	return source:match '(.+):(.+)'
end

local function parseAxis(value)
	return value:match '(.+)([%+%-])'
end

local function parseHat(value)
	return value:match '(%d)(.+)'
end

local sourceFunction = {keyboardMouse = {}, joystick = {}}

function sourceFunction.keyboardMouse.key(key)
	return love.keyboard.isDown(key) and 1 or 0
end

function sourceFunction.keyboardMouse.sc(sc)
	return love.keyboard.isScancodeDown(sc) and 1 or 0
end

function sourceFunction.keyboardMouse.mouse(button)
	return love.mouse.isDown(tonumber(button)) and 1 or 0
end

function sourceFunction.joystick.axis(joystick, value)
	local axis, direction = parseAxis(value)
	value = tonumber(axis) and joystick:getAxis(tonumber(axis))
	                        or joystick:getGamepadAxis(axis)
	if direction == '-' then value = -value end
	return value > 0 and value or 0
end

function sourceFunction.joystick.button(joystick, button)
	local isDown = tonumber(button) and joystick:isDown(tonumber(button))
									 or joystick:isGamepadDown(button)
	return isDown and 1 or 0
end

function sourceFunction.joystick.hat(joystick, value)
	local hat, direction = parseHat(value)
	return joystick:getHat(hat) == direction and 1 or 0
end

local Player = {}
Player.__index = Player

function Player:_loadConfig(config)
	if not config then
		error('No config table provided', 4)
	end
	if not config.controls then
		error('No controls specified', 4)
	end
	config.pairs = config.pairs or {}
	config.deadzone = config.deadzone or .5
	config.squareDeadzone = config.squareDeadzone or false
	self.config = config
end

function Player:_initControls()
	self._controls = {}
	for controlName, sources in pairs(self.config.controls) do
		self._controls[controlName] = {
			sources = sources,
			rawValue = 0,
			value = 0,
			down = false,
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
			down = false,
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
	self._activeDevice = 'none'
end

function Player:_setActiveDevice()
	for _, control in pairs(self._controls) do
		for _, source in ipairs(control.sources) do
			local type, value = parseSource(source)
			if sourceFunction.keyboardMouse[type] then
				if sourceFunction.keyboardMouse[type](value) > self.config.deadzone then
					self._activeDevice = 'kbm'
					return
				end
			elseif self.config.joystick and sourceFunction.joystick[type] then
				if sourceFunction.joystick[type](self.config.joystick, value) > self.config.deadzone then
					self._activeDevice = 'joy'
				end
			end
		end
	end
end

function Player:_getControlRawValue(control)
	local rawValue = 0
	for _, source in ipairs(control.sources) do
		local type, value = parseSource(source)
		if sourceFunction.keyboardMouse[type] and self._activeDevice == 'kbm' then
			if sourceFunction.keyboardMouse[type](value) == 1 then
				return 1
			end
		elseif sourceFunction.joystick[type] and self._activeDevice == 'joy' then
			rawValue = rawValue + sourceFunction.joystick[type](self.config.joystick, value)
			if rawValue >= 1 then
				return 1
			end
		end
	end
	return rawValue
end

function Player:_updateControls()
	for _, control in pairs(self._controls) do
		control.rawValue = self:_getControlRawValue(control)
		control.value = control.rawValue >= self.config.deadzone and control.rawValue or 0
		control.downPrevious = control.down
		control.down = control.value > 0
		control.pressed = control.down and not control.downPrevious
		control.released = control.downPrevious and not control.down
	end
end

function Player:_updatePairs()
	for _, pair in pairs(self._pairs) do
		-- get raw x and y
		local l = self._controls[pair.controls[1]].rawValue
		local r = self._controls[pair.controls[2]].rawValue
		local u = self._controls[pair.controls[3]].rawValue
		local d = self._controls[pair.controls[4]].rawValue
		pair.rawX, pair.rawY = r - l, d - u

		-- limit to 1
		local len = math.sqrt(pair.rawX^2 + pair.rawY^2)
		if len > 1 then
			pair.rawX, pair.rawY = pair.rawX / len, pair.rawY / len
		end

		-- deadzone
		if self.config.squareDeadzone then
			pair.x = math.abs(pair.rawX) > self.config.deadzone and pair.rawX or 0
			pair.y = math.abs(pair.rawY) > self.config.deadzone and pair.rawY or 0
		else
			pair.x = len > self.config.deadzone and pair.rawX or 0
			pair.y = len > self.config.deadzone and pair.rawY or 0
		end

		-- down/pressed/released
		pair.downPrevious = pair.down
		pair.down = pair.x ~= 0 or pair.y ~= 0
		pair.pressed = pair.down and not pair.downPrevious
		pair.released = pair.downPrevious and not pair.down
	end
end

function Player:update()
	self:_setActiveDevice()
	self:_updateControls()
	self:_updatePairs()
end

function Player:getRaw(name)
	if self._pairs[name] then
		return self._pairs[name].rawX, self._pairs[name].rawY
	elseif self._controls[name] then
		return self._controls[name].rawValue
	else
		error('No control with name "' .. name .. '" defined', 3)
	end
end

function Player:get(name)
	if self._pairs[name] then
		return self._pairs[name].x, self._pairs[name].y
	elseif self._controls[name] then
		return self._controls[name].value
	else
		error('No control with name "' .. name .. '" defined', 3)
	end
end

function Player:down(name)
	if self._pairs[name] then
		return self._pairs[name].down
	elseif self._controls[name] then
		return self._controls[name].down
	else
		error('No control with name "' .. name .. '" defined', 3)
	end
end

function Player:pressed(name)
	if self._pairs[name] then
		return self._pairs[name].pressed
	elseif self._controls[name] then
		return self._controls[name].pressed
	else
		error('No control with name "' .. name .. '" defined', 3)
	end
end

function Player:released(name)
	if self._pairs[name] then
		return self._pairs[name].released
	elseif self._controls[name] then
		return self._controls[name].released
	else
		error('No control with name "' .. name .. '" defined', 3)
	end
end

function Player:getActiveDevice()
	return self._activeDevice
end

function baton.new(config)
	local player = setmetatable({}, Player)
	player:_init(config)
	return player
end

return baton
