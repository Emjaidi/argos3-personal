-- motion.lua
--

local motion = {}

function motion.Drive_as_car(forwardSpeed, angularSpeed)
    -- We have an equal component, and an opposed one
    local leftSpeed  = forwardSpeed - angularSpeed
    local rightSpeed = forwardSpeed + angularSpeed
    robot.wheels.set_velocity(leftSpeed, rightSpeed)
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

function motion.rnb_force()
    local rnbForce = { x = 0, y = 0 }

    -- loop through range_and_bearing
    for _, entry in ipairs(robot.range_and_bearing) do
        -- locate the angle of the message where home beacon
        -- is being transmitted
        if entry and entry.data[1] == 1 
            or entry and entry.data[2] == 1 then
            -- if 
            log("Angle is: " .. entry.horizontal_bearing)
            log("Dist is: " .. entry.range)
            local angle = entry.horizontal_bearing
            local dist = entry.range
            val = 35 * dist / 80
            log("Val is: " .. val)
            rnbForce.x = val * math.cos(angle)
            log("rnbForce.x is: " .. rnbForce.x)
            rnbForce.y = val * math.sin(angle)
            log("rnbForce.y is: " .. rnbForce.y)
            return rnbForce
        else
            return rnbForce
        end
    end
end

return motion
