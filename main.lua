local baton = require 'baton'

local controls = {
  left = {'key:left', 'axis:leftx-', 'button:dpleft'},
  right = {'key:right', 'axis:leftx+', 'button:dpright'},
  up = {'key:up', 'axis:lefty-', 'button:dpup'},
  down = {'key:down', 'axis:lefty+', 'button:dpdown'},
  primary = {'sc:x', 'button:a'},
  secondary = {'sc:z', 'button:x'},
}
input = baton.new(controls, love.joystick.getJoysticks()[1])

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
  love.graphics.setColor(113, 194, 205)
  local x, y = 400, 300
  x = x + 200 * input:get 'right'
  x = x - 200 * input:get 'left'
  y = y + 200 * input:get 'down'
  y = y - 200 * input:get 'up'
  love.graphics.circle('fill', x, y, 8)

  love.graphics.setColor(208, 133, 214)
  local x, y = 400, 300
  x = x + 200 * input:getRaw 'right'
  x = x - 200 * input:getRaw 'left'
  y = y + 200 * input:getRaw 'down'
  y = y - 200 * input:getRaw 'up'
  love.graphics.circle('fill', x, y, 8)

  love.graphics.setColor(255, 255, 255)
  love.graphics.print(tostring(input:getActiveDevice()))
end
