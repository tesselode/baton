local flene = require 'flene'

local controls = {
  left = {'key:left', 'gp:axis:leftx-', 'gp:button:dpleft'},
  right = {'key:right', 'gp:axis:leftx+', 'gp:button:dpright'},
  up = {'key:up', 'gp:axis:lefty-', 'gp:button:dpup'},
  down = {'key:down', 'gp:axis:lefty+', 'gp:button:dpdown'},
  primary = {'key:x', 'gp:button:a'},
  secondary = {'key:z', 'gp:button:x'},
}

local input = flene.new(controls)

function love.update(dt)
  input:update()
  for control in pairs(controls) do
    if input:pressed(control) then
      print(control, 'pressed')
    end
    if input:released(control) then
      print(control, 'released')
    end
  end
end

function love.draw()
  love.graphics.print(input:get('left'), 0, 0)
  love.graphics.print(tostring(input:down('left')), 0, 12)
  love.graphics.print(tostring(input:pressed('left')), 0, 24)
  love.graphics.print(tostring(input:released('left')), 0, 36)
end
