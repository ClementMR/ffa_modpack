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

local function insert_player(player)
    local names = ffa.get_names()
    table.insert(names, player:get_player_name())
    modstorage:set_string("ffa:players", core.serialize(names))
end

local function send_system_message(message)
    for _, name in ipairs(ffa.get_names()) do
        core.chat_send_player(name, message)
    end
end

function ffa.module_loaded()
    return next(ffa.map.pos1) and next(ffa.map.pos2) and next(ffa.map.spawns)
end

function ffa.to_random_spawn(player)
    local id = math.random(1, #(ffa.map.spawns or 1))
    local pos = ffa.map.spawns[id]
    if pos then
        player:set_pos(pos)
    end
end

function ffa.get_names()
    return core.deserialize(modstorage:get_string("ffa:players")) or {}
end

function ffa.get_player_in_list(player)
    for _, name in ipairs(ffa.get_names()) do
        if player:get_player_name() == name then
            return true
        end
    end

    return false
end

function ffa.remove_player(player)
    local names = ffa.get_names()

    for i, name in ipairs(names) do
        if player:get_player_name() == name then
            table.remove(names, i)
            --break
        end
    end

    modstorage:set_string("ffa:players", core.serialize(names))
end

function ffa.serialize_inventory(player)
    local data = serialize_player_inventory(player)

    local armor_data = serialize_player_armor(player)
    if armor_data then
        data.armor = armor_data
    end

    save_inventory(player, core.serialize(data))
end

function ffa.restore_inventory(player)
    local data = get_saved_inventory(player)
    if not data then
        return
    end

    restore_player_inventory(player, data)
    restore_player_armor(player, data.armor)
end

function ffa.on_enter(player)
    local name = player:get_player_name()

    if not ffa.module_loaded() then
        core.chat_send_player(name, "FFA isn't set up!")
        return
    end

    if ffa.map.disabled then
        core.chat_send_player(name, "The map is currently disabled!")
        return
    end

    if ffa.get_player_in_list(player) then
        core.chat_send_player(name, "You are already in FFA...")
        return
    end

    insert_player(player)
    send_system_message("*** " .. player:get_player_name() .. " entered FFA.")

    ffa.restore_inventory(player)
    ffa.to_random_spawn(player)
end

function ffa.on_leave(player)
    if not ffa.get_player_in_list(player) then
        return
    end

    ffa.serialize_inventory(player)

    ffa.remove_player(player)
    send_system_message("*** " .. player:get_player_name() .. " left FFA.")

    skylith.try_tp_to_spawn(player)
    skylith.reset_inventories(player)
end