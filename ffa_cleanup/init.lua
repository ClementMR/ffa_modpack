if not ffa.map.pos1 and not ffa.map.pos2 then
    return
end

local pos1 = ffa.map.pos1
local pos2 = ffa.map.pos2
local nodes = ffa.nodes

local INTERVAL = 1800
local WARN = 30
local STEP = 16

local function sort_pos(a, b)
    return {
        x = math.min(a.x, b.x),
        y = math.min(a.y, b.y),
        z = math.min(a.z, b.z),
    },
    {
        x = math.max(a.x, b.x),
        y = math.max(a.y, b.y),
        z = math.max(a.z, b.z),
    }
end

local minp, maxp = sort_pos(pos1, pos2)

local function clean_area()
    core.log("action", "[Cleaner] Begin cleanup!")

    for x = minp.x, maxp.x, STEP do
        for y = minp.y, maxp.y, STEP do
            for z = minp.z, maxp.z, STEP do

                local block_min = {x = x, y = y, z = z}
                local block_max = {
                    x = math.min(x + STEP - 1, maxp.x),
                    y = math.min(y + STEP - 1, maxp.y),
                    z = math.min(z + STEP - 1, maxp.z),
                }

                -- Charge la zone si nécessaire
                core.emerge_area(block_min, block_max)

                -- Trouve les nodes ciblés
                for _, nodename in pairs(nodes) do
                    local positions = core.find_nodes_in_area(block_min, block_max, nodename)
                    for _, pos in ipairs(positions) do
                        core.set_node(pos, {name = "air"})
                    end
                end

            end
        end
    end

    core.log("action", "[Cleaner] Cleanup done!")
end

local function notify_players(message)
    for _, name in ipairs(ffa.get_players()) do
        local player = core.get_player_by_name(name)
        hud_api.show_front(player, message, "0xFF0000")
        core.after(2, hud_api.remove, player, "front")
    end
end

local timer = 0
local function update()
    timer = timer + 1

    if (INTERVAL - timer) == WARN then
        notify_players(("Cleaning the area in %ds"):format(WARN))
    end

    if timer >= INTERVAL then
        timer = 0
        for _, name in ipairs(ffa.get_players()) do
            local player = core.get_player_by_name(name)
            ffa.to_random_spawn(player)
        end

        notify_players("Cleanup ...")
        clean_area()
    end

    core.after(1, update)
end

core.after(1, update)