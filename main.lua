local flene = require 'flene'

local controls = {
  left = {'sc:left', 'gp:axis:leftx-', 'gp:button:dpleft', 'joy:axis:1-'},
  right = {'sc:right', 'gp:axis:leftx+', 'gp:button:dpright', 'joy:axis:1+'},
  up = {'sc:up', 'gp:axis:lefty-', 'gp:button:dpup', 'joy:axis:2-'},
  down = {'sc:down', 'gp:axis:lefty+', 'gp:button:dpdown', 'joy:axis:2+'},
  primary = {'sc:x', 'gp:button:a', 'joy:button:1'},
  secondary = {'sc:z', 'gp:button:x', 'joy:button:2'},
}

local input

function love.load()
  input = flene.new(controls, love.joystick.getJoysticks()[1])
end

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
