ctf_ranged = {}

local shoot_cooldown = ms_items.cooldown()

local S = core.get_translator(core.get_current_modname())

core.register_craftitem("ctf_ranged:ammo", {
	description = S("Ammo").."\n"..S("Used to reload guns"),
	inventory_image = "ctf_ranged_ammo.png",
})

local function process_ray(ray, user, look_dir, def)
	local hitpoint = ray:hit_object_or_node({
		node = function(ndef)
			return (ndef.walkable == true and ndef.pointable == true) or ndef.groups.liquid
		end,
		object = function(obj)

			if obj == user then
				return false
			end

			if obj:is_player() then
				return true
			end

			local entity = obj:get_luaentity()
			if entity and entity.health then
				return true
			end

			return false
		end
	})

	if hitpoint then
		if hitpoint.type == "node" then
			local node = core.get_node(hitpoint.under)
			local nodedef = core.registered_nodes[node.name]

			if nodedef.on_ranged_shoot or node.name == "wool:red" or node.name == "wool:blue" then
				if not core.is_protected(hitpoint.under, user:get_player_name()) then
					if nodedef.on_ranged_shoot then
						nodedef.on_ranged_shoot(hitpoint.under, node, user, def.type)
					else
						core.dig_node(hitpoint.under)
					end
				end
			else
				if nodedef.walkable and nodedef.pointable then
					if nodedef.groups.tnt and core.get_modpath("tnt") then
						tnt.burn(hitpoint.under)
					end

					core.add_particle({
						pos = vector.subtract(hitpoint.intersection_point, vector.multiply(look_dir, 0.04)),
						velocity = vector.new(),
						acceleration = {x=0, y=0, z=0},
						expirationtime = def.bullethole_lifetime or 3,
						size = 1,
						collisiondetection = false,
						texture = "ctf_ranged_bullethole.png",
					})

					core.sound_play("ctf_ranged_ricochet", {pos = hitpoint.intersection_point})
				elseif nodedef.groups.liquid then
					core.add_particlespawner({
						amount = 10,
						time = 0.1,
						minpos = hitpoint.intersection_point,
						maxpos = hitpoint.intersection_point,
						minvel = {x=look_dir.x * 3, y=4, z=-look_dir.z * 3},
						maxvel = {x=look_dir.x * 4, y=6, z= look_dir.z * 4},
						minacc = {x=0, y=-10, z=0},
						maxacc = {x=0, y=-13, z=0},
						minexptime = 1,
						maxexptime = 1,
						minsize = 0,
						maxsize = 0,
						collisiondetection = false,
						glow = 3,
						node = {name = nodedef.name},
					})

					if def.liquid_travel_dist then
						process_ray(rawf.bulletcast(
							def.bullet, hitpoint.intersection_point,
							vector.add(hitpoint.intersection_point, vector.multiply(look_dir, def.liquid_travel_dist)), true, false
						), user, look_dir, def)
					end
                end
			end
		elseif hitpoint.type == "object" then
			local player_armor = hitpoint.ref:get_armor_groups().fleshy or 100
			local armor_buff = 0

			if type(def.bullet) == "table" then
				if player_armor <= 90 and player_armor > 50 then armor_buff = 1.0
				elseif player_armor <= 50 and player_armor > 40 then armor_buff = 1.5
				elseif player_armor <= 40 and player_armor > 30 then armor_buff = 2.0
				elseif player_armor <= 30 and player_armor > 20 then armor_buff = 3.0
				elseif player_armor <= 20 then armor_buff = 4.5 end
			end

			hitpoint.ref:punch(user, def.fire_interval or 0.1, {
				full_punch_interval = def.fire_interval or 0.1,
				damage_groups = {ranged = 1, [def.type] = 1, fleshy = (def.damage + armor_buff) * 1.2}
			}, look_dir)

			--[[
			hitpoint.ref:punch(user, def.fire_interval or 0.1, {
				full_punch_interval = def.fire_interval or 0.1,
				damage_groups = {ranged = 1, [def.type] = 1, fleshy = def.damage}
			}, look_dir)
			]]
		end
	end
end

function ctf_ranged.can_use_gun(player, name)
	return true
end

local function play_player_positional_sound(user, sound_name, spec)
	local user_name = user:get_player_name()

	local non_user_spec = spec and table.copy(spec) or {}
	non_user_spec.pos = user:get_pos()
	non_user_spec.exclude_player = user_name

	local user_spec = spec and table.copy(spec) or {}
	user_spec.to_player = user_name

	core.sound_play(sound_name, non_user_spec, true)
	core.sound_play(sound_name, user_spec, true)
end

