local flene = require 'flene'

local controls = {
  left = {'sc:left', 'gpaxis:leftx-', 'gpbutton:dpleft'},
  right = {'sc:right', 'gpaxis:leftx+', 'gpbutton:dpright'},
  up = {'sc:up', 'gpaxis:lefty-', 'gpbutton:dpup'},
  down = {'sc:down', 'gpaxis:lefty+', 'gpbutton:dpdown'},
  primary = {'sc:x', 'gpbutton:a'},
  secondary = {'sc:z', 'gpbutton:x'},
}

local player1

function love.load()
  player1 = flene.newPlayer(controls, love.joystick.getJoysticks()[1])
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
end
