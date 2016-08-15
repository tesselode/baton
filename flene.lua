local flene = {}



local sourceFunction = {}

function sourceFunction.key(k)
  return function()
    return love.keyboard.isDown(k) and 1 or 0
  end
end

function sourceFunction.scancode(sc)
  return function()
    return love.keyboard.isScancodeDown(sc) and 1 or 0
  end
end

function sourceFunction.gamepadAxis(value, control)
  local axis, direction = value:match '(.+)%s*([%+%-])'
  if direction == '+' then direction = 1 end
  if direction == '-' then direction = -1 end
  return function()
    if control.joystick then
      local v = control.joystick:getGamepadAxis(axis)
      v = v * direction
      if v > control.deadzone then
        return v
      end
    end
    return 0
  end
end

function sourceFunction.gamepadButton(button, control)
  return function()
    if control.joystick then
      return control.joystick:isGamepadDown(button) and 1 or 0
    end
    return 0
  end
end

function sourceFunction.joystickAxis(value, control)
  local axis, direction = value:match '(.+)%s*([%+%-])'
  if direction == '+' then direction = 1 end
  if direction == '-' then direction = -1 end
  return function()
    if control.joystick then
      local v = control.joystick:getAxis(tonumber(axis))
      v = v * direction
      if v > control.deadzone then
        return v
      end
    end
    return 0
  end
end

function sourceFunction.joystickButton(button, control)
  return function()
    if control.joystick then
      return control.joystick:isDown(tonumber(button)) and 1 or 0
    end
    return 0
  end
end



local Control = {}

function Control:addSource(source)
  local type, value = source:match '(.+)%s*:%s*(.+)'
  if type == 'key' then
    table.insert(self.sources, sourceFunction.key(value))
  elseif type == 'sc' then
    table.insert(self.sources, sourceFunction.scancode(value))
  elseif type == 'gp:axis' then
    table.insert(self.sources, sourceFunction.gamepadAxis(value, self))
  elseif type == 'gp:button' then
    table.insert(self.sources, sourceFunction.gamepadButton(value, self))
  elseif type == 'joy:axis' then
    table.insert(self.sources, sourceFunction.joystickAxis(value, self))
  elseif type == 'joy:button' then
    table.insert(self.sources, sourceFunction.joystickButton(value, self))
  end
end

function Control:update()
  self.value = 0
  for _, source in ipairs(self.sources) do
    self.value = self.value + source()
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
