ffa = {
    map = {
        spawns = {},
        pos1 = {},
        pos2 = {}
    },
    disabled = false,
    nodes = {}
}

local files = {
    "map",
    "player",
    "chatcommands"
}

local modpath = core.get_modpath(core.get_current_modname())

for _, f in ipairs(files) do
    dofile(modpath .. "/" .. f .. ".lua")
end