-- luacheck: globals describe it before_each
local baton = require 'baton'

-- attempts to find a key in a table from a list of keys
local function findKey(hash, ...)
  for _, key in ipairs{...} do
    if hash[key] then return true end
  end
  return false
end

-- LOVE api mock
local love = {}
local keys = {}
local scancodes = {}

love.keyboard = {}

function love.keyboard.isDown(...)
  return findKey(keys, ...)
end

function love.keyboard.isScancodeDown(...)
  return findKey(scancodes, ...)
end

-- gamepad mock
local function newGamepad()
  local self = {}

  self.joybuttons = {}
  self.joyaxes = {}
  self.gpbuttons = {}
  self.gpaxes = {}

  function self:isDown(...)
    return findKey(self.gpbuttons, ...)
  end

  function self:getAxis(which)
    return self.joyaxes[which]
  end

  function self:isGamepadDown(...)
    return findKey(self.gpbuttons, ...)
  end

  function self:getGamepadAxis(which)
    return self.gpaxes[which]
  end

  return self
end

-- attach it to global scope, to let baton access it
_G.love = love

describe('baton', function()
  it('detects keys', function()
    local player = baton.newPlayer({ action = {'key:a'} })

    keys.a = true
    player:update()
    assert.is_true(player:down('action'))

    keys.a = false
    player:update()
    assert.is_false(player:down('action'))
  end)

  it('detects scancodes', function()
    local player = baton.newPlayer({ action = {'sc:a'} })

    scancodes.a = true
    player:update()
    assert.is_true(player:down('action'))

    scancodes.a = false
    player:update()
    assert.is_false(player:down('action'))
  end)

  it('detects gamepad buttons', function()
    local gamepad = newGamepad()
    local player = baton.newPlayer({ action = {'button:a'} }, gamepad)

    gamepad.gpbuttons.a = true
    player:update()
    assert.is_true(player:down('action'))

    gamepad.gpbuttons.a = false
    player:update()
    assert.is_false(player:down('action'))
  end)

  it('detects joystick buttons', function()
    local gamepad = newGamepad()
    local player = baton.newPlayer({ action = {'button:1'} }, gamepad)

    gamepad.gpbuttons[1] = true
    player:update()
    assert.is_true(player:down('action'))

    gamepad.gpbuttons[1] = false
    player:update()
    assert.is_false(player:down('action'))
  end)

  it('detects gamepad axes', function()
    local gamepad = newGamepad()
    local player = baton.newPlayer({
      left = {'axis:leftx-'},
      right = {'axis:leftx+'}
    }, gamepad)

    gamepad.gpaxes.leftx = -1
    player:update()
    assert.is_true(player:down('left'))
    assert.is_false(player:down('right'))

    gamepad.gpaxes.leftx = 1
    player:update()
    assert.is_false(player:down('left'))
    assert.is_true(player:down('right'))

    gamepad.gpaxes.leftx = 0
    player:update()
    assert.is_false(player:down('left'))
    assert.is_false(player:down('right'))
  end)

  it('detects joystick axes', function()
    local gamepad = newGamepad()
    local player = baton.newPlayer({
      left = {'axis:1-'},
      right = {'axis:1+'}
    }, gamepad)

    gamepad.joyaxes[1] = -1
    player:update()
    assert.is_true(player:down('left'))
    assert.is_false(player:down('right'))

    gamepad.joyaxes[1] = 1
    player:update()
    assert.is_false(player:down('left'))
    assert.is_true(player:down('right'))

    gamepad.joyaxes[1] = 0
    player:update()
    assert.is_false(player:down('left'))
    assert.is_false(player:down('right'))
  end)
end)
