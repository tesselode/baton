local flene = require 'flene'

local controls = {
  left = {'key:left', 'axis:leftx-', 'button:dpleft'},
  right = {'key:right', 'axis:leftx+', 'button:dpright'},
  up = {'key:up', 'axis:lefty-', 'button:dpup'},
  down = {'key:down', 'axis:lefty+', 'button:dpdown'},
  primary = {'key:x', 'button:a'},
  secondary = {'key:z', 'button:x'},
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
