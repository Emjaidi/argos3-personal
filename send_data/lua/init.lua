---@diagnostic disable: undefined-global
-- Use Shift + Click to select a robotNone
-- When a robot is selected, its variables appear in this editor

-- Use Ctrl + Click (Cmd + Click on Mac) to move a selected robot to a different location

local State = require("state")

local Design = require("design")

-- Put your global variables here
My_state = "explore"

Found_table = {}

-- Used to reset the range_and_bearing data set

RANDOM_FORCE_VALUE = 50

TARGET_DISTANCE = 160

T = 0
TMAX = 0

-- Used for the leds
CPT = 1
UP = true

--[[
function Drive_as_car(forwardSpeed, angularSpeed)
    -- We have an equal component, and an opposed one
    local leftSpeed  = forwardSpeed - angularSpeed
    local rightSpeed = forwardSpeed + angularSpeed
    robot.wheels.set_velocity(leftSpeed, rightSpeed)
end

function Speed_from_force(f)
    local forward_speed = f.x * 1.0
    local angular_speed = f.y * 0.3

    local left_speed = forward_speed - angular_speed
    local right_speed = forward_speed + angular_speed

    robot.wheels.set_velocity(left_speed, right_speed)
end

function Rand_force(val)
    local angle = robot.random.uniform(-math.pi / 2, math.pi / 2)
    local random_force = { x = val * math.cos(angle), y = val * math.sin(angle) }

    return random_force
end

function Proximity_avoidance_force()
    local avoidance_force = { x = 0, y = 0 }
    for i = 1, 24 do
        -- "-100" for a strong repulsion
        local v = -100 * robot.proximity[i].value
        local a = robot.proximity[i].angle

        local sensor_force = { x = v * math.cos(a), y = v * math.sin(a) }
        avoidance_force.x = avoidance_force.x + sensor_force.x
        avoidance_force.y = avoidance_force.y + sensor_force.y
    end
    return avoidance_force
end

function Camera_force(attraction, strong)
    local camForce = { x = 0, y = 0 }

    -- Check if there is a light seen
    if (#robot.colored_blob_omnidirectional_camera == 0) then
        return camForce
    end

    local dist = robot.colored_blob_omnidirectional_camera[1].distance
    local angle = robot.colored_blob_omnidirectional_camera[1].angle

    -- Max range defined at 80 cm
    if (dist > 80) then
        return camForce
    end

    -- Strong or Weak reaction
    if (strong) then
        val = 35 * dist / 80
    else
        val = 35 * (1 - dist / 80)
    end

    -- Attraction or Repulsion
    if (not attraction) then
        val = -val
    end

    camForce.x = val * math.cos(angle)
    camForce.y = val * math.sin(angle)
    return camForce
end

--]]
--
function add_to_found_table(bot_name, home, resource)
    -- Check if the bot already exists in the found table
    local bot_entry = Found_table[bot_name]
    if bot_entry == nil then
        -- If the bot doesn't exist, create a new nested table
        Found_table[bot_name] = { { home = home, resource = resource } }
    else
        -- If the bot already exists, check for redundancy
        for _, entry in ipairs(bot_entry) do
            if entry.home == home and entry.resource == resource then
                -- Redundant entry, skip adding
                return
            end
        end
        -- If not redundant, add a new entry to the nested table
        table.insert(bot_entry, { home = home, resource = resource })
    end
end

--[[ This function is executed every time you press the 'execute' button ]]

function init()
    -- put your code here	
    robot.colored_blob_omnidirectional_camera.enable()
    TMAX = 100
    T = math.floor(math.random(0, TMAX))
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
end

--[[ This function is executed only once, when the robot is removed
     from the simulation ]]
function destroy()
    -- put your code here
end
