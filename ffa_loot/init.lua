local loot_table = {
    {name = "wool:white", chance = 0.9, max = 16},
    {name = "wool:blue", chance = 0.9, max = 16},
    {name = "default:apple", chance = 0.5, max = 6},
    {name = "default:sword_steel", chance = 0.2, max = 1},
    {name = "fire:flint_and_steel", chance = 0.2,  max = 1},
    {name = "3d_armor:helmet_steel", chance = 0.2, max = 1},
    {name = "3d_armor:chestplate_steel", chance = 0.1, max = 1},
    {name = "3d_armor:leggings_steel", chance = 0.1, max = 1},
    {name = "3d_armor:boots_steel", chance = 0.2, max = 1},
    {name = "shields:shield_steel", chance = 0.2, max = 1},
    {name = "xdecor:cobweb", chance = 0.2, max = 8},
    {name = "ffa_loot:golden_key", chance = 0.01, max = 3},
    --{name = "tnt:tnt", chance = 0.05, max = 3}
}

local golden_loot_table = {
    {name = "wool:white", chance = 0.9, max = 16},
    {name = "wool:blue", chance = 0.9, max = 16},
	{name = "default:sword_diamond", chance = 0.3, max = 1},
	{name = "farming:bread", chance = 0.5, max = 4},
	{name = "default:blueberries", chance = 0.5, max = 6},
	{name = "ms_arena:shotgun", chance = 0.2, max = 1},
	{name = "3d_armor:helmet_diamond", chance = 0.1, max = 1},
	{name = "3d_armor:chestplate_diamond", chance = 0.05, max = 1},
	{name = "3d_armor:leggings_diamond", chance = 0.05, max = 1},
	{name = "3d_armor:boots_diamond", chance = 0.1, max = 1},
	{name = "shields:shield_diamond", chance = 0.1, max = 1},
    --{name = "tnt:tnt", chance = 0.2, max = 3}
}

local REGULAR_CHEST = 60
local MESE_CHEST = 10

local function fill_chest_random(pos, loot)
    local meta = core.get_meta(pos)
    local inv = meta:get_inventory()
    local size = inv:get_size("main")
    inv:set_list("main", {})

    for i=1, math.floor(size/16) do
        for _, item in ipairs(loot) do
            local r = math.random()
            if r <= item.chance then
                local slot = math.random(1, size)
                local amount = math.random(1, item.max or 99)
                inv:set_stack("main", slot, ItemStack(item.name .. " " .. amount))
            end
        end
    end
end

local function construct_node(pos, infotext)
    local meta = core.get_meta(pos)
    meta:set_string("infotext", infotext)
    local inv = meta:get_inventory()
    inv:set_size("main", 8*4)
    core.get_node_timer(pos):start(1)
end

local function can_dig_node(pos)
    local meta = core.get_meta(pos)
    local inv = meta:get_inventory()
    --[[
    for _, stack in ipairs(inv:get_list("main")) do
        local p = vector.new(pos.x + math.random(-0.2, 0.2), pos.y + 0.5, pos.z + math.random(-0.2, 0.2))
        inv:remove_item("main", stack)
        core.add_item(p, stack)
    end
    ]]

    return inv:is_empty("main")
end

--
--- REGULAR CHEST
--

local function update_node(pos, refill_time, loot)
    local meta = core.get_meta(pos)
    local timer = meta:get_int("timer")
    local time_left = (refill_time - timer)
    local infotext = meta:get_string("infotext")

    meta:set_int("timer", timer + 1)
    meta:set_string("infotext", ("%s, Filling in %ds"):format(infotext:split(",")[1], time_left))

    if time_left <= 0 then
        fill_chest_random(pos, loot)
    end

    -- Reset node timer
    if timer >= refill_time then
        meta:set_int("timer", 0)
    end
end

