local function drop_armor(player)
    local armor_enabled = core.global_exists("armor")
    if not armor_enabled then
        return
    end

    local name, armor_inv = armor:get_valid_player(player, "[on_dieplayer]")
    if not name or not armor_inv then
        return
    end

    for i=1, armor_inv:get_size("armor") do
        local stack = armor_inv:get_stack("armor", i)
        if stack:get_count() > 0 then
            local pos = player:get_pos()
            pos = vector.new(pos.x + math.random(-0.2, 0.2), pos.y + 0.5, pos.z + math.random(-0.2, 0.2))
            core.add_item(pos, stack)
        end

        armor_inv:set_stack("armor", i, nil)
    end

    armor:save_armor_inventory(player)
    armor:set_player_armor(player)
end

core.register_on_dieplayer(function(player, reason)
    if ffa.get_player_in_list(player) then
        drop_armor(player)
        minigame.drop_inventory(player)
        ffa.serialize_inventory(player)
    end
end)

core.register_on_respawnplayer(function(player)
    if ffa.get_player_in_list(player) then
        ffa.to_random_spawn(player)
    end
end)

core.register_on_leaveplayer(function(player, timed_out)
    ffa.on_leave(player)
end)

local function is_liquid_node(node_name)
    local nodedef = core.registered_nodes[node_name]
    return nodedef.drawtype == "liquid" or nodedef.drawtype == "flowingliquid"
end

core.register_on_placenode(function(pos, newnode, placer, oldnode, itemstack, pointed_thing)
    if not ffa.get_player_in_list(placer) or core.get_player_privs(placer:get_player_name()).protection_bypass then
        return
    end
    for _, node in ipairs(ffa.nodes) do
        if newnode.name == node and not is_liquid_node(oldnode.name) and oldnode.name ~= "fire:permanent_flame" then
            return false
        end
    end

    core.set_node(pos, oldnode)

    return true
end)

core.register_on_dignode(function(pos, oldnode, digger)
    if not ffa.get_player_in_list(digger) or core.get_player_privs(digger:get_player_name()).protection_bypass then
        return
    end

    for _, node in ipairs(ffa.nodes) do
        if oldnode.name == node then
            return false
        end
    end

    local nodedef = core.registered_nodes[oldnode.name]
    if nodedef then
        local node_drop = nodedef.drop
        local inv = digger:get_inventory()
        if type(node_drop) == "string" then
            inv:remove_item("main", node_drop .. " 1")
        else
            inv:remove_item("main", oldnode.name .. " 1")
        end
    end

    core.set_node(pos, oldnode)

    return true
end)

core.register_on_player_inventory_action(function(player, action, inventory, inventory_info)
    if ffa.get_player_in_list(player) then ffa.serialize_inventory(player) end
end)

core.register_on_item_pickup(function(itemstack, picker, pointed_thing, time_from_last_punch)
    if ffa.get_player_in_list(picker) then ffa.serialize_inventory(picker) end
end)

local function is_player_outside(player)
    local player_pos = player:get_pos()
    local map_pos1, map_pos2 = ffa.map.pos1, ffa.map.pos2

    if map_pos1 and map_pos2 then
        if player_pos.x < math.min(map_pos1.x, map_pos2.x) or player_pos.x > math.max(map_pos1.x, map_pos2.x) or
            player_pos.y < math.min(map_pos1.y, map_pos2.y) or player_pos.y > math.max(map_pos1.y, map_pos2.y) or
            player_pos.z < math.min(map_pos1.z, map_pos2.z) or player_pos.z > math.max(map_pos1.z, map_pos2.z) then
            return true
        end
    end

    return false
end

local function map_disabled()
    return ffa.map.disabled
end

local function is_manager(player)
    return core.get_player_privs(player:get_player_name()).ffa_manager
end

core.register_on_shutdown(function()
    for _, name in ipairs(ffa.get_names()) do
        ffa.serialize_inventory(core.get_player_by_name(name))
    end
end)

local timer
core.register_globalstep(function(dtime)
    if not ffa.module_loaded() then
        return
    end

    timer = (timer or 0) + dtime

    if timer > 1 then
        timer = 0

        for _, name in ipairs(ffa.get_names()) do
            local player = core.get_player_by_name(name)
            local is_outside =  is_player_outside(player)

            if is_outside then
                ffa.to_random_spawn(player)
            end

            if map_disabled() then
                ffa.on_leave(player)
                core.chat_send_player(name, core.colorize("orange", "The map is currently disabled!"))
            end
        end

        if not map_disabled() then
            for _, player in ipairs(core.get_connected_players()) do
                if is_manager(player) then return end
                local is_outside = is_player_outside(player)
                if not is_outside and not ffa.get_player_in_list(player) then
                    ffa.on_enter(player)
                end
            end
        end
    end
end)