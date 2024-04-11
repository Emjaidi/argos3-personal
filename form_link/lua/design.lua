-- design.lua
--
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
        robot.leds.set_all_colors("100,250,0, 255")
    end,

    resource_beacon = function()
        robot.leds.set_all_colors("250, 0, 50, 255")
    end
}

return Design
