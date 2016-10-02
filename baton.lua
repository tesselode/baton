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

local function any(t, f)
  for _, v in pairs(t) do
    if f(v) then
      return true
    end
  end
  return false
end

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

function Player:_determineActiveDevice()
  if any(self._controls.keyboard, function(c) return c.active end) then
    self._active = 'keyboard'
  elseif any(self._controls.joystick, function(c) return c.active end) then
    self._active = 'joystick'
  end
end

function Player:_updateControls(controls)
  for _, control in pairs(controls) do
    control.active = false
    control.value = 0
    for i = 1, #control.sources do
      local source = control.sources[i]
      local v = source(self)
      if v > self.deadzone then
        control.active = true
      end
      control.value = control.value + v
    end
    if control.value > 1 then control.value = 1 end
  end
end

function Player:changeControls(controls)
  for name, sources in pairs(controls) do
    if not self._controls.keyboard[name] then
      self._controls.keyboard[name] = {active = false, value = 0}
    end
    self._controls.keyboard[name].sources = {}
    if not self._controls.joystick[name] then
      self._controls.joystick[name] = {active = false, value = 0}
    end
    self._controls.joystick[name].sources = {}

    for i = 1, #sources do
      local source = sources[i]
      local type, value = source:match '(.+):(.+)'
      if type == 'axis' or type == 'button' then
        table.insert(self._controls.joystick[name].sources,
          sourceFunction[type](value))
      else
        table.insert(self._controls.keyboard[name].sources,
          sourceFunction[type](value))
      end
    end
  end
end

function Player:update()
  self:_updateControls(self._controls.keyboard)
  self:_updateControls(self._controls.joystick)
  self:_determineActiveDevice()
end

function Player:getRaw(name)
  if self._active == 'keyboard' then
    return self._controls.keyboard[name].value
  elseif self._active == 'joystick' then
    return self._controls.joystick[name].value
  else
    return 0
  end
end

function Player:get(name)
  local v = self:getRaw(name)
  return v > self.deadzone and v or 0
end

function Player:getActiveDevice()
  return self._active
end

function baton.new(controls, joystick)
  local player = {
    _controls = {
      keyboard = {},
      joystick = {},
    },
    joystick = joystick,
    deadzone = .5,
  }
  setmetatable(player, {__index = Player})
  player:changeControls(controls)
  return player
end

return baton
