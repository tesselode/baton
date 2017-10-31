local baton = {
  _VERSION = 'baton',
  _DESCRIPTION = 'Input library for LÖVE.',
  _URL = 'https://github.com/tesselode/baton',
  _LICENSE = [[
    MIT License

    Copyright (c) 2017 Andrew Minnich

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

local sourceFunction = {}

function sourceFunction.key(key)
  return function()
    return love.keyboard.isDown(key) and 1 or 0
  end
end

function sourceFunction.sc(scancode)
  return function()
    return love.keyboard.isScancodeDown(scancode) and 1 or 0
  end
end

function sourceFunction.mouse(button)
  return function()
    return love.mouse.isDown(tonumber(button)) and 1 or 0
  end
end

function sourceFunction.axis(value)
  local axis, direction = value:match '(.+)([%+%-])'
  if direction == '+' then direction = 1 end
  if direction == '-' then direction = -1 end
  return function(self)
    if self.joystick then
      local v = tonumber(axis) and self.joystick:getAxis(tonumber(axis))
                                or self.joystick:getGamepadAxis(axis)
      v = v * direction
      return v > 0 and v or 0
    end
    return 0
  end
end

function sourceFunction.button(button)
  return function(self)
    if self.joystick then
      if tonumber(button) then
        return self.joystick:isDown(tonumber(button)) and 1 or 0
      else
        return self.joystick:isGamepadDown(button) and 1 or 0
      end
    end
    return 0
  end
end

function sourceFunction.hat(hat)
    return function(self)
        if self.joystick then
            index, direction = hat:match('(%d)(.+)')
            if self.joystick:getHat(index) == direction then
                return 1
            end
        end
        return 0
    end
end

local Player = {}

function Player:_initControls()
  for name, _ in pairs(self.controls) do
    if not self._controls[name] then
      self._controls[name] = {
        value = 0,
        downPrevious = false,
        downCurrent = false,
      }
    end
  end
end

function Player:_initPairs(axisPairs)
  for name, controls in pairs(axisPairs) do
    self._axisPairs[name] = {
      controls = controls,
      x = 0,
      y = 0,
      downCurrent = false,
      downPrevious = false,
    }
  end
end

function Player:_getSources(controlName)
  local sources = {keyboard = {}, joystick = {}}
  for _, source in ipairs(self.controls[controlName]) do
    local type, value = source:match '(.+):(.+)'
    local device = 'keyboard'
    if type == 'axis' or type == 'button' then
      device = 'joystick'
    end
    table.insert(sources[device], sourceFunction[type](value))
  end
  return sources
end

function Player:_getControlOrPair(name)
  if self._axisPairs[name] then
    return self._axisPairs[name]
  else
    return self._controls[name]
  end
end

function Player:_getActiveDevice()
  local function check(device)
    for controlName, control in pairs(self._controls) do
      local sources = self:_getSources(controlName)[device]
      for i = 1, #sources do
        if sources[i](self) > self.deadzone then
          return true
        end
      end
    end
  end
  if check 'joystick' then self._active = 'joystick' end
  if check 'keyboard' then self._active = 'keyboard' end
end

function Player:_updateControls()
  if not self._active then return false end
  for controlName, control in pairs(self._controls) do
    control.value = 0
    local sources = self:_getSources(controlName)[self._active]
    for i = 1, #sources do
      control.value = control.value + sources[i](self)
    end
    if control.value > 1 then control.value = 1 end
    control.downPrevious = control.downCurrent
    control.downCurrent = control.value > self.deadzone
  end
end

function Player:_updateAxisPairs()
  for _, p in pairs(self._axisPairs) do
    local c = p.controls
    p.x, p.y = self:getRaw(c[2]) - self:getRaw(c[1]),
      self:getRaw(c[4]) - self:getRaw(c[3])
    local l = (p.x^2 + p.y^2) ^ .5
    if l > 1 then
      p.x, p.y = p.x / l, p.y / l
    end
    p.downPrevious = p.downCurrent
    if self.squareDeadzone then
      p.downCurrent = math.abs(p.x) > self.deadzone
                   or math.abs(p.y) > self.deadzone
    else
      p.downCurrent = l > self.deadzone
    end
  end
end

function Player:update()
  self:_getActiveDevice()
  self:_updateControls()
  self:_updateAxisPairs()
end

function Player:getRaw(name)
  if self._axisPairs[name] then
    return self._axisPairs[name].x, self._axisPairs[name].y
  else
    return self._controls[name].value
  end
end

function Player:get(name)
  if self._axisPairs[name] then
    local x, y = self:getRaw(name)
    if self.squareDeadzone then
      x = math.abs(x) > self.deadzone and x or 0
      y = math.abs(y) > self.deadzone and y or 0
      return x, y
    else
      if (x^2 + y^2) ^ .5 > self.deadzone then
        return x, y
      else
        return 0, 0
      end
    end
  else
    local v = self:getRaw(name)
    return v > self.deadzone and v or 0
  end
end

function Player:down(name)
  return self:_getControlOrPair(name).downCurrent
end

function Player:pressed(name)
  local c = self:_getControlOrPair(name)
  return c.downCurrent and not c.downPrevious
end

function Player:released(name)
  local c = self:_getControlOrPair(name)
  return c.downPrevious and not c.downCurrent
end

function Player:getActiveDevice()
  return self._active
end

function baton.new(options)
  local player = setmetatable({
    _controls = {},
    _axisPairs = {},
    _active = nil,
    controls = options.controls,
    joystick = options.joystick,
    deadzone = options.deadzone or .5,
    squareDeadzone = options.squareDeadzone,
  }, {__index = Player})
  player:_initControls()
  if options.pairs then
    player:_initPairs(options.pairs)
  end
  return player
end

return baton
