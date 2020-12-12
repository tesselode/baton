local baton = require 'baton'

local player = baton.new {
	controls = {
		left = {'key:left', 'axis:leftx-', 'button:dpleft'},
		right = {'key:right', 'axis:leftx+', 'button:dpright'},
		up = {'key:up', 'axis:lefty-', 'button:dpup'},
		down = {'key:down', 'axis:lefty+', 'button:dpdown'},
		action = {'key:x', 'button:a', 'mouse:1'},
	},
	pairs = {
		move = {'left', 'right', 'up', 'down'}
	},
	joystick = love.joystick.getJoysticks()[1],
	deadzone = .33,
}

local pairDisplayAlpha = 0
local pairDisplayTargetAlpha = 0
local buttonDisplayAlpha = 0
local buttonDisplayTargetAlpha = 0

local updates = 0
local updateTime = 0

function love.update(dt)
	local time = love.timer.getTime()

	player:update()

	pairDisplayTargetAlpha = player:pressed 'move' and 1
	                      or player:released 'move' and 1
	                      or player:down 'move' and .5
	                      or 0
	if pairDisplayAlpha > pairDisplayTargetAlpha then
		pairDisplayAlpha = pairDisplayAlpha - 4 * dt
	end
	if pairDisplayAlpha < pairDisplayTargetAlpha then
		pairDisplayAlpha = pairDisplayTargetAlpha
	end

	buttonDisplayTargetAlpha = player:pressed 'action' and 1
	                        or player:released 'action' and 1
	                        or player:down 'action' and .5
	                        or 0
	if buttonDisplayAlpha > buttonDisplayTargetAlpha then
		buttonDisplayAlpha = buttonDisplayAlpha - 4 * dt
	end
	if buttonDisplayAlpha < buttonDisplayTargetAlpha then
		buttonDisplayAlpha = buttonDisplayTargetAlpha
	end

	updateTime = updateTime + (love.timer.getTime() - time)
	updates = updates + 1
end

function love.keypressed(key)
	if key == 'space' then
		player.config.joystick = nil
	end
	if key == 'escape' then
		love.event.quit()
	end
end

local pairDisplayRadius = 128

function love.draw()
	love.graphics.setColor(1, 1, 1)
	love.graphics.print('Current active device: ' .. tostring(player:getActiveDevice()))
	love.graphics.print('Average update time (us): ' .. math.floor(updateTime/updates*1000000), 0, 16)
	love.graphics.print('Memory usage (kb): ' .. math.floor(collectgarbage 'count'), 0, 32)

	love.graphics.push()
	love.graphics.translate(400, 300)

	love.graphics.setColor(.25, .25, .25, pairDisplayAlpha)
	love.graphics.circle('fill', 0, 0, pairDisplayRadius)

	love.graphics.setColor(1, 1, 1)
	love.graphics.circle('line', 0, 0, pairDisplayRadius)

	local r = pairDisplayRadius * player.config.deadzone
	if player.config.squareDeadzone then
		love.graphics.rectangle('line', -r, -r, r*2, r*2)
	else
		love.graphics.circle('line', 0, 0, r)
	end

	love.graphics.setColor(.5, .5, .5)
	local x, y = player:getRaw 'move'
	love.graphics.circle('fill', x*pairDisplayRadius, y*pairDisplayRadius, 4)
	love.graphics.setColor(1, 1, 1)
	x, y = player:get 'move'
	love.graphics.circle('fill', x*pairDisplayRadius, y*pairDisplayRadius, 4)

	love.graphics.setColor(1, 1, 1)
	love.graphics.rectangle('line', -50, 150, 100, 100)
	love.graphics.setColor(1, 1, 1, buttonDisplayAlpha)
	love.graphics.rectangle('fill', -50, 150, 100, 100)

	love.graphics.pop()
end