function ctf_ranged.simple_register_gun(name, def)
	core.register_tool(rawf.also_register_loaded_tool(name, {
		description = def.description ..
				("\nDMG: %d | Shots/s: %0.1f | Mag: %d"):format(
					def.damage * (def.bullet and def.bullet.amount or 1),
					1 / def.fire_interval,
					def.rounds
				),
		inventory_image = def.texture .. "^[colorize:#F44:42",
		ammo = def.ammo or "ctf_ranged:ammo",
		rounds = def.rounds,
		_g_category = def.type,
		groups = {ranged = 1, [def.type] = 1, tier = def.tier or 1, not_in_creative_inventory = 1},
		on_use = function(itemstack, user)
			if not ctf_ranged.can_use_gun(user, name) then
				play_player_positional_sound(user, "ctf_ranged_click")
				return
			end

			local result = rawf.load_weapon(itemstack, user:get_inventory())

			local sound_name
			if result:get_name() == itemstack:get_name() then
				sound_name = "ctf_ranged_click"
			else
				sound_name = "ctf_ranged_reload"
			end

			play_player_positional_sound(user, sound_name)

			return result
		end,
	},
	function(loaded_def)
		loaded_def.description = def.description ..
				("\nDMG: %d | Shots/s: %0.1f | Mag: %d"):format(
					def.damage * (def.bullet and def.bullet.amount or 1),
					1 / def.fire_interval,
					def.rounds
				) ..
				" (Loaded)"
		loaded_def.inventory_image = def.texture
		loaded_def.inventory_overlay = def.texture_overlay
		loaded_def.wield_image = def.wield_texture or def.texture
		loaded_def.groups.not_in_creative_inventory = nil
		loaded_def.on_secondary_use = def.on_secondary_use
		loaded_def.on_use = function(itemstack, user)
			if not ctf_ranged.can_use_gun(user, name) then
				play_player_positional_sound(user, "ctf_ranged_click")
				return
			end

			if shoot_cooldown:get(user) then
				return
			end

			if def.automatic then
				if not rawf.enable_automatic(def.fire_interval, itemstack, user) then
					return
				end
			else
				shoot_cooldown:set(user, def.fire_interval)
			end

			local spawnpos, look_dir = rawf.get_bullet_start_data(user)
			local endpos = vector.add(spawnpos, vector.multiply(look_dir, def.range))
			local rays

			if type(def.bullet) == "table" then
				def.bullet.texture = "ctf_ranged_bullet.png"
			else
				def.bullet = {texture = "ctf_ranged_bullet.png"}
			end

			if not def.bullet.spread then
				rays = {rawf.bulletcast(
					def.bullet,
					spawnpos, endpos, true, true
				)}
			else
				rays = rawf.spread_bulletcast(def.bullet, spawnpos, endpos, true, true)
			end

			play_player_positional_sound(user, def.fire_sound)

			for _, ray in pairs(rays) do
				process_ray(ray, user, look_dir, def)
			end

			if def.rounds > 0 then
				return rawf.unload_weapon(itemstack)
			end
		end

		if def.rightclick_func then
			loaded_def.on_place = function(itemstack, user, pointed, ...)
				local pointed_def = false
				local node

				if pointed and pointed.under then
					node = core.get_node(pointed.under)
					pointed_def = core.registered_nodes[node.name]
				end

				if pointed_def and pointed_def.on_rightclick then
					return core.item_place(itemstack, user, pointed)
				else
					return def.rightclick_func(itemstack, user, pointed, ...)
				end
			end

			loaded_def.on_secondary_use = def.rightclick_func
		end
	end))
end

core.register_on_joinplayer(function(player)
	if shoot_cooldown:get(player) then
		core.log("error", "Player is rejoining with a cooldown: "..dump(shoot_cooldown:get(player)))
	end
end)

ctf_ranged.simple_register_gun("ctf_ranged:pistol", {
	type = "pistol",
	description = S("Pistol"),
	texture = "ctf_ranged_pistol.png",
	fire_sound = "ctf_ranged_pistol",
	rounds = 75,
	range = 75,
	damage = 2,
	automatic = true,
	fire_interval = 0.6,
	liquid_travel_dist = 2
})

ctf_ranged.simple_register_gun("ctf_ranged:rifle", {
	type = "rifle",
	description = S("Rifle"),
	texture = "ctf_ranged_rifle.png",
	fire_sound = "ctf_ranged_rifle",
	rounds = 40,
	range = 150,
	damage = 4,
	automatic = false,
	fire_interval = 0.8,
	liquid_travel_dist = 4,
})

ctf_ranged.simple_register_gun("ctf_ranged:shotgun", {
	type = "shotgun",
	description = S("Shotgun"),
	texture = "ctf_ranged_shotgun.png",
	fire_sound = "ctf_ranged_shotgun",
	bullet = {
		amount = 8,
		spread = 4,
	},
	rounds = 10,
	range = 24,
	damage = 3,
	fire_interval = 2,
})

ctf_ranged.simple_register_gun("ctf_ranged:smg", {
	type = "smg",
	description = S("Submachinegun"),
	texture = "ctf_ranged_smgun.png",
	fire_sound = "ctf_ranged_pistol",
	bullet = {
		spread = 1.5,
	},
	automatic = true,
	rounds = 36,
	range = 75,
	damage = 1,
	fire_interval = 0.1,
	liquid_travel_dist = 2,
})