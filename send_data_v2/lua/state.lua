-- state.lua
--

local motion = require("motion")
local Design = require("design")

-- Define a global variable to track the start time
local zero_data = {}

for i = 1, 10 do
    zero_data[i] = 0
end

local startTime = 0

local timeout = 2 -- Timeout in seconds
-- Define a function to reset the start time
local function resetTimer()
    startTime = os.time()
end

local requiredDetectionCount = 1
local blobDetectionCount = 0

State = {
    explore = function() -- random walk
        MY_design = "none"

        motion.random_walk()

        -- if bot is exploring then data being sent should be 0 for all necessary
        robot.range_and_bearing.set_data(zero_data)
        robot.gripper.unlock() -- release gripper

        if found_home == true
            and found_resource == true then
            My_state = "find_beacon"
        end

        if (#robot.colored_blob_omnidirectional_camera > 0) then
            My_state = "inspect"
            return
        end
    end,

    approach = function()
        robot.gripper.unlock()
        robot.range_and_bearing.set_data(zero_data)

        local proximityMinCount = 1
        local proximityDistance = 15
        local targetLocked = false

        if startTime == 0 then
            resetTimer()
        end

        -- Check if another robot has already locked the target
        for _, entry in ipairs(robot.range_and_bearing) do
            if entry and entry.data[6] == 1 then
                targetLocked = true
                break
            end
        end

        if not targetLocked then
            motion.Speed_from_force(motion.Camera_force(true, true))

            -- Approach the POI
            robot.range_and_bearing.set_data(6, 1) -- send data that it is approaching

            local proximityCount = 0
            for i = 1, 24 do
                proximityCount = proximityCount + robot.proximity[i].value
            end

            if proximityCount >= proximityMinCount then
                if #robot.colored_blob_omnidirectional_camera > 0 then
                    local distance = robot.colored_blob_omnidirectional_camera[1].distance

                    if distance <= proximityDistance then
                        My_state = "halt"
                        robot.gripper.lock_positive()
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
        else
            log("Target already locked by another robot")
            My_state = "explore"
            resetTimer()
        end

        local targetLost = (#robot.colored_blob_omnidirectional_camera == 0)

        if os.time() - startTime >= timeout or targetLost then
            My_state = "explore"
            resetTimer()
        end
    end,

    -- observe any messages or leds that are being detected
    inspect = function()
        motion.Drive_as_car(0, 0)
        robot.gripper.unlock()                      -- release gripper if attached to anything
        robot.range_and_bearing.set_data(zero_data) -- reset information being sent out

        if startTime == 0 then
            resetTimer()
        end

        -- loop through the range_and_bearing table to determine if there are
        -- messages that need to be followed
        for _, entry in ipairs(robot.range_and_bearing) do
            if entry.data[1] == 1 then
                home_found = true
            end
            if entry.data[2] == 1 then
                resource_found = true
            end
        end

        if home_found and resource_found then
            My_state = "connect_to_beacon"
            return
        elseif home_found and not found_resource then
            found_home = true
            My_state = "find_resource"
            return
        elseif resource_found and not found_home then
            found_resource = true
            My_state = "find_home"
            return
        else
            log(robot.id .. " claims: resource/home not found")
            found_home = false
            found_resource = false

            for _, value in ipairs(robot.colored_blob_omnidirectional_camera) do
                if (255 == value.color.green) or (255 == value.color.blue) then
                    blobDetectionCount = blobDetectionCount + 1
                end
            end

            if blobDetectionCount >= requiredDetectionCount then
                My_state = "approach"
                resetTimer()
                return
            end
        end

        if os.time() - startTime >= timeout then
            My_state = "explore"
            resetTimer()
        end
    end,

    find_home = function()
        MY_design = "none"
        local target_blob = {}
        local target_rnb = {}

        -- loop through colored blob data
        -- if the value is 255 then assign the value table to the
        for _, value in ipairs(robot.colored_blob_omnidirectional_camera) do
            if (255 == value.color.green) then
                target_blob = value
                break
            end
        end

        for _, entry in ipairs(robot.range_and_bearing) do
            if (entry.data[1] == 0) or (entry.data[1] == 1) then
                target_rnb = entry
                break
            end
        end

        motion.random_walk()

        if next(target_rnb) and next(target_blob) and
            (target_rnb.data[1] == 0 or target_rnb.data[1] == 1) and
            (255 == target_blob.color.green) then
            blobDetectionCount = blobDetectionCount + 1
        end

        if blobDetectionCount >= requiredDetectionCount then
            My_state = "inspect"
            resetTimer()
            return
        end
    end,

    find_resource = function()
        MY_design = "none"
        local target_blob = {}
        local target_rnb = {}

        for _, value in ipairs(robot.colored_blob_omnidirectional_camera) do
            if (255 == value.color.blue) then
                target_blob = value
                log("Found blue blob: " .. robot.id)
                break
            end
        end

        for _, entry in ipairs(robot.range_and_bearing) do
            if (entry.data[2] == 0) or (entry.data[2] == 1) then
                target_rnb = entry
                break
            end
        end

        motion.random_walk()

        if next(target_rnb) and next(target_blob) and
            (target_rnb.data[2] == 0 or target_rnb.data[2] == 1) and
            (255 == target_blob.color.blue) then
            blobDetectionCount = blobDetectionCount + 1
        end

        if blobDetectionCount >= requiredDetectionCount then
            My_state = "inspect"
            resetTimer()
            return
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
        local proximityMinCount = 1
        local proximityDistance = 17.5
        local targetLost = (#robot.range_and_bearing == 0)

        if startTime == 0 then
            resetTimer()
        end

        local target_blob = {}
        local target_rnb = {}

        motion.Speed_from_force(motion.rnb_force())

        if motion.rnb_force() == { x = 0, y = 0 } then
            My_state = "inspect"
            return
        end

        for _, value in ipairs(robot.colored_blob_omnidirectional_camera) do
            if ((250 == value.color.green and 100 == value.color.red)
                    or (50 == value.color.blue and 250 == value.color.red)) then
                target_blob = value
                break
            end
        end

        for _, entry in ipairs(robot.range_and_bearing) do
            if (entry.data[1] == 1) or (entry.data[2] == 1) then
                target_rnb = entry
                break
            end
        end

        local proximityCount = 0
        for i = 1, 24 do
            proximityCount = proximityCount + robot.proximity[i].value
        end

        log("Proximity Count: " .. proximityCount)

        if proximityCount >= proximityMinCount and next(target_rnb) then
            local distance = target_rnb.range
            log("Proximity activation ongoing. Distance: " .. distance)

            if distance <= proximityDistance then
                log("Proximity activation sustained within " .. proximityDistance .. " meters")
                My_state = "halt"
                robot.gripper.lock_positive()
                robot.turret.set_passive_mode()
                log("Locked & Loaded!")
                My_state = "beacon"
                robot.range_and_bearing.set_data(5, 1)
                return
            end
        else
            log(robot.id .. " Proximity activation not sustained")
            -- motion.random_walk()
        end

        if not targetLost then
            log(robot.id .. " lost the target")
        end

        if os.time() - startTime >= timeout and targetLost then
            log(robot.id .. " timeout")
            My_state = "explore"
            resetTimer()
        end
    end,

    link = function()
        MY_design = "none"
        motion.Drive_as_car(0, 0)
        robot.range_and_bearing.set_data(zero_data)
        robot.range_and_bearing.set_data(5, 2)
        log(robot.id .. " I am a link")
    end,

    beacon = function()
        motion.Drive_as_car(0, 0)
        robot.range_and_bearing.set_data(zero_data)

        local is_home_beacon = false
        local is_resource_beacon = false

        -- Determine what kind of beacon the bot is supposed to be
        for _, value in ipairs(robot.colored_blob_omnidirectional_camera) do
            if (255 == value.color.green) or (250 == value.color.green and 100 == value.color.red) then
                robot.range_and_bearing.set_data(1, 1)
                is_home_beacon = true
                found_home = true
                MY_design = "home_beacon"
            elseif (255 == value.color.blue) or (50 == value.color.blue and 250 == value.color.red) then
                robot.range_and_bearing.set_data(2, 1)
                is_resource_beacon = true
                found_resource = true
                MY_design = "resource_beacon"
            end
        end

        -- Check if the robot should become a link
        for _, entry in ipairs(robot.range_and_bearing) do
            if entry and entry.data[5] == 1 then
                My_state = "link"
                return
            end
        end

        -- Failsafe to handle multiple beacons of the same design
        if not is_home_beacon and not is_resource_beacon then
            for _, entry in ipairs(robot.range_and_bearing) do
                if entry.data[1] == 1 and entry.range < 20 then
                    log(robot.id .. " returning to explore (home beacon conflict)")
                    My_state = "explore"
                    return
                elseif entry.data[2] == 1 and entry.range < 20 then
                    log(robot.id .. " returning to explore (resource beacon conflict)")
                    My_state = "explore"
                    return
                end
            end
        end
        --
        -- Maintain the robot's position as a beacon
        -- Add code here to keep the robot in place or move slightly to maintain its role as a beacon
        -- motion.straighten()
    end,

    halt = function()
        local halt_timeout = 4
        -- reset approaching message
        robot.range_and_bearing.set_data(zero_data)
        -- Check if start time is zero, if so, initialize it
        if startTime == 0 then
            resetTimer()
        end

        motion.Drive_as_car(0, 0)
        if os.time() - startTime >= halt_timeout then
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
