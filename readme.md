Baton
-----
**Baton** is an input library for LÖVE that bridges the gap between keyboard and gamepad controls and allows you to easily define and change controls on the fly.

```lua
local baton = require 'baton'

local controls = {
  left = {'key:left', 'axis:leftx-', 'button:dpleft'},
  right = {'key:right', 'axis:leftx+', 'button:dpright'},
  up = {'key:up', 'axis:lefty-', 'button:dpup'},
  down = {'key:down', 'axis:lefty+', 'button:dpdown'},
  shoot = {'key:x', 'button:a'}
}

local input = baton.new(controls, love.joystick.getJoysticks()[1])

function love.update(dt)
  input:update()
  local horizontal = input:get 'right' - input:get 'left'
  local vertical = input:get 'down' - input:get 'up'

  playerShip:move(horizontal, vertical)
  if input:pressed 'shoot' then
    playerShip:shoot()
  end
end
```

Installation
============
To use Baton, place `baton.lua` in your project, and then add this code to your `main.lua`:
```lua
baton = require 'baton' -- if your baton.lua is in the root directory
baton = require 'path.to.baton' -- if it's in subfolders
```

Usage
=====
### Defining controls
Controls are defined using a table. Each key should be the name of a control, and each value should be another table. This table contains strings defining what inputs should be mapped to the control. For example, this table
```lua
controls = {
  left = {'key:left', 'axis:leftx-'}
  shoot = {'key:x', 'button:a'}
}
```
will create a control called "left" that responds to the left arrow key and pushing the left analog stick on the controller to the left, and a control called "shoot" that responds to the X key on the keyboard and the A button on the gamepad.

Inputs are strings with the following format:
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

### Players
**Players** are the objects that monitor and manage inputs.

#### Creating players
To create a player, use `baton.new`:
```lua
player = baton.new(controls, joystick)
```
`controls` is a table of controls, and `joystick` is a LÖVE joystick (returned from `love.joystick.getJoysticks`). The `joystick` argument is optional; if it's not specified, or if the joystick becomes unavailable later, the player object will just ignore controller inputs.

#### Updating players
You should update each player each frame by calling this function:
```lua
player:update()
```

#### Getting the value of controls
To get the value of an input, use:
```lua
value = player:get(control)
```
For example, for the controls defined above, we could get the value of the "left" control by doing
```lua
left = player:get 'left'
```
`player:get` always returns a number between 0 and 1, and as such, it is most applicable to controls that act as axes, such as movement controls. To get the value of a control without applying the deadzone, use `player:getRaw`.

#### Getting down, pressed, and released states
To see whether a control is currently "held down", use:
```lua
down = player:down(control)
```
`player:down` returns `true` if the values of the control is greater than the deadzone, and `false` if not.

```lua
pressed = player:pressed(control)
```
`player:pressed` return `true` if the control was pressed this `frame`, and false if not.

```lua
released = player:released(control)
```
`player:released` return `true` if the control was released this `frame`, and false if not.

These functions are most applicable for controls that act as buttons, such as a shoot button. That being said, they can be used for any control, which is useful if you want to, for example, use a movement control as a discrete button press to operate a menu.

#### Changing controls and deadzone
At any time, you can change the controls for a player by calling:
```lua
player:changeControls(controls)
```
Just pass in a new table of controls, and the player will seamlessly update to use the new controls.

You can also change the deadzone of the player by setting `player.deadzone` to a number between `0` and `1`. The deadzone is set to `0.5` by default.

If you need to access or change the joystick associated with a player, use `player.joystick` (which is just a standard LÖVE [Joystick](https://love2d.org/wiki/Joystick) object).

#### Getting the active input device
At any time, only the keyboard/mouse sources or the gamepad sources will be active. A device will be considered active if any of the sources for that device exceed the deadzone. The keyboard and mouse will always take precedence over the gamepad.

You can call `player:getActiveDevice()` to see which input device is currently active. It will either be `'keyboard'` or `'joystick'` (or `nil` if no inputs have been used yet). This is useful if you need to change what you display on screen based on the controls the player is using (such as instructions).

*Note:* mouse sources are counted under `keyboard`.

Contributing
============
This is very early software, and the design is not set in stone. Feel free to take it for a spin and suggest additions and changes (especially if you try making a multiplayer game with it!). Issues and pull requests are always welcome. To run the tests, use [busted](https://olivinelabs.com/busted/).

License
=======
MIT License

Copyright (c) 2016 Andrew Minnich

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
