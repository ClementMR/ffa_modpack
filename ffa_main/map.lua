local modstorage = core.get_mod_storage()

core.register_privilege("ffa_manager", {
    description = "Allows the player to manage FFA",
    give_to_singleplayer = false,
    give_to_admin = false,
})

local function get_spawns()
    return ffa.map.spawns
end

local function list_spawns()
    local str = ""
    for id, pos in ipairs(get_spawns()) do
        str = str .. "[" .. id .. "] " .. core.pos_to_string(pos) .. "\n"
    end

    return str
end

local function remove_spawn(id)
    for k, _ in ipairs(get_spawns()) do
        if k == id then
            table.remove(ffa.map.spawns, k)
        end
    end
end

core.register_chatcommand("ffa_map", {
    params = "spawn add | spawn remove <id> | spawn list | pos1 | pos2 | toggle <enable|disable|1|0> | save | print",
    privs = {ffa_manager=true},
    func = function(name, param)
        local player = core.get_player_by_name(name)
        if not player then
            return false, "You must be online to use this command."
        end

        local safe_pos = vector.round(player:get_pos())
        local params = param:split(" ")

        if params[1] == "spawn" then
            if params[2] == "add" then
                table.insert(ffa.map.spawns, safe_pos)
                return true, "Spawn added at " .. core.pos_to_string(safe_pos)
            elseif params[2] == "remove" then
                local id = tonumber(params[3])
                if id then
                    remove_spawn(id)
                    return true, "Spawn n°" .. id .. " removed!"
                end
            elseif params[2] == "list" then
                return true, list_spawns()
            end

        elseif params[1] == "pos1" then
            ffa.map.pos1 = safe_pos
            return true, "Position (1) set at " .. core.pos_to_string(safe_pos)

        elseif params[1] == "pos2" then
            ffa.map.pos2 = safe_pos
            return true, "Position (2) set at " .. core.pos_to_string(safe_pos)

        elseif params[1] == "toggle" then
            if params[2] == "disable" or params[2] == "0" then
                ffa.map.disabled = true
                return true, "Map disabled."
            elseif params[2] == "enable" or params[2] == "1" then
                ffa.map.disabled = false
                return true, "Map enabled."
            end

        elseif params[1] == "save" then
            modstorage:set_string("ffa:map", core.serialize(ffa.map))
            return true, "Map saved."

        elseif params[1] == "print" then
            return true, dump(ffa.map)
        end

        return false, "Invalid parameters : " .. param
    end
})