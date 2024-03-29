-- state.lua
--
--

local motion = require("motion")
local Design = require("design")

-- Define a global variable to track the start time
local startTime = 0

-- Define a function to reset the start time
local function resetTimer()
    startTime = os.time()
end

-- Use the functions from utils
State = {
    explore = function()
        MY_design = "none"

        local rand_force = motion.Rand_force(RANDOM_FORCE_VALUE)
        local get_out_force = motion.Proximity_avoidance_force()

        local sum_force = { x = 0, y = 0 }
        sum_force.x = rand_force.x + get_out_force.x
        sum_force.y = rand_force.y + get_out_force.y

        motion.Speed_from_force(sum_force)

        for _, entry in ipairs(robot.range_and_bearing) do
            if (entry.data[1] == 1) then
                My_state = "find_resource"
                return
            elseif (entry.data[2] == 1) then
                My_state = "find_home"
                return
            end
        end

        if (#robot.colored_blob_omnidirectional_camera > 0) then
            My_state = "inspect"
            return
        end
    end,

    -- inspect state looks at the POI and determines
    -- if bot is to approach or keep exploring
    inspect = function()
        motion.Drive_as_car(0, 0)
        local timeout = 5 -- Timeout in seconds

        -- Check if start time is zero, if so, initialize it
        if startTime == 0 then
            resetTimer()
        end

        for _, value in ipairs(robot.colored_blob_omnidirectional_camera) do
            if (255 == value.color.green) then
                My_state = "approach"
                resetTimer() -- Reset timer upon finding a target
                return
            elseif (255 == value.color.blue) then
                My_state = "approach"
                resetTimer() -- Reset timer upon finding a beacon
                return
            end
        end

        -- Check if timeout has elapsed
        if os.time() - startTime >= timeout then
            My_state = "explore" -- Return to explore state
            resetTimer()         -- Reset timer upon timeout
        end
    end,

    --Find home state
    -- Look for the green LED
    find_home = function()
        MY_design = "none"
        local rand_force = motion.Rand_force(RANDOM_FORCE_VALUE)
        local get_out_force = motion.Proximity_avoidance_force()

        local sum_force = { x = 0, y = 0 }
        sum_force.x = rand_force.x + get_out_force.x
        sum_force.y = rand_force.y + get_out_force.y

        motion.Speed_from_force(sum_force)

        for _, entry in ipairs(robot.range_and_bearing) do
            if (#robot.colored_blob_omnidirectional_camera > 0)
                and entry
                and (entry.data[1] == 0) then -- Check if home base is not found
                My_state = "inspect"
                return
            end
        end
    end,

    --Find resource state
    -- Look for the blue LED
    find_resource = function()
        MY_design = "none"
        local rand_force = motion.Rand_force(RANDOM_FORCE_VALUE)
        local get_out_force = motion.Proximity_avoidance_force()

        local sum_force = { x = 0, y = 0 }
        sum_force.x = rand_force.x + get_out_force.x
        sum_force.y = rand_force.y + get_out_force.y

        motion.Speed_from_force(sum_force)

        for _, entry in ipairs(robot.range_and_bearing) do
            if (#robot.colored_blob_omnidirectional_camera > 0)
                and entry
                and (entry.data[2] == 0) then -- Check if resource is not found
                My_state = "inspect"
                return
            end
        end
    end,

    beacon = function()
        motion.Drive_as_car(0, 0)
        log("Found a POI")
        MY_design = "home_beacon"

        for _, value in ipairs(robot.colored_blob_omnidirectional_camera) do
            if (255 == value.color.green) then
                robot.range_and_bearing.set_data(1, 1)
            elseif (255 == value.color.blue) then
                robot.range_and_bearing.set_data(2, 1)
            end
        end

        if robot.range_and_bearing[1].data[1] == 1
            or robot.range_and_bearing[1].data[2] == 1 then
            My_state = "explore"
        end
    end,

    halt = function()
        motion.Drive_as_car(0, 0)
    end,

    approach = function()
        local timeout = 5 -- Timeout in seconds

        -- Check if start time is zero, if so, initialize it
        if startTime == 0 then
            resetTimer()
        end

        motion.Speed_from_force(motion.Camera_force(true, true))

        local foundTarget = false

        for _, entry in ipairs(robot.range_and_bearing) do
            if entry and entry.data[1] == 1 then
                My_state = "find_resource"
                foundTarget = true
                break
            elseif entry and entry.data[2] == 1 then
                My_state = "find_home"
                foundTarget = true
                break
            end
        end

        if not foundTarget then
            -- Approach the POI
            local found_proximity_1 = false

            for i = 1, 24 do
                if robot.proximity[i].value == 1 then
                    found_proximity_1 = true
                    break
                end
            end

            if found_proximity_1 then
                My_state = "halt"
                robot.gripper.lock_negative()
                robot.turret.set_passive_mode()
                log("Locked & Loaded!")
                My_state = "beacon"
            end

            -- Check if timeout has elapsed or target is lost
            if os.time() - startTime >= timeout or #robot.colored_blob_omnidirectional_camera == 0 then
                My_state = "explore" -- Return to explore state
                resetTimer()         -- Reset timer upon timeout or losing target
            end
        else
            resetTimer() -- Reset timer upon finding a target
        end
    end,

    deliver = function()
        log("Delivering!")
        motion.Speed_from_force(motion.Proximity_avoidance_force())
        MY_design = "none"
        Design[MY_design]()

        -- TODO: Implement delivery logic based on specific requirements
    end,
}

return State
