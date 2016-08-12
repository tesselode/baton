-- PHASE 1: JUST SINGLE PLAYER
-- Axis/button interoperability, remappable controls, keyboard + controller

local flene = {}



local Control = {}

function Control:addSource(source)
  local type, value = source:match('(.*):(.*)')
  if type == 'key' then
    table.insert(self.sources, function()
      return love.keyboard.isDown(value) and 1 or 0
    end)
  end
  -- will add controller support once I have a controller to test with
end

function Control:get()
  local value = 0
  for _, source in ipairs(self.sources) do
    value = source()
  end
  return value
end

local function newControl(sources)
  local control = setmetatable({
    sources = {},
  }, {__index = Control})
  for _, source in ipairs(sources) do
    control:addSource(source)
  end
  return control
end



local Manager = {}

function Manager:get(control)
  return self.controls[control]:get()
end

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
