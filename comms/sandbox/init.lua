-- Use Shift + Click to select a robot
-- When a robot is selected, its variables appear in this editor

-- Use Ctrl + Click (Cmd + Click on Mac) to move a selected robot to a different location



-- Put your global variables here

	-- Turning backwards left/right
self_left_speed = robot.wheels.set_velocity(-20,20)
self_right_speed = robot.wheels.set_velocity(20,-20)	
	-- Using the sensors on the left/right side


function Drive_as_car(forwardSpeed, angularSpeed)
-- We have an equal component, and an opposed one   
	leftSpeed  = forwardSpeed - angularSpeed
	rightSpeed = forwardSpeed + angularSpeed
	robot.wheels.set_velocity(leftSpeed,rightSpeed)
end

function Stop_wheel()
	Drive_as_car(0,0)
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

	sensing_forward =  robot.proximity[1].value + robot.proximity[2].value + robot.proximity[23].value

	sensing_left =  robot.proximity[1].value + robot.proximity[2].value + robot.proximity[3].value + robot.proximity[4].value + robot.proximity[5].value + robot.proximity[6].value

	sensing_right =  robot.proximity[24].value + robot.proximity[23].value + robot.proximity[22].value + robot.proximity[21].value +	robot.proximity[20].value + robot.proximity[19].value

	-- Using the sensors on the back left/right side
	sensing_back_left = robot.proximity[12].value + robot.proximity[9].value + robot.proximity[10].value + robot.proximity[11].value

	sensing_back_right = robot.proximity[17].value + robot.proximity[16].value + robot.proximity[15].value + robot.proximity[18].value
	
	if( sensing_left ~= 0 ) then
		Stop_wheel()
		Drive_as_car(4,-5)
		log("1")
	elseif( sensing_right ~= 0) then		
		Stop_wheel()
		Drive_as_car(4,5)
		log("2")
	elseif( sensing_forward ~= 0) then		
		Stop_wheel()
		Drive_as_car(4,5)
		log("2")
	else
		Drive_as_car(20,0)
		log("5")
	end	
--[[ driveAsCar(20,0) 
	x = robot.proximity[1].angle
	log(x)
]]--
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
