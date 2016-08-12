-- PHASE 1: JUST SINGLE PLAYER
-- Axis/button interoperability, remappable controls, keyboard + controller

local flene = {}

local Control = {}

local function newControl(sources)
  local control = {sources = {}}
  for _, source in ipairs(sources) do
    local type, value = source:match('(.*):(.*)')
    print(type, value)
  end
end

local Manager = {}

function flene.new(controls)
  local manager = {controls = {}}
  for name, sources in pairs(controls) do
    newControl(sources)
  end
end

return flene
