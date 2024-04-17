-- motion.lua
--

local motion = {}

function motion.Drive_as_car(forwardSpeed, angularSpeed)
    -- We have an equal component, and an opposed one
    local leftSpeed  = forwardSpeed - angularSpeed
    local rightSpeed = forwardSpeed + angularSpeed
    robot.wheels.set_velocity(leftSpeed, rightSpeed)
end

function motion.oscillate(amplitude, period)
    -- Define the oscillation parameters
    -- Get the current time
    local currentTime = os.time()
    -- Calculate the phase of the oscillation
    local phase = (currentTime % period) / period
    -- Calculate the velocity based on the phase
    local velocity = amplitude * math.sin(2 * math.pi * phase)
    -- Set the robot's motion
    motion.Drive_as_car(velocity, 2)
end

function motion.range_force(target)
    local rnbForce = { x = 0, y = 0 }

    -- Locate the angle of the message where home beacon or resource beacon is being transmitted
    if nil ~= target and nil ~= target.range and nil ~= target.horizontal_bearing then
        local angle = target.horizontal_bearing
        local dist = target.range
        local force_magnitude = 20 * dist / 80

        rnbForce.x = force_magnitude * math.cos(angle)
        rnbForce.y = force_magnitude * math.sin(angle)
        else
            return rnbForce
    end
    return rnbForce
end

function motion.rnb_force(target)
    local rnbForce = { x = 0, y = 0 }

    -- Locate the angle of the message where home beacon or resource beacon is being transmitted
    local angle = target.horizontal_bearing
    local dist = target.range
    local force_magnitude = 20 * dist / 80

    rnbForce.x = force_magnitude * math.cos(angle)
    rnbForce.y = force_magnitude * math.sin(angle)

    return rnbForce
end

function motion.Speed_from_force(f)
    local forward_speed = f.x * 1.0
    local angular_speed = f.y * 0.3

    local left_speed = forward_speed - angular_speed
    local right_speed = forward_speed + angular_speed

    robot.wheels.set_velocity(left_speed, right_speed)
end

function motion.Rand_force(val)
    local angle = robot.random.uniform(-math.pi / 2, math.pi / 2)
    local random_force = { x = val * math.cos(angle), y = val * math.sin(angle) }

    return random_force
end

function motion.Proximity_avoidance_force()
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

function motion.Camera_force(attraction, strong)
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

--[[
function motion.rnb_force(target)
    local rnbForce = { x = 0, y = 0 }

    -- Locate the angle of the message where home beacon or resource beacon is being transmitted
    local angle = target.horizontal_bearing
    local dist = target.range
    local force_magnitude = 20 * dist / 80

    rnbForce.x = force_magnitude * math.cos(angle)
    rnbForce.y = force_magnitude * math.sin(angle)

    return rnbForce
end
------------]]

function motion.random_walk()
    local rand_force = motion.Rand_force(RANDOM_FORCE_VALUE)
    local get_out_force = motion.Proximity_avoidance_force()

    local sum_force = { x = 0, y = 0 }
    sum_force.x = rand_force.x + get_out_force.x
    sum_force.y = rand_force.y + get_out_force.y

    motion.Speed_from_force(sum_force)
end

return motion
