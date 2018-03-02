# Baton
**Baton** is an input library for LÖVE that bridges the gap between keyboard and gamepad controls and allows you to easily define and change controls on the fly.

```lua
local baton = require 'baton'

local input = baton.new {
  controls = {
    left = {'key:left', 'axis:leftx-', 'button:dpleft'},
    right = {'key:right', 'axis:leftx+', 'button:dpright'},
    up = {'key:up', 'axis:lefty-', 'button:dpup'},
    down = {'key:down', 'axis:lefty+', 'button:dpdown'},
    action = {'key:x', 'button:a'},
  },
  pairs = {
    move = {'left', 'right', 'up', 'down'}
  },
  joystick = love.joystick.getJoysticks()[1],
}

function love.update(dt)
  input:update()

  local x, y = input:get 'move'
  playerShip:move(x*100, y*100)
  if input:pressed 'action' then
    playerShip:shoot()
  end
end
```

## Installation
To use Baton, place `baton.lua` in your project, and then add this code to your `main.lua`:
```lua
baton = require 'baton' -- if your baton.lua is in the root directory
baton = require 'path.to.baton' -- if it's in subfolders
```

## Usage

### Defining controls
Controls are defined using a table. Each key should be the name of a control, and each value should be another table. This table contains strings defining what sources should be mapped to the control. For example, this table
```lua
controls = {
  left = {'key:left', 'axis:leftx-'}
  shoot = {'key:x', 'button:a'}
}
```
will create a control called "left" that responds to the left arrow key and pushing the left analog stick on the controller to the left, and a control called "shoot" that responds to the X key on the keyboard and the A button on the gamepad.

Sources are strings with the following format:
```lua
'[input type]:[input source]'
```
Here are the different input types and the sources that can be associated with them:

| Type    | Description                  | Source                                                                                                                                                                  |
| --------| -----------------------------| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `key`   | A keyboard key.              | Any LÖVE [KeyConstant](http://love2d.org/wiki/KeyConstant)                                                                                                              |
| `sc`    | A scancode.                  | Any LÖVE [KeyConstant](http://love2d.org/wiki/KeyConstant)                                                                                                              |
| `mouse` | A mouse button.              | A number representing a mouse button (see [love.mouse.isDown](https://love2d.org/wiki/love.mouse.isDown))                                                               |
| `axis`  | A joystick or gamepad axis.  | Either a number representing a joystick axis or a LÖVE [GamepadAxis](http://love2d.org/wiki/GamepadAxis). Add a '+' or '-' on the end to denote the direction to detect.|
| `button`| A joystick or gamepad button.| Either a number repesenting a joystick button or a LÖVE [GamepadButton](http://love2d.org/wiki/GamepadButton)                                                           |
| `hat`   | A joystick hat. | A number representing a joystick hat and a [JoystickHat](https://love2d.org/wiki/JoystickHat). For example '1r' corresponds to the 1st hat pushed right. |

### Defining axis pairs
Baton allows you to define **axis pairs**, which group four controls under a single name. This is perfect for analog sticks, arrow keys, etc., as it allows you to get x and y components quickly.  Each pair is defined by a table with the names of the four controls (in the order left, right, up, down).
```lua
pairs = {
  move = {'moveLeft', 'moveRight', 'moveUp', 'moveDown'},
  aim = {'aimLeft', 'aimRight', 'aimUp', 'aimDown'},
}
```

### Players
**Players** are the objects that monitor and manage inputs.

#### Creating players
To create a player, use `baton.new`:
```lua
player = baton.new(options)
```
`options` is a table containing the following values:
- `controls` - a table of controls
- `pairs` - a table of axis pairs (optional)
- `joystick` - a LÖVE joystick (returned from `love.joystick.getJoysticks`). The `joystick` argument is optional; if it's not specified, or if the joystick becomes unavailable later, the player object will just ignore controller inputs.

#### Updating players
You should update each player each frame by calling this function:
```lua
player:update()
```

#### Getting the value of controls
To get the value of a control, use:
```lua
value = player:get(control)
```
For example, for the controls defined above, we could get the value of the "left" control by doing
```lua
left = player:get 'left'
```
`player:get` always returns a number between 0 and 1, and as such, it is most applicable to controls that act as axes, such as movement controls. To get the value of a control without applying the deadzone, use `player:getRaw`.

#### Getting the value of axis pairs
`player.get` can also get the x and y components of an axis pair.
```lua
x, y = player:get(pair)
```
In this case, `x` and `y` are numbers between -1 and 1. The length of the vector x, y is capped to 1. `player.getRaw` will return the value of axis pairs without deadzone applied.

#### Getting down, pressed, and released states
To see whether a control is currently "held down", use:
```lua
down = player:down(control)
```
`player:down` returns `true` if the value of the control is greater than the deadzone, and `false` if not.

```lua
pressed = player:pressed(control)
```
`player:pressed` return `true` if the control was pressed this `frame`, and false if not.

```lua
released = player:released(control)
```
`player:released` return `true` if the control was released this `frame`, and false if not.

These functions are most applicable for controls that act as buttons, such as a shoot button. That being said, they can be used for any control, which is useful if you want to, for example, use a movement control as a discrete button press to operate a menu.

#### Changing controls
At any time, you can change the sources for a player's controls by modifying the controls table, which can be accessed via `player.controls`.

**Note**: removing a control entirely (by running `player.controls.left = nil`, for example) will cause errors. If you want to disable a control, you can set it to an empty table, thus removing all of the sources. Also note that the player object cannot detect if new controls are added.

#### Changing the deadzone
You can change the deadzone of a player by setting `player.deadzone` to a number between `0` and `1`. The deadzone is set to `0.5` by default. If you set `player.squareDeadzone` to `true`, axis pairs will apply deadzone individually to each axis.

#### Reassigning joysticks
If you need to change the joystick associated with a player, just set `player.joystick` (which is just a standard LÖVE [Joystick](https://love2d.org/wiki/Joystick) object).

#### Getting the active input device
At any time, only the keyboard/mouse sources or the gamepad sources for a player will be active. A device will be considered active if any of the sources for that device exceed the deadzone. The keyboard and mouse will always take precedence over the gamepad.

You can call `player:getActiveDevice()` to see which input device is currently active. It will return either `'keyboard'` or `'joystick'` (or `nil` if no sources have been used yet). This is useful if you need to change what you display on screen based on the controls the player is using (such as instructions).

**Note:** mouse sources are counted under `keyboard`.

## Contributing
This library is still fairly young, so feel free to take it for a spin and suggest additions and changes (especially if you try making a multiplayer game with it!). Issues and pull requests are always welcome. To run the test, run `love .` in the baton folder.

## License
MIT License

Copyright (c) 2018 Andrew Minnich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
