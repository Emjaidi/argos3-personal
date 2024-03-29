-- Use Shift + Click to select a robotNone
-- When a robot is selected, its variables appear in this editor

-- Use Ctrl + Click (Cmd + Click on Mac) to move a selected robot to a different location



-- Put your global variables here
RANDOM_FORCE_VALUE = 50

TARGET_DISTANCE = 160

t = 0
tmax = 0

-- Used for the leds
cpt = 1
bcpt = 7
up = true
down = true

function Drive_as_car(forwardSpeed, angularSpeed)
    -- We have an equal component, and an opposed one
    leftSpeed  = forwardSpeed - angularSpeed
    rightSpeed = forwardSpeed + angularSpeed
    robot.wheels.set_velocity(leftSpeed, rightSpeed)
end

function Speed_from_force(f)
    forward_speed = f.x * 1.0
    angular_speed = f.y * 0.3

    left_speed = forward_speed - angular_speed
    right_speed = forward_speed + angular_speed

    robot.wheels.set_velocity(left_speed, right_speed)
end

function Rand_force(val)
    angle = robot.random.uniform(-math.pi / 2, math.pi / 2)
    random_force = { x = val * math.cos(angle), y = val * math.sin(angle) }
    return random_force
end

function Proximity_avoidance_force()
    avoidance_force = { x = 0, y = 0 }
    for i = 1, 24 do
        -- "-100" for a strong repulsion
        v = -100 * robot.proximity[i].value
        a = robot.proximity[i].angle

        sensor_force = { x = v * math.cos(a), y = v * math.sin(a) }
        avoidance_force.x = avoidance_force.x + sensor_force.x
        avoidance_force.y = avoidance_force.y + sensor_force.y
    end
    return avoidance_force
end

function cameraForce(attraction, strong)
    camForce = { x = 0, y = 0 }

    -- Check if there is a light seen
    if (#robot.colored_blob_omnidirectional_camera == 0) then
        return camForce
    end

    dist = robot.colored_blob_omnidirectional_camera[1].distance
    angle = robot.colored_blob_omnidirectional_camera[1].angle

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

--[[
function state.bot_light()
    Drive_as_car(7,3)
    --Display of the bot light
    robot.leds.set_all_colors("black")

   cpt_to_led =  {}-- to get right offset of LEDs

    for i=1, 12 do
      cpt_to_led[i] = 1
    end

    if(cpt_to_led[cpt] % 2 == 0) then
        robot.leds.set_single_color(cpt_to_led[cpt],"yellow")
    else
        robot.leds.set_single_color(cpt_to_led[cpt],"black")
    end
end

function state.explore()
    --
    -- Driving
    rand_force = Rand_force(RANDOM_FORCE_VALUE)
    get_out_force = Proximity_avoidance_force()

    sum_force = {x=0, y=0}
    sum_force.x = rand_force.x + get_out_force.x
    sum_force.y = rand_force.y + get_out_force.y

    Speed_from_force(sum_force)

    --end driving



end
--]]

function LED_Design()
    -- led
    --[[
    if(up) then
        cpt = cpt + 1
    else
        cpt = cpt - 1
    end

    if(cpt>6) then
        up = false
    end

    if(cpt<4) then
        up = true
    end
    --]]

    -- display
    --[[
    robot.leds.set_all_colors("black")

    cpt_to_led = {9,8,10,11,12,1,2,3,4,5} -- to get right offset of LEDs


    if(cpt_to_led[cpt] % 2 == 0) then
        robot.leds.set_single_color(cpt_to_led[cpt],"cyan")
    else
        robot.leds.set_single_color(cpt_to_led[cpt],"red")
    end

    --13 LED Blinking state
    t = t + 1
    --]]

    if (my_state == "halt") then
        robot.leds.set_single_color(13, "red")
    else
        robot.leds.set_single_color(13, "green")
    end
    --[[
    if(t<tmax) then
        t = t + 1
        robot.leds.set_single_color(13,"black")
    else
        t = 0
        robot.leds.set_single_color(13,"yellow")
    end
    --]]

    -- Sync
    --[[
    if(#robot.colored_blob_omnidirectional_camera > 0) then
        t = t + 0.2 * t
    end
    --]]
end

local my_state = "explore"

local state = {
    explore = function()
        rand_force = Rand_force(RANDOM_FORCE_VALUE)
        get_out_force = Proximity_avoidance_force()

        sum_force = { x = 0, y = 0 }
        sum_force.x = rand_force.x + get_out_force.x
        sum_force.y = rand_force.y + get_out_force.y

        Speed_from_force(sum_force)

        --end driving
        --LED_Design()

        -- TODO when a resource is found (specific LED)
        -- the state changes to form a path to the resource
        -- the bot can transmit a message or
        -- change the design of its LEDs to point to the resource
        if (#robot.colored_blob_omnidirectional_camera > 0) then
            log(robot.colored_blob_omnidirectional_camera)
            --[[if (robot.colored_blob_omnidirectional_camera[1].color.blue == 255
                --]]
            if (robot.colored_blob_omnidirectional_camera[1].color.blue == 255) then
                log(robot.id .. " says o yeah")
                log(robot.colored_blob_omnidirectional_camera[1].distance)
                my_state = "halt"
            end
        end
    end,

    halt = function()
        Drive_as_car(0, 0)
        --LED_Design()
    end,

}
--[[ This function is executed every time you press the 'execute' button ]]

function init()
    -- put your code here	
    robot.colored_blob_omnidirectional_camera.enable()
    tmax = 100
    t = math.floor(math.random(0, tmax))
end

--[[ This function is executed at each time step
     It must contain the logic of your controller ]]
function step()
    state[my_state]()
end

--[[ This function is executed every time you press the 'reset'
     button in the GUI. It is supposed to restore the state
     of the controller to whatever it was right after init() was
     called. The state of sensors and actuators is reset
     automatically by ARGoS. ]]
function reset()
    -- put your code here
end

--[[ This function is executed only once, when the robot is removed
     from the simulation ]]
function destroy()
    -- put your code here
end
