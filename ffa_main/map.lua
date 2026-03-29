local modstorage = core.get_mod_storage()

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

core.register_chatcommand("ffa_spawn", {
    params = "add | remove <id>",
    privs = {server=true},
    func = function(name, param)
        local player = core.get_player_by_name(name)
        local params = param:split(" ")

        if not ffa.map.spawns then
            ffa.map.spawns = {}
        end

        if params[1] == "add" then
            local pos =  vector.round(player:get_pos())
            table.insert(ffa.map.spawns, pos)
            return true, "Spawn added ! " .. core.pos_to_string(pos)
        elseif params[1] == "remove" then
            local id = tonumber(params[2])
            if id ~= nil then
                remove_spawn(id)
                return true, "Spawn n°" .. id .. " removed!"
            end
        end

        return true, list_spawns()
    end
})

core.register_chatcommand("ffa_pos1", {
    params = "set",
    privs = {server=true},
    func = function(name, param)
        if param == "set" then
            local player = core.get_player_by_name(name)
            local pos =  vector.round(player:get_pos())
            ffa.map.pos1 = pos
            return true, "Position set ! " .. core.pos_to_string(pos)
        end

        return true, "Current pos1 " .. core.pos_to_string(ffa.map.pos1)
    end
})

core.register_chatcommand("ffa_pos2", {
    params = "set",
    privs = {server=true},
    func = function(name, param)
        if param == "set" then
            local player = core.get_player_by_name(name)
            local pos =  vector.round(player:get_pos())
            ffa.map.pos2 = pos
            return true, "Position set ! " .. core.pos_to_string(pos)
        end

        return true, "Current pos2 " .. core.pos_to_string(ffa.map.pos2)
    end
})

core.register_chatcommand("ffa_save", {
    privs = {server=true},
    func = function(name, param)
        modstorage:set_string("ffa:map", core.serialize(ffa.map))
        ffa.map = core.deserialize(modstorage:get_string("ffa:map"))
        return true, "Map saved!"
    end
})

core.register_chatcommand("ffa_data", {
    privs = {server=true},
    func = function(name, param)
        return true, dump(ffa.map)
    end
})

core.register_chatcommand("ffa_toggle", {
    params = "enable | disable",
    privs = {server=true},
    func = function(name, param)
        if param == "disable" then
            ffa.disabled = true
            return true, "Map disabled until next restart..."
        end

        ffa.disabled = false
        return true, "Map enabled..."
    end
})

ffa.map = core.deserialize(modstorage:get_string("ffa:map")) or {}