local baton = {
  _VERSION = 'baton',
  _DESCRIPTION = 'Input library for LÖVE.',
  _URL = 'https://github.com/tesselode/baton',
  _LICENSE = [[
    MIT License

    Copyright (c) 2016 Andrew Minnich

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

function sourceFunction.axispair(controls)
  local up, down, left, right = controls:match '(.+),(.+),(.+),(.+)'
  return function(self)
    return self:getRaw(right) - self:getRaw(left),
           self:getRaw(down) - self:getRaw(up)
  end
end

local Player = {}

function Player:_getActiveDevice()
  local function check(device)
    for _, control in pairs(self._controls) do
      for i = 1, #control.sources[device] do
        local source = control.sources[device][i]
        if source(self) > self.deadzone then
          return true
        end
      end
    end
  end
  if check 'keyboard' then return 'keyboard' end
  if check 'joystick' then return 'joystick' end
  return false
end

function Player:_updateControls()
  if not self._active then return false end
  for _, control in pairs(self._controls) do
    for i = 1, #control.values do
      control.values[i] = 0
    end
    local sources = control.sources[self._active]
    for i = 1, #sources do
      local source = sources[i]
      self:addSourceToValues(control.values, source)
    end
  end
  for _, control in pairs(self._controls) do
    local sources = control.sources['aggregate']
    for i = 1, #sources do
      local source = sources[i]
      self:addSourceToValues(control.values, source)
    end
  end
  for _, control in pairs(self._controls) do
    for i = 1, #control.values do
      control.values[i] = math.min(1, math.max(control.values[i], -1))
    end
    control.downPrevious = control.downCurrent
    control.downCurrent = self:_isMagnitudeGreaterThanDeadzone(unpack(control.values))
  end
end

function Player:addSourceToValues(current, source)
  local a, b = source(self)
  if a then current[1] = current[1] + a end
  if b then current[2] = current[2] + b end
end

function Player:changeControls(controls)
  for name, sources in pairs(controls) do
    if not self._controls[name] then
      self._controls[name] = {
        values = {0},
        downPrevious = false,
        downCurrent = false,
      }
    end
    local control = self._controls[name]
    control.sources = {keyboard = {}, joystick = {}, aggregate = {}}
    for i = 1, #sources do
      local type, value = sources[i]:match '(.+):(.+)'
      local device
      if type == 'axispair' then
        device = 'aggregate'
        control.values = {0, 0}
      elseif type == 'axis' or type == 'button' then
        device = 'joystick'
      else
        device = 'keyboard'
      end
      table.insert(control.sources[device], sourceFunction[type](value))
    end
  end
end

function Player:update()
  local a = self:_getActiveDevice()
  if a then self._active = a end
  self:_updateControls()
end

function Player:getRaw(name)
  return unpack(self._controls[name].values)
end

function Player:get(name)
  local a, b = self:getRaw(name)
  if not self:_isMagnitudeGreaterThanDeadzone(a, b) then
    a = 0
    b = b and 0 or nil
  end
  if b ~= nil then
    return a, b
  else
    return a
  end
end

function Player:_isMagnitudeGreaterThanDeadzone(a, b)
  if b == nil then b = 0 end
  return self.deadzone < math.sqrt(a^2 + b^2)
end

function Player:down(name) return self._controls[name].downCurrent end

function Player:pressed(name)
  local c = self._controls[name]
  return c.downCurrent and not c.downPrevious
end

function Player:released(name)
  local c = self._controls[name]
  return c.downPrevious and not c.downCurrent
end

function Player:getActiveDevice()
  return self._active
end

function baton.new(controls, joystick)
  local player = setmetatable({
    _controls = {},
    _active = nil,
    joystick = joystick,
    deadzone = .5,
  }, {__index = Player})
  player:changeControls(controls)
  return player
end

return baton
