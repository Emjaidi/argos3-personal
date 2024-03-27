-- state.lua 
--
--

local motion = require("motion")

local Design = require("design")
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

        --end driving

        -- TODO when a resource is found (specific LED)
        -- the State changes to form a path to the resource
        -- the bot can transmit a message or
        -- change the design of its LEDs to point to the resource
        if (#robot.colored_blob_omnidirectional_camera > 0) then
            if (255 == robot.colored_blob_omnidirectional_camera[1].color.blue) then
                if (nil == robot.range_and_bearing) then
                    My_state = "explore"
                else
                    My_state = "approach"
                end
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
        motion.Drive_as_car(0, 0)
        log("Found a POI")
        robot.range_and_bearing.set_data(1, 255)
        MY_design = "home_beacon"
    end,

    halt = function()
        motion.Drive_as_car(0, 0)
        --LED_Design()
    end,

    approach = function()
        -- Approaches the LED
        -- TODO approach only if the LED is a resource/
        -- TODO use the robot.light function  to approach the head footbot
        motion.Speed_from_force(motion.Camera_force(true, true))

        -- loop through all of range_and_bearing data table and 
        for i = 1, #robot.range_and_bearing do
            local entry = robot.range_and_bearing[i]
            if entry and entry.data and entry.data[1] == 255 then
                My_state = "explore"
            end
        end

        if robot.proximity[1].value == 1 then
            My_state = "halt"
            robot.gripper.lock_negative()
            robot.turret.set_passive_mode()
            log("Locked & Loaded!")
            My_state = "beacon"
        end

        if (0 == #robot.colored_blob_omnidirectional_camera)
            and (255 == robot.range_and_bearing[1].data[1]) then
            My_state = "explore"
        end
    end,

    deliver = function()
        log("Delivering!")
        motion.Speed_from_force(motion.Proximity_avoidance_force())
        MY_design = "none"
        Design[MY_design]()
        --LED_Design()
    end,

}

return State
