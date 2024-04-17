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

return util
