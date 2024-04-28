-- utilities.lue
--
--

local util = {}

function util.get_beacon_rnb(arg)
    local target_rnb
    if arg == "p" then
        for _, entry in ipairs(robot.range_and_bearing) do
            if entry and (entry.data[1] == 1) then
                target_rnb = entry
                break
            end
        end
    else
        for _, entry in ipairs(robot.range_and_bearing) do
            if entry and ((entry.data[1] == 1) or (entry.data[2] == 1)) then
                target_rnb = entry
                break
            end
        end
    end
    return target_rnb
end

function util.determine_beacon()
    local beacon_type
    for _, value in ipairs(robot.colored_blob_omnidirectional_camera) do
        if (255 == value.color.green) or (250 == value.color.green and 100 == value.color.red) then
            robot.range_and_bearing.set_data(1, 1)
            beacon_type = "beacon"
        elseif (255 == value.color.blue) or (50 == value.color.blue and 250 == value.color.red) then
            robot.range_and_bearing.set_data(2, 1)
            beacon_type = "beacon"
        end
    end

    return beacon_type
end

function util.check_multi_beacon()
    for _, entry in ipairs(robot.range_and_bearing) do
        local min_dis = 26
        local distance = entry.range

        if entry.data[1] == 1 and distance < min_dis then
            log(robot.id .. " returning to explore (home beacon conflict)")
            My_state = "inspect"
            return
        end

        if entry.data[2] == 1 and distance < min_dis then
            log(robot.id .. " returning to explore (resource beacon conflict)")
            My_state = "inspect"
            return
        end
    end
end

return util
