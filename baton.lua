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

function sourceFunction.key(k)
  return function()
    return love.keyboard.isDown(k) and 1 or 0
  end
end

function sourceFunction.sc(sc)
  return function()
    return love.keyboard.isScancodeDown(sc) and 1 or 0
  end
end

function sourceFunction.axis(value)
  local axis, direction = value:match '(.+)%s*([%+%-])'
  if direction == '+' then direction = 1 end
  if direction == '-' then direction = -1 end
  return function(self)
    if self.joystick then
      local v = tonumber(axis) and self.joystick:getAxis(tonumber(axis))
                                or self.joystick:getGamepadAxis(axis)
      v = v * direction
      return v > self.deadzone and v or 0
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

function Player:init(controls, joystick)
  self.controls = {}
  self.joystick = joystick
  self.deadzone = .5
  self:setControls(controls)
end

function Player:_addControl(name, sources)
  self.controls[name] = {
    value = 0,
    downCurrent = false,
    downPrevious = false,
  }
  self:_setSources(name, sources)
end

function Player:_setSources(controlName, sources)
  self.controls[controlName].sources = {}
  for i = 1, #sources do
    local type, value = sources[i]:match '(.+)%s*:%s*(.+)'
    table.insert(self.controls[controlName].sources,
      sourceFunction[type](value))
  end
end

function Player:setControls(controls)
  for name, sources in pairs(controls) do
    if self.controls[name] then
      self:_setSources(name, sources)
    else
      self:_addControl(name, sources)
    end
  end
end

function Player:update()
  for _, control in pairs(self.controls) do
    control.value = 0
    for i = 1, #control.sources do
      control.value = control.value + control.sources[i](self)
    end
    if control.value > 1 then control.value = 1 end

    control.downPrevious = control.downCurrent
    control.downCurrent = control.value > self.deadzone
  end
end

function Player:get(control)
  return self.controls[control].value
end
function Player:down(control)
  return self.controls[control].downCurrent
end
function Player:pressed(control)
  local c = self.controls[control]
  return c.downCurrent and not c.downPrevious
end
function Player:released(control)
  local c = self.controls[control]
  return c.downPrevious and not c.downCurrent
end

function baton.newPlayer(controls, joystick)
  local player = setmetatable({}, {__index = Player})
  Player.init(player, controls, joystick)
  return player
end



return baton
