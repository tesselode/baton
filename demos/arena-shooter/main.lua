local baton  = require 'baton'
local Object = require 'classic'
local timer  = require 'timer'
local vector = require 'vector'

local controls = {
  moveLeft = {'key:left', 'sc:a', 'button:dpleft', 'axis:leftx-'},
  moveRight = {'key:right', 'sc:d', 'button:dpright', 'axis:leftx+'},
  moveUp = {'key:up', 'sc:w', 'button:dpup', 'axis:lefty-'},
  moveDown = {'key:down', 'sc:s', 'button:dpdown', 'axis:lefty+'},

  aimLeft = {'key:left', 'axis:rightx-'},
  aimRight = {'key:right', 'axis:rightx+'},
  aimUp = {'key:up', 'axis:righty-'},
  aimDown = {'key:down', 'axis:righty+'},
}
local input = baton.newPlayer(controls, love.joystick.getJoysticks()[1])



local Player = Object:extend()

Player.speed = 300

function Player:new()
  self.position = vector(400, 300)
  self.angle = 0
end

function Player:update(dt)
  -- movement
  local movementVector = vector(input:get 'moveRight' - input:get 'moveLeft',
    input:get 'moveDown' - input:get 'moveUp')
  movementVector:trimInplace(1)
  self.position = self.position + movementVector * Player.speed * dt

  -- aiming
  local aimingVector = vector(input:get 'aimRight' - input:get 'aimLeft',
    input:get 'aimDown' - input:get 'aimUp')
  self.angle = aimingVector:angleTo()
end

function Player:draw()
  love.graphics.setColor(255, 255, 255)
  love.graphics.circle('fill', self.position.x, self.position.y, 16)
  love.graphics.setColor(0, 0, 0)
  local a = player.position
  local b = a + vector(16, 0):rotated(player.angle)
  love.graphics.line(a.x, a.y, b.x, b.y)
end



function love.load()
  player = Player()
end

function love.update(dt)
  input:update()
  player:update(dt)
end

function love.draw()
  player:draw()
end
