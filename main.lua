local flene = require 'flene'

local controls = {
  left = {'key:left', 'gamepad:axis:leftx-', 'gamepad:button:dpleft'},
  right = {'key:right', 'gamepad:axis:leftx+', 'gamepad:button:dpright'},
  up = {'key:up', 'gamepad:axis:lefty-', 'gamepad:button:dpup'},
  down = {'key:down', 'gamepad:axis:lefty+', 'gamepad:button:dpdown'},
  primary = {'key:x', 'gamepad:button:a'},
  secondary = {'key:z', 'gamepad:button:x'},
}

local input = flene.new(controls)

function love.update(dt)
  input:update()
end

function love.draw()
  love.graphics.print(input:get('left'), 0, 0)
  love.graphics.print(tostring(input:down('left')), 0, 12)
  love.graphics.print(tostring(input:pressed('left')), 0, 24)
  love.graphics.print(tostring(input:released('left')), 0, 36)
end
