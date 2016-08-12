-- PHASE 1: JUST SINGLE PLAYER
-- Axis/button interoperability, remappable controls, keyboard + controller

local flene = {}



local Control = {}

function Control:addSource(source)
  local type, value = source:match '(.*):(.*)'
  if type == 'key' then
    table.insert(self.sources, function()
      return love.keyboard.isDown(value) and 1 or 0
    end)
  elseif type == 'gamepad:axis' then
    local axis, direction = value:match '(.*)([%+%-])'
    if direction == '+' then direction = 1 end
    if direction == '-' then direction = -1 end
    table.insert(self.sources, function()
      local joystick = love.joystick.getJoysticks()[1]
      if joystick then
        v = joystick:getAxis(axis)
        v = v * direction
        if v > self.deadzone then
          return v
        end
      end
      return 0
    end)
  elseif type == 'gamepad:button' then
    table.insert(self.sources, function()
      local joystick = love.joystick.getJoysticks()[1]
      if joystick then
        return joystick:isGamepadDown(value) and 1 or 0
      end
      return 0
    end)
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

local function newControl(sources)
  local control = setmetatable({
    sources = {},
    value = 0,
    downCurrent = false,
    downPrevious = false,
    deadzone = .5,
  }, {__index = Control})
  for _, source in ipairs(sources) do
    control:addSource(source)
  end
  return control
end



local Manager = {}

function Manager:update()
  for _, control in pairs(self.controls) do
    control:update()
  end
end

function Manager:get(control) return self.controls[control]:get() end
function Manager:down(control) return self.controls[control]:down() end
function Manager:pressed(control) return self.controls[control]:pressed() end
function Manager:released(control) return self.controls[control]:released() end

function flene.new(controls)
  local manager = setmetatable({
    controls = {},
  }, {__index = Manager})
  for name, sources in pairs(controls) do
    manager.controls[name] = newControl(sources)
  end
  return manager
end

return flene
