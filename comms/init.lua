-- Use Shift + Click to select a robot
-- When a robot is selected, its variables appear in this editor

-- Use Ctrl + Click (Cmd + Click on Mac) to move a selected robot to a different location



-- Put your global variables here
RANDOM_FORCE_VALUE = 30

function Drive_as_car(forwardSpeed, angularSpeed)
-- We have an equal component, and an opposed one   
	leftSpeed  = forwardSpeed - angularSpeed
	rightSpeed = forwardSpeed + angularSpeed
	robot.wheels.set_velocity(leftSpeed,rightSpeed)
end

function Speed_from_force(f)
    forward_speed = f.x * 1.0
    angular_speed = f.y * 0.3

    left_speed = forward_speed - angular_speed
    right_speed = forward_speed + angular_speed

    robot.wheels.set_velocity(left_speed, right_speed)
end

function Rand_force(val)
    angle = robot.random.uniform(- math.pi/2, math.pi/2)
    random_force = {x = val * math.cos(angle), y = val * math.sin(angle) }
    return random_force
end

function Proximity_avoidance_force()
    avoidance_force = {x = 0, y = 0}
    for i = 1,24 do
        -- "-100" for a strong repulsion 
        v = -100 * robot.proximity[i].value 
        a = robot.proximity[i].angle

        sensor_force = {x = v * math.cos(a), y = v * math.sin(a)}
        avoidance_force.x = avoidance_force.x + sensor_force.x
        avoidance_force.y = avoidance_force.y + sensor_force.y
    end
    return avoidance_force
end



--[[ This function is executed every time you press the 'execute' button ]]
function init() 
   -- put your code here	
	robot.leds.set_all_colors("yellow")
	robot.leds.set_single_color(13, "red")
end



--[[ This function is executed at each time step
     It must contain the logic of your controller ]]
function step()

    rand_force = Rand_force(RANDOM_FORCE_VALUE)
    get_out_force = Proximity_avoidance_force()

    sum_force = {x=0, y=0}
    sum_force.x = rand_force.x + get_out_force.x
    sum_force.y = rand_force.y + get_out_force.y

    Speed_from_force(sum_force)
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
