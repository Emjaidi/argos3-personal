-- state.lua
--

local motion = require("motion")
local Design = require("design")

-- Define a global variable to track the start time
local startTime = 0

local timeout = 2 -- Timeout in seconds
-- Define a function to reset the start time
local function resetTimer()
    startTime = os.time()
end

found_home = false
found_resource = false

State = {
    explore = function() -- random walk
        MY_design = "none"

        motion.random_walk()

        if found_home == true
            and found_resource == true then
            My_state = "find_beacon"
        end

        if (#robot.colored_blob_omnidirectional_camera > 0) then
            My_state = "inspect"
            return
        end
    end,

    approach = function() -- inspect state looks at the POI and determines
        -- halt when another robot is approaching the POI
        for _, entry in ipairs(robot.range_and_bearing) do
            if entry and entry.data[6] == 1 then
                My_state = "halt"
            end
        end

        local proximityMinCount = 1 -- Minimum number of activated proximity sensors required

        -- Check if start time is zero, if so, initialize it
        if startTime == 0 then
            resetTimer()
        end

        motion.Speed_from_force(motion.Camera_force(true, true))


        local foundTarget = false

        if not foundTarget then
            motion.Speed_from_force(motion.Camera_force(true, true))
            -- Approach the POI

            robot.range_and_bearing.set_data(6, 1)

            local proximityCount = 0

            for i = 1, 24 do
                if robot.proximity[i].value == 1 then
                    proximityCount = proximityCount + 1
                end
            end

            log("Proximity Count: " .. proximityCount)

            local proximityDistance = 20

            if proximityCount >= proximityMinCount then
                -- Hysteresis: Require proximity activation for a certain distance
                if #robot.colored_blob_omnidirectional_camera > 0 then
                    local distance = robot.colored_blob_omnidirectional_camera[1].distance
                    log("Proximity activation ongoing. Distance: " .. distance)

                    if distance <= proximityDistance then
                        -- Proximity activation sustained within the required distance
                        log("Proximity activation sustained within " .. proximityDistance .. " meters")
                        My_state = "halt"
                        robot.gripper.lock_negative()
                        robot.turret.set_passive_mode()
                        log("Locked & Loaded!")
                        My_state = "beacon"
                    end
                else
                    log("No colored blob detected")
                end
            else
                log("Proximity activation not sustained")
            end
            -- Combine multiple sensor inputs for target loss detection
            local targetLost = (#robot.colored_blob_omnidirectional_camera == 0)

            -- Check if timeout has elapsed or target is lost
            if os.time() - startTime >= timeout or targetLost then
                My_state = "explore" -- Return to explore state
                resetTimer()         -- Reset timer upon timeout or losing target
            end
        else
            resetTimer() -- Reset timer upon finding a target
        end
    end,

    inspect = function() -- if bot is to approach or keep exploring
        motion.Drive_as_car(0, 0)
        local blobDetectionCount = 0
        local requiredDetectionCount = 1

        -- Check if start time is zero, if so, initialize it
        if startTime == 0 then
            resetTimer()
        end

        -- determine if there are any messages being received
        -- that indicate that POI is already found & which one is it
        for _, entry in ipairs(robot.range_and_bearing) do
            if (entry.data[2] == 0) -- nothing is found
                and (entry.data[1] == 0)
                and (found_resource == false)
                and (found_home == false) then
                for _, value in ipairs(robot.colored_blob_omnidirectional_camera) do
                    if (255 == value.color.green) or (255 == value.color.blue) then
                        blobDetectionCount = blobDetectionCount + 1
                    end
                end

                if blobDetectionCount >= requiredDetectionCount then
                    -- Hysteresis: Require consecutive detections before transitioning
                    My_state = "approach"
                    resetTimer()
                    return
                end
            elseif (entry.data[1] == 1) -- home found and resource is found
                and found_resource == true then
                -- connect to beacon
                My_state = "connect_to_beacon"
                return
            elseif (entry.data[2] == 1) -- resource beacon is found and home is found
                and found_home == true then
                -- connect to beacon
                My_state = "connect_to_beacon"
                return
            elseif (entry.data[1] == 1) -- home beacon found time to find resource
                and found_resource == false then
                -- connect to beacon
                My_state = "find_resource"
                found_home = true
                return
            elseif (entry.data[2] == 1) -- resource found time to find home
                and found_home == false then
                -- connect to beacon
                My_state = "find_home"
                found_resource = true
                return
            end
        end



        -- Check if timeout has elapsed
        if os.time() - startTime >= timeout then
            My_state = "explore" -- Return to explore state
            resetTimer()         -- Reset timer upon timeout
        end
    end,

    find_home = function() -- Find home state; Look for the green LED
        MY_design = "none"

        motion.random_walk()

        for _, entry in ipairs(robot.range_and_bearing) do
            if (#robot.colored_blob_omnidirectional_camera > 0)
                and entry
                and (entry.data[1] == 0) then -- Check if home base is not found
                My_state = "inspect"
                return
            end
        end
    end,

    find_resource = function() --Find resource state; Look for the blue LED
        MY_design = "none"

        motion.random_walk()

        for _, entry in ipairs(robot.range_and_bearing) do
            if (#robot.colored_blob_omnidirectional_camera > 0)
                and entry
                and (entry.data[2] == 0) then -- Check if resource is not found
                My_state = "inspect"
                return
            end
        end
    end,

    find_beacon = function()
        MY_design = "none"

        motion.random_walk()

        for _, entry in ipairs(robot.range_and_bearing) do
            if (#robot.colored_blob_omnidirectional_camera > 0)
                and entry
                and (entry.data[2] == 0) then -- Check if resource is not found
                My_state = "inspect"
                return
            end
        end
    end,

    connect_to_beacon = function()
        local proximityMinCount = 1 -- Minimum number of activated proximity sensors required
        local foundTarget = false

        -- Check if start time is zero, if so, initialize it
        if startTime == 0 then
            resetTimer()
        end

        motion.Speed_from_force(motion.rnb_force())

        for _, entry in ipairs(robot.range_and_bearing) do
            if not foundTarget then
                motion.Speed_from_force(motion.rnb_force())
                -- Approach the POI
                local proximityCount = 0

                for i = 1, 24 do
                    if robot.proximity[i].value == 1 then
                        proximityCount = proximityCount + 1
                    end
                end

                log("Proximity Count: " .. proximityCount)

                local proximityDistance = 20

                if proximityCount >= proximityMinCount then
                    -- Hysteresis: Require proximity activation for a certain distance
                    local distance = entry.range
                    log("Proximity activation ongoing. Distance: " .. distance)

                    if distance <= proximityDistance then
                        -- Proximity activation sustained within the required distance
                        log("Proximity activation sustained within " .. proximityDistance .. " meters")
                        My_state = "halt"
                        robot.gripper.lock_negative()
                        robot.turret.set_passive_mode()
                        log("Locked & Loaded!")
                        My_state = "beacon"
                    end
                else
                    log("Proximity activation not sustained")
                end
                -- Combine multiple sensor inputs for target loss detection
                local targetLost = (#entry == 0)

                -- Check if timeout has elapsed or target is lost
                if os.time() - startTime >= timeout or targetLost then
                    My_state = "explore" -- Return to explore state
                    resetTimer()         -- Reset timer upon timeout or losing target
                end
            else
                resetTimer() -- Reset timer upon finding a target
            end
        end
    end,

    link = function()
        MY_design = "none"
        motion.Drive_as_car(0, 0)
        robot.range_and_bearing.set_data(5, 1)
        log(robot.id .. " I am a link")
    end,

    beacon = function()
        motion.Drive_as_car(0, 0)
        log("Found a POI")
        robot.range_and_bearing.set_data(6, 0)

        for _, value in ipairs(robot.colored_blob_omnidirectional_camera) do
            if (255 == value.color.green) then
                robot.range_and_bearing.set_data(1, 1)
                MY_design = "home_beacon"
                found_home = true
            elseif (255 == value.color.blue) then
                robot.range_and_bearing.set_data(2, 1)
                MY_design = "resource_beacon"
                found_resource = true
            end
        end

        for _, entry in ipairs(robot.range_and_bearing) do
            if entry and entry.data[5] == 1 then
                My_state = "link"
            end
        end

        for _, entry in ipairs(robot.range_and_bearing) do
            if entry.data[1] == 1
                or entry.data[2] == 1 then
                My_state = "explore"
            end
        end
    end,

    halt = function()
        robot.range_and_bearing.set_data(6, 0)
        -- Check if start time is zero, if so, initialize it
        if startTime == 0 then
            resetTimer()
        end
        motion.Drive_as_car(0, 0)
        if os.time() - startTime >= timeout then
            motion.Speed_from_force(motion.Camera_force(false, true))
            My_state = "inspect" -- Return to explore state
            resetTimer()         -- Reset timer upon timeout or losing target
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
