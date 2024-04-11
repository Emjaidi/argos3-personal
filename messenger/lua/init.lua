---@diagnostic disable: undefined-global
-- Use Shift + Click to select a robotNone
-- When a robot is selected, its variables appear in this editor

-- Use Ctrl + Click (Cmd + Click on Mac) to move a selected robot to a different location

local State = require("state")

local Design = require("design")

-- Put your global variables here
My_state = {}

found_home = false
found_resource = false
home_found = false
resource_found = false

-- Used to reset the range_and_bearing data set

RANDOM_FORCE_VALUE = 50

TARGET_DISTANCE = 160

T = 0
TMAX = 0

-- Used for the leds
CPT = 1
UP = true

BOT_COUNT = 20

function is_messenger() -- create 3 robots that are messengers
    local minimum_population = 3;

end


--[[ This function is executed every time you press the 'execute' button ]]
function init()
    -- put your code here	
    robot.colored_blob_omnidirectional_camera.enable()
    TMAX = 100
    T = math.floor(math.random(0, TMAX))
    My_state = "explore"
end

--[[ This function is executed at each time step
     It must contain the logic of your controller ]]
function step()
    State[My_state]()
    Design[MY_design]()
end

--[[ This function is executed every time you press the 'reset'
     button in the GUI. It is supposed to restore the State
     of the controller to whatever it was right after init() was
     called. The State of sensors and actuators is reset
     automatically by ARGoS. ]]
function reset()
    -- put your code here
    My_state = "explore"
    State[My_state]()
    MY_design = "none"
    Design[MY_design]()
    found_home = false
    found_resource = false
    home_found = false
    resource_found = false
end

--[[ This function is executed only once, when the robot is removed
     from the simulation ]]
function destroy()
    -- put your code here
end
