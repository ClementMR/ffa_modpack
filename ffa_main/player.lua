local modstorage = core.get_mod_storage()

local function save_inventory(player, serialized_data)
    return player:get_meta():set_string("ffa_main:inventory", serialized_data)
end

local function get_saved_inventory(player)
    return core.deserialize(player:get_meta():get_string("ffa_main:inventory"))
end

local function serialize_player_inventory(player)
    local checked_lists = {"main", "craft"}
    local inv = player:get_inventory()
    local data = {}

    for _, list_name in ipairs(checked_lists) do
        local list = inv:get_list(list_name)
        if list then
            data[list_name] = {}

            for _, item in ipairs(list) do
                table.insert(data[list_name], item:to_string())
            end
        end
    end

    return data
end

local function serialize_player_armor(player)
    if not core.global_exists("armor") then
        return nil
    end

    local _, armor_inv = armor:get_valid_player(player, "[save_armor_inventory]")
    if not armor_inv then
        return nil
    end

    local list = armor_inv:get_list("armor")
    if not list then
        return nil
    end

    local armor_data = {}
    for _, item in ipairs(list) do
        table.insert(armor_data, item:to_string())
    end

    return armor_data
end

local function serialize_inventory(player)
    local data = serialize_player_inventory(player)

    local armor_data = serialize_player_armor(player)
    if armor_data then
        data.armor = armor_data
    end

    save_inventory(player, core.serialize(data))
end

local function restore_player_inventory(player, data)
    local inv = player:get_inventory()
    for list_name, list_data in pairs(data) do
        if list_name ~= "armor" then
            if inv:get_list(list_name) then
                for i, item in ipairs(list_data) do
                    inv:set_stack(list_name, i, item)
                end
            end
        end
    end
end

local function restore_player_armor(player, armor_data)
    if not core.global_exists("armor") then
        return
    end

    if not armor_data then
        return
    end

    local _, armor_inv = armor:get_valid_player(player, "[restore_armor]")
    if not armor_inv then
        return
    end

    local list = {}
    for i, item in ipairs(armor_data) do
        list[i] = ItemStack(item)
    end

    armor_inv:set_list("armor", list)
    armor:set_player_armor(player)
end

local function restore_inventory(player)
    local data = get_saved_inventory(player)
    if not data then
        return
    end

    restore_player_inventory(player, data)
    restore_player_armor(player, data.armor)
end

local function get_player_in_list(player)
    for _, name in ipairs(ffa.get_players()) do
        if player:get_player_name() == name then
            return true
        end
    end

    return false
end

local function insert_player(player)
    local players = ffa.get_players()
    local name = player:get_player_name()
    table.insert(players, name)
    modstorage:set_string("ffa:players", core.serialize(players))
end

local function remove_player(player)
    local players = ffa.get_players()
    local name = player:get_player_name()

    for k, v in ipairs(players) do
        if v == name then
            table.remove(players, k)
            --break
        end
    end

    modstorage:set_string("ffa:players", core.serialize(players))
end

function ffa.get_players()
    return core.deserialize(modstorage:get_string("ffa:players")) or {}
end

local function send_system_message(message)
    for _, name in ipairs(ffa.get_players()) do
        core.chat_send_player(name, message)
    end
end

function ffa.to_random_spawn(player)
    local id = math.random(1, #(ffa.map.spawns or 1))
    local pos = ffa.map.spawns[id]
    if pos then
        player:set_pos(pos)
    end
end

function ffa.on_enter(player)
    local name = player:get_player_name()

    if ffa.disabled == true then
        core.chat_send_player(name, core.colorize("orange", "The map is currently disabled!"))
        return
    end

    if minigame.get_player_entry(player) ~= nil then
        core.chat_send_player(name, "You are not allowed to join FFA while being in another minigame. Try /quit")
        return
    end

    if get_player_in_list(player) then
        core.chat_send_player(name, "You are already in FFA...")
        return
    end

    restore_inventory(player)
    insert_player(player)
    ffa.to_random_spawn(player)
    send_system_message("*** " .. player:get_player_name() .. " entered FFA.")
end

function ffa.on_leave(player)
    if not get_player_in_list(player) then
        return
    end
    serialize_inventory(player)
    remove_player(player)
    skylith.try_tp_to_spawn(player)
    skylith.reset_inventories(player)
    send_system_message("*** " .. player:get_player_name() .. " left FFA.")
end

core.register_on_player_inventory_action(function(player, action, inventory, inventory_info)
    if get_player_in_list(player) then
        serialize_inventory(player)
    end
end)

core.register_on_item_pickup(function(itemstack, picker, pointed_thing, time_from_last_punch)
    if get_player_in_list(picker) then
        serialize_inventory(picker)
    end
end)

core.register_on_leaveplayer(function(player, timed_out)
    ffa.on_leave(player)
end)

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
    if get_player_in_list(player) then
        drop_armor(player)
        minigame.drop_inventory(player)
        serialize_inventory(player)
    end
end)

core.register_on_respawnplayer(function(player)
    if get_player_in_list(player) then
        remove_player(player)
        skylith.try_tp_to_spawn(player)
    end
end)

local function is_liquid_node(node_name)
    local nodedef = core.registered_nodes[node_name]
    return nodedef.drawtype == "liquid" or nodedef.drawtype == "flowingliquid"
end

core.register_on_placenode(function(pos, newnode, placer, oldnode, itemstack, pointed_thing)
    if not get_player_in_list(placer) or core.get_player_privs(placer:get_player_name()).protection_bypass then
        return
    end
    for _, node in ipairs(ffa.nodes) do
        if newnode.name == node and not is_liquid_node(oldnode.name) then
            return false
        end
    end

    core.set_node(pos, oldnode)

    return true
end)

core.register_on_dignode(function(pos, oldnode, digger)
    if not get_player_in_list(digger) or core.get_player_privs(digger:get_player_name()).protection_bypass then
        return
    end
    for _, node in ipairs(ffa.nodes) do
        if oldnode.name == node then
            return false
        end
    end

    local node_drop = core.registered_nodes[oldnode.name].drop
    local inv = digger:get_inventory()
    if type(node_drop) == "string" then
        inv:remove_item("main", node_drop .. " 1")
    else
        inv:remove_item("main", oldnode.name .. " 1")
    end

    core.set_node(pos, oldnode)

    return true
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

local timer
core.register_globalstep(function(dtime)
    timer = (timer or 0) + dtime
    if timer > 1 then
        timer = 0

        for _, name in ipairs(ffa.get_players()) do
            local player = core.get_player_by_name(name)
            local is_outside =  is_player_outside(player)

            if is_outside then
                ffa.to_random_spawn(player)(player)
            end

            if ffa.disabled == true then
                ffa.on_leave(player)
                core.chat_send_player(name, core.colorize("orange", "The map is currently disabled!"))
            end
        end

        if not ffa.disabled and ffa.map.pos1 ~= nil and ffa.map.pos2 then
            for _, player in ipairs(core.get_connected_players()) do
                local is_outside = is_player_outside(player)
                if is_outside == false and not get_player_in_list(player) then
                    ffa.on_enter(player)
                end
            end
        end
    end
end)

core.register_on_mods_loaded(function()
    modstorage:set_string("ffa:players", "")
end)