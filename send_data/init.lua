---@diagnostic disable: undefined-global
-- Use Shift + Click to select a robotNone
-- When a robot is selected, its variables appear in this editor

-- Use Ctrl + Click (Cmd + Click on Mac) to move a selected robot to a different location



-- Put your global variables here
local My_state = "explore"

local found_table = {}

local messages = { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 }

RANDOM_FORCE_VALUE = 50

TARGET_DISTANCE = 160

T = 0
TMAX = 0

-- Used for the leds
CPT = 1
UP = true

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

Design = {
    robocop = function()
        -- led
        if (UP) then
            CPT = CPT + 1
        else
            CPT = CPT - 1
        end

        if (CPT > 6) then
            UP = false
        end

        if (CPT < 4) then
            UP = true
        end

        -- display
        robot.leds.set_all_colors("black")

        local cpt_to_led = { 9, 8, 10, 11, 12, 1, 2, 3, 4, 5 } -- to get right offset of LEDs


        if (cpt_to_led[CPT] % 2 == 0) then
            robot.leds.set_single_color(cpt_to_led[CPT], "cyan")
        else
            robot.leds.set_single_color(cpt_to_led[CPT], "red")
        end

        --13 LED Blinking State
        T = T + 1
        if (T < TMAX) then
            T = T + 1
            robot.leds.set_single_color(13, "black")
        else
            T = 0
            robot.leds.set_single_color(13, "yellow")
        end

        -- Sync
        if (#robot.colored_blob_omnidirectional_camera > 0) then
            T = T + 0.2 * T
        end
    end,

    none = function()
        robot.leds.set_all_colors("black")
    end,


    home_beacon = function()
        T = T + 1
        if (T < TMAX) then
            T = T + 1
            robot.leds.set_single_color(13, "black")
        else
            T = 0
            robot.leds.set_single_color(13, "yellow")
        end
    end,
}


local State = {
    explore = function()
        MY_design = "none"
        local rand_force = Rand_force(RANDOM_FORCE_VALUE)
        local get_out_force = Proximity_avoidance_force()

        local sum_force = { x = 0, y = 0 }
        sum_force.x = rand_force.x + get_out_force.x
        sum_force.y = rand_force.y + get_out_force.y

        Speed_from_force(sum_force)

        --end driving

        -- TODO when a resource is found (specific LED)
        -- the State changes to form a path to the resource
        -- the bot can transmit a message or
        -- change the design of its LEDs to point to the resource
        if (#robot.colored_blob_omnidirectional_camera > 0) then
            if (robot.colored_blob_omnidirectional_camera[1].color.blue == 255) then
                My_state = "beacon"
            end
        end
    end,

    beacon = function()
        --[[ Robot.range_and_bearing is a table visualized as:
        --| Position | Message Meaning |
        --| -------- | --------------- |
        --| 1        | home base found | 0/1
        --| 2        | resource found  | 0/1
        --| 3        | tbd             |
        --| 4        | tbd             |
        --| 5        | tbd             |
        --| 6        | tbd             |
        --| 7        | tbd             |
        --| 8        | tbd             |
        --| 9        | tbd             |
        --| 10       | tbd             |
        --For this program I will repurpose the meaning of the each position
        --Elaborated above
        --TODO determine if this should be set globally
        --]]
        Drive_as_car(0, 0)
        log("Found a POI")
        robot.range_and_bearing.set_data(1, 2)
        if robot.range_and_bearing ~= nil then
            for i = 1, #robot.range_and_bearing do
                log("----------------------------------------")
                log("message: ", robot.range_and_bearing[i].data[i])
                log("from: ", robot.id)
                log("distance: ", robot.range_and_bearing[i].range)
                log("direction: ", robot.range_and_bearing[i].horizontal_bearing)
            end
        end
        MY_design = "home_beacon"
    end,

    halt = function()
        Drive_as_car(0, 0)
        --LED_Design()
    end,

    approach = function()
        -- Approaches the LED
        -- TODO approach only if the LED is a resource/
        -- TODO use the robot.light function  to approach the head footbot
        Speed_from_force(Camera_force(true, true))
        log(robot.proximity[1].value)
        if robot.proximity[1].value == 1 then
            My_state = "halt"
            robot.turret.set_passive_mode()
            robot.gripper.lock_negative()
            log("Locked & Loaded!")
            My_state = "deliver"
        end
        if (0 == #robot.colored_blob_omnidirectional_camera) then
            My_state = "explore"
        end
    end,

    deliver = function()
        log("Delivering!")
        Speed_from_force(Proximity_avoidance_force())
        MY_design = "none"
        Design[MY_design]()
        --LED_Design()
    end,

}

function add_to_found_table(bot_name, home, resource)
    -- Check if the bot already exists in the found table
    local bot_entry = found_table[bot_name]
    if bot_entry == nil then
        -- If the bot doesn't exist, create a new nested table
        found_table[bot_name] = { { home = home, resource = resource } }
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
    robot.range_and_bearing.set_data(messages)
end

--[[ This function is executed at each time step
     It must contain the logic of your controller ]]
function step()
    robot.range_and_bearing.set_data(messages)
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
    robot.range_and_bearing.set_data(messages)
end

--[[ This function is executed only once, when the robot is removed
     from the simulation ]]
function destroy()
    -- put your code here
end