local function regular_chest_on_rightclick(pos, node, clicker)
    local cn = clicker:get_player_name()

    if default.chest.open_chests[cn] then
        default.chest.chest_lid_close(cn)
    end
    core.sound_play("default_chest_open", {gain = 0.3, pos = pos, max_hear_distance = 10}, true)
    if not default.chest.chest_lid_obstructed(pos) then
        core.swap_node(pos, {name = "ffa_loot:regular_chest_open", param2 = node.param2 })
    end
    core.after(0.2, core.show_formspec, cn, "ffa_loot:regular_chest", default.chest.get_chest_formspec(pos))
    default.chest.open_chests[cn] = { pos = pos, sound = "default_chest_close", swap = "ffa_loot:regular_chest" }
end

core.register_node("ffa_loot:regular_chest", {
	description = "Regular Chest",
	tiles = {
		"default_chest_top.png",
		"default_chest_top.png",
		"default_chest_side.png",
		"default_chest_side.png",
        "default_chest_side.png",
		"default_chest_front.png",
	},
	paramtype = "light",
    paramtype2 = "facedir",
	legacy_facedir_simple = true,
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
	groups = {choppy = 2, oddly_breakable_by_hand = 2},
    on_construct = function(pos) construct_node(pos, "Regular Chest") end,
    can_dig = function(pos,player) can_dig_node(pos) end,
    on_rightclick = function(pos, node, clicker) regular_chest_on_rightclick(pos, node, clicker) end,
    on_timer = function(pos, elapsed)
        update_node(pos, REGULAR_CHEST, loot_table)
        return true
    end,
    on_blast = function() end,
})

core.register_node("ffa_loot:regular_chest_open", {
	description = "Regular Chest Open",
	tiles = {
        {name = "default_chest_top.png", backface_culling = true},
        {name = "default_chest_top.png", backface_culling = true},
        {name = "default_chest_side.png", backface_culling = true},
        {name = "default_chest_side.png", backface_culling = true},
        {name = "default_chest_front.png", backface_culling = true},
        {name = "default_chest_inside.png", backface_culling = true},
	},
    selection_box = {
		type = "fixed",
		fixed = { -1/2, -1/2, -1/2, 1/2, 3/16, 1/2 },
	},
    drawtype = "mesh",
    mesh = "chest_open.obj",
	paramtype = "light",
    paramtype2 = "facedir",
	legacy_facedir_simple = true,
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
	groups = {choppy = 2, oddly_breakable_by_hand = 2, not_in_creative_inventory=1},
    on_construct = function(pos) construct_node(pos, "Regular Chest") end,
    can_dig = function(pos,player) can_dig_node(pos) end,
    on_rightclick = function(pos, node, clicker) regular_chest_on_rightclick(pos, node, clicker) end,
    on_timer = function(pos, elapsed)
        update_node(pos, REGULAR_CHEST, loot_table)
        return true
    end,
    on_blast = function() end,
    drop = "ffa_loot:regular_chest"
})

--
--- MESE CHEST
--

local function chest_opened(pos)
    local meta = core.get_meta(pos)
    return meta:get_int("timer") ~= 0
end

local function has_key(clicker, pos)
    local stack = ItemStack("ffa_loot:golden_key")
    local name = clicker:get_player_name()
    local wielded_item = clicker:get_wielded_item()
    if wielded_item == stack then
        return true
    end

    if not chest_opened(pos) then
        core.chat_send_player(name,
        ("You need a %s to open this chest."):format(core.colorize("#FFDF20", stack:get_description())))
    end

    return false
end

local function remove_key(clicker)
    local inv = clicker:get_inventory()
    inv:remove_item("main", "ffa_loot:golden_key" .. " 1")
end


local function update_mese_chest(pos, closing_time)
    local meta = core.get_meta(pos)
    local timer = meta:get_int("timer")
    local infotext = meta:get_string("infotext")

    meta:set_int("timer", timer - 1)
    meta:set_string("infotext", ("%s, Closing in %ds"):format(infotext:split(",")[1], timer - 1))

    if (timer -1) == 0 then
        meta:set_string("infotext", ("%s"):format(infotext:split(",")[1]))
        core.swap_node(pos, {name = "ffa_loot:mese_chest", param2 = core.get_node(pos).param2 })
    end
end

