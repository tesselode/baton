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
    control.value = 0
    local sources = control.sources[self._active]
    for i = 1, #sources do
      local source = sources[i]
      control.value = control.value + source(self)
    end
    if control.value > 1 then control.value = 1 end
    control.downPrevious = control.downCurrent
    control.downCurrent = control.value > self.deadzone
  end
end

function Player:changeControls(controls)
  for name, sources in pairs(controls) do
    if not self._controls[name] then
      self._controls[name] = {
        value = 0,
        downPrevious = false,
        downCurrent = false,
      }
    end
    local control = self._controls[name]
    control.sources = {keyboard = {}, joystick = {}}
    for i = 1, #sources do
      local type, value = sources[i]:match '(.+):(.+)'
      local device
      if type == 'axis' or type == 'button' then
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
  return self._controls[name].value
end

function Player:get(name)
  local v = self:getRaw(name)
  return v > self.deadzone and v or 0
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
