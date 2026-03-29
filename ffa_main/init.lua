local modstorage = core.get_mod_storage()

ffa = {
    map = core.deserialize(modstorage:get_string("ffa:map")) or {pos1={},pos2={},spawns={},disabled=true},
    nodes = {}
}

local files = {
    "map",
    "player",
    "callbacks",
    "cleanup",
    "chatcommands"
}

for _, f in ipairs(files) do
    dofile(core.get_modpath(core.get_current_modname()) .. "/" .. f .. ".lua")
end

modstorage:set_string("ffa:players", "")