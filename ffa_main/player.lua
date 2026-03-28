local inv_name = "ffa_main:inventory"
local modstorage = core.get_mod_storage()

local function save_inventory(player, serialized_data)
    return player:get_meta():set_string(inv_name, serialized_data)
end

local function serialize_inventory(player)
    local checked_lists = {"main", "craft"}
    local inv = player:get_inventory()
    local data = {}

    for _, list_name in pairs(checked_lists) do
        local list = inv:get_list(list_name)
        if list then
            data[list_name] = {}
            for _, item in ipairs(list) do
                --inv:remove_item(list_name, item)
                table.insert(data[list_name], item:to_string())
            end
        end
    end

    save_inventory(player, core.serialize(data))
end

local function get_saved_inventory(player)
    return core.deserialize(player:get_meta():get_string(inv_name))
end

local function restore_inventory(player)
    local data = get_saved_inventory(player)
    local inv = player:get_inventory()

    if data == nil then return end

    for list_name, v in pairs(data) do
        local list = inv:get_list(list_name)
        if list then
            for i, item in ipairs(v) do
                inv:set_stack(list_name, i, item)
            end
        end
    end
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

local function to_random_spawn(player)
    local id = math.random(1, #(ffa.map.spawns or 1))
    local pos = ffa.map.spawns[id]
    if pos then
        player:set_pos(pos)
    end
end

local minigame_available = core.global_exists("minigame")

function ffa.on_enter(player)
    local name = player:get_player_name()

    if ffa.disabled == true then
        core.chat_send_player(name, core.colorize("orange", "The map is currently disabled!"))
        return
    end

    if minigame_available and minigame.get_player_entry(player) ~= nil then
        core.chat_send_player(name, "You are not allowed to join FFA while being in another minigame. Try /quit")
        return
    end

    if get_player_in_list(player) then
        core.chat_send_player(name, "You are already in FFA...")
        return
    end

    restore_inventory(player)
    insert_player(player)
    to_random_spawn(player)
    send_system_message("*** " .. player:get_player_name() .. " entered FFA.")
end

function ffa.on_leave(player)
    if not get_player_in_list(player) then return end
    serialize_inventory(player)
    remove_player(player)
    skylith.try_tp_to_spawn(player)
    skylith.reset_inventories(player)
    send_system_message("*** " .. player:get_player_name() .. " left FFA.")
end

core.register_on_player_inventory_action(function(player, action, inventory, inventory_info)
    if not get_player_in_list(player) then return end
    serialize_inventory(player)
end)

core.register_on_item_pickup(function(itemstack, picker, pointed_thing, time_from_last_punch)
    if not get_player_in_list(picker) then return end
    serialize_inventory(picker)
end)

core.register_on_leaveplayer(function(player, timed_out)
    ffa.on_leave(player)
end)

local nodes = {
    "wool:red",
    "wool:blue"
}

core.register_on_dignode(function(pos, oldnode, digger)
    if not get_player_in_list(digger) or core.get_player_privs(digger:get_player_name()).protection_bypass then
        return
    end
    for _, node in ipairs(nodes) do
        if oldnode.name == node then
            return true
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
end)

core.register_on_placenode(function(pos, newnode, placer, oldnode, itemstack, pointed_thing)
    if not get_player_in_list(placer) or core.get_player_privs(placer:get_player_name()).protection_bypass then
        return
    end
    for _, node in ipairs(nodes) do
        if newnode.name == node and oldnode.name ~= "default:water_source" then
            return true
        end
    end
    core.set_node(pos, oldnode)
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

--[[
local old_is_protected = core.is_protected
function core.is_protected(pos, name)
    local player = core.get_player_by_name(name)
	if get_player_in_list(player) and is_player_outside(player) then
		return true
	end
	return old_is_protected(pos, name)
end
]]

local timer
core.register_globalstep(function(dtime)
    timer = (timer or 0) + dtime
    if timer > 1 then
        timer = 0

        for _, name in ipairs(ffa.get_players()) do
            local player = core.get_player_by_name(name)
            local is_outside =  is_player_outside(player)

            if is_outside then
                to_random_spawn(player)
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