core.register_node("ffa_loot:mese_chest", {
	description = "Mese Chest",
	tiles = {
        "(default_chest_top.png^default_mese_crystal.png)^[colorize:#FFDF20:100",
        "default_chest_top.png^[colorize:#FFDF20:100",
        "default_chest_side.png^[colorize:#FFDF20:100",
        "default_chest_side.png^[colorize:#FFDF20:100",
        "default_chest_side.png^[colorize:#FFDF20:100",
        "default_chest_front.png^[colorize:#FFDF20:100"
	},
	paramtype = "light",
    paramtype2 = "facedir",
	legacy_facedir_simple = true,
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
	groups = {choppy = 2, oddly_breakable_by_hand = 2},
    on_construct = function(pos) construct_node(pos, "Mese Chest") end,
    can_dig = function(pos,player) can_dig_node(pos) end,
    on_rightclick = function(pos, node, clicker)
        local cn = clicker:get_player_name()
        local meta = core.get_meta(pos)
        local is_opened = chest_opened(pos)

        if not has_key(clicker, pos) and not is_opened then
            return
        end

        if not is_opened then
            core.after(0, remove_key, clicker)
            fill_chest_random(pos, golden_loot_table)
            meta:set_int("timer", MESE_CHEST)
        end

        core.sound_play("ffa_loot_unlock", {gain = 0.3, pos = pos, max_hear_distance = 10}, true)
        core.swap_node(pos, {name = "ffa_loot:mese_chest_open", param2 = node.param2 })

        core.after(0.2, core.show_formspec, cn, "ffa_loot:mese_chest", default.chest.get_chest_formspec(pos))
    end,
    on_timer = function(pos, elapsed)
        local is_opened = chest_opened(pos)
        if is_opened then
            update_mese_chest(pos, MESE_CHEST)
        end

        return true
    end,
    on_blast = function() end,
})

core.register_node("ffa_loot:mese_chest_open", {
	description = "Mese Chest",
	tiles = {
        {name = "(default_chest_top.png^default_mese_crystal.png)^[colorize:#FFDF20:100", backface_culling = true},
        {name = "default_chest_top.png^[colorize:#FFDF20:100", backface_culling = true},
        {name = "default_chest_side.png^[colorize:#FFDF20:100", backface_culling = true},
        {name = "default_chest_side.png^[colorize:#FFDF20:100", backface_culling = true},
        {name = "default_chest_front.png^[colorize:#FFDF20:100", backface_culling = true},
        {name = "default_chest_inside.png", backface_culling = true},
	},
    selection_box = {
		type = "fixed",
		fixed = { -1/2, -1/2, -1/2, 1/2, 3/16, 1/2 },
	},
    drawtype = "mesh",
    mesh = "chest_open.obj",
	paramtype = "light",
    paramtype2 = "facedir",
	legacy_facedir_simple = true,
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
	groups = {choppy = 2, oddly_breakable_by_hand = 2, not_in_creative_inventory=1},
    on_construct = function(pos) construct_node(pos, "Mese Chest") end,
    can_dig = function(pos,player) can_dig_node(pos) end,
    on_rightclick = function(pos, node, clicker)
        local cn = clicker:get_player_name()
        core.show_formspec(cn, "ffa_loot:mese_chest", default.chest.get_chest_formspec(pos))
    end,
    on_timer = function(pos, elapsed)
        local is_opened = chest_opened(pos)
        if is_opened then
            update_mese_chest(pos, MESE_CHEST)
        end

        return true
    end,
    on_blast = function() end,
    drop = "ffa_loot:mese_chest"
})

core.register_craftitem("ffa_loot:golden_key", {
    description = core.colorize("#FFDF20", "Golden Key"),
    inventory_image = "ffa_loot_key.png",
    stack_max = 1
})

core.register_lbm({
    label = "Close opened chests on load",
    name = "ffa_loot:close_chest_open",
    nodenames = {"ffa_loot:regular_chest_open"},
    run_at_every_load = true,
    action = function(pos, node)
        node.name = (node.name):sub(1, (node.name):len() - 5)
        core.swap_node(pos, node)
    end
})
