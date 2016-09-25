local baton = require 'baton'

local controls = {
  left = {'sc:left', 'axis:leftx-', 'button:dpleft', 'mouse:1'},
  right = {'sc:right', 'axis:leftx+', 'button:dpright'},
  up = {'sc:up', 'axis:lefty-', 'button:dpup'},
  down = {'sc:down', 'axis:lefty+', 'button:dpdown'},
  primary = {'sc:x', 'button:a'},
  secondary = {'sc:z', 'button:x'},
}

local player1

function love.load()
  player1 = baton.newPlayer(controls, love.joystick.getJoysticks()[1])
end

function love.update(dt)
  player1:update()
  for control in pairs(controls) do
    if player1:pressed(control) then
      print(control, 'pressed')
    end
    if player1:released(control) then
      print(control, 'released')
    end
  end
end

function love.draw()
  love.graphics.print(player1:get('left'), 0, 0)
  love.graphics.print(tostring(player1:down('left')), 0, 12)
  love.graphics.print(tostring(player1:pressed('left')), 0, 24)
  love.graphics.print(tostring(player1:released('left')), 0, 36)
  love.graphics.print(tostring(player1.lastUsed), 0, 48)
end
