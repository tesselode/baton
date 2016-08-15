local flene = {}



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

function sourceFunction.gpaxis(value)
  local axis, direction = value:match '(.+)%s*([%+%-])'
  if direction == '+' then direction = 1 end
  if direction == '-' then direction = -1 end
  return function(self)
    if self.joystick then
      local v = self.joystick:getGamepadAxis(axis)
      v = v * direction
      if v > self.deadzone then
        return v
      end
    end
    return 0
  end
end

function sourceFunction.gpbutton(button)
  return function(self)
    if self.joystick then
      return self.joystick:isGamepadDown(button) and 1 or 0
    end
    return 0
  end
end

function sourceFunction.joyaxis(value)
  local axis, direction = value:match '(.+)%s*([%+%-])'
  if direction == '+' then direction = 1 end
  if direction == '-' then direction = -1 end
  return function(self)
    if self.joystick then
      local v = self.joystick:getAxis(tonumber(axis))
      v = v * direction
      if v > self.deadzone then
        return v
      end
    end
    return 0
  end
end

function sourceFunction.joybutton(button)
  return function(self)
    if self.joystick then
      return self.joystick:isDown(tonumber(button)) and 1 or 0
    end
    return 0
  end
end



local Control = {}

function Control:addSource(source)
  local type, value = source:match '(.+)%s*:%s*(.+)'
  table.insert(self.sources, sourceFunction[type](value))
end

function Control:update()
  self.value = 0
  for i = 1, #self.sources do
    self.value = self.value + self.sources[i](self)
  end
  if self.value > 1 then self.value = 1 end

  self.downPrevious = self.downCurrent
  self.downCurrent = self.value > self.deadzone
end

function Control:get() return self.value end
function Control:down() return self.downCurrent end
function Control:pressed() return self.downCurrent and not self.downPrevious end
function Control:released() return self.downPrevious and not self.downCurrent end

local function newControl(sources, joystick)
  local control = setmetatable({
    sources = {},
    value = 0,
    downCurrent = false,
    downPrevious = false,
    deadzone = .5,
    joystick = joystick,
  }, {__index = Control})
  for _, source in ipairs(sources) do
    control:addSource(source)
  end
  return control
end



local Player = {}

function Player:update()
  for _, control in pairs(self.controls) do
    control:update()
  end
end

function Player:get(control) return self.controls[control]:get() end
function Player:down(control) return self.controls[control]:down() end
function Player:pressed(control) return self.controls[control]:pressed() end
function Player:released(control) return self.controls[control]:released() end

function flene.new(controls, joystick)
  local player = setmetatable({
    controls = {},
  }, {__index = Player})
  for name, sources in pairs(controls) do
    player.controls[name] = newControl(sources, joystick)
  end
  return player
end



return flene
