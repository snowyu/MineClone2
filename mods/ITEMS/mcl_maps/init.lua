mcl_maps = {}

local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)
local S = minetest.get_translator(modname)

local math = math
local vector = vector
local table = table
local pairs = pairs

local pos_to_string = minetest.pos_to_string
local string_to_pos = minetest.string_to_pos
local get_item_group = minetest.get_item_group
local dynamic_add_media = minetest.dynamic_add_media
local get_connected_players = minetest.get_connected_players

local storage = minetest.get_mod_storage()
local worldpath = minetest.get_worldpath()
local map_textures_path = worldpath .. "/mcl_maps/"
--local last_finished_id = storage:get_int("next_id") - 1

minetest.mkdir(map_textures_path)

local function load_json_file(name)
	local file = assert(io.open(modpath .. "/" .. name .. ".json", "r"))
	local data = minetest.parse_json(file:read())
	file:close()
	return data
end

local texture_colors = load_json_file("colors")
local palettes = load_json_file("palettes")

local color_cache = {}

local creating_maps = {}
local loaded_maps = {}

local c_air = minetest.get_content_id("air")

function mcl_maps.create_map(pos)
	local minp = vector.multiply(vector.floor(vector.divide(pos, 128)), 128)
	local maxp = vector.add(minp, vector.new(127, 127, 127))

	local itemstack = ItemStack("mcl_maps:filled_map")
	local meta = itemstack:get_meta()
	local next_id = storage:get_int("next_id")
	storage:set_int("next_id", next_id + 1)
	local id = tostring(next_id)
	meta:set_string("mcl_maps:id", id)
	meta:set_string("mcl_maps:minp", pos_to_string(minp))
	meta:set_string("mcl_maps:maxp", pos_to_string(maxp))
	tt.reload_itemstack_description(itemstack)

	creating_maps[id] = true
	minetest.emerge_area(minp, maxp, function(blockpos, action, calls_remaining)
		if calls_remaining > 0 then
			return
		end
		local vm = minetest.get_voxel_manip()
		local emin, emax = vm:read_from_map(minp, maxp)
		local data = vm:get_data()
		local param2data = vm:get_param2_data()
		local area = VoxelArea:new({MinEdge = emin, MaxEdge = emax})
		local pixels = {}
		local last_heightmap
		for x = 1, 128 do
			local map_x = minp.x - 1 + x
			local heightmap = {}
			for z = 1, 128 do
				local map_z = minp.z - 1 + z
				local color, height
				for map_y = maxp.y, minp.y, -1 do
					local index = area:index(map_x, map_y, map_z)
					local c_id = data[index]
					if c_id ~= c_air then
						color = color_cache[c_id]
						if color == nil then
							local nodename = minetest.get_name_from_content_id(c_id)
							local def = minetest.registered_nodes[nodename]
							if def then
								local texture
								if def.palette then
									texture = def.palette
								elseif def.tiles then
									texture = def.tiles[1]
									if type(texture) == "table" then
										texture = texture.name
									end
								end
								if texture then
									texture = texture:match("([^=^%^]-([^.]+))$"):split("^")[1]
								end
								if def.palette then
									local palette = palettes[texture]
									color = palette and {palette = palette}
								else
									color = texture_colors[texture]
								end
							end
						end

						if color and color.palette then
							color = color.palette[param2data[index] + 1]
						else
							color_cache[c_id] = color or false
						end

						if color and last_heightmap then
							local last_height = last_heightmap[z]
							if last_height < map_y then
								color = {
									math.min(255, color[1] + 16),
									math.min(255, color[2] + 16),
									math.min(255, color[3] + 16),
								}
							elseif last_height > map_y then
								color = {
									math.max(0, color[1] - 16),
									math.max(0, color[2] - 16),
									math.max(0, color[3] - 16),
								}
							end
						end
						height = map_y
						break
					end
				end
				heightmap[z] = height or minp.y
				pixels[z] = pixels[z] or {}
				pixels[z][x] = color or {0, 0, 0}
			end
			last_heightmap = heightmap
		end
		tga_encoder.image(pixels):save(map_textures_path .. "mcl_maps_map_texture_" .. id .. ".tga")
		creating_maps[id] = nil
	end)
	return itemstack
end

function mcl_maps.load_map(id, callback)
	if id == "" or creating_maps[id] then
		return
	end

	local texture = "mcl_maps_map_texture_" .. id .. ".tga"

	if not loaded_maps[id] then
		if not minetest.features.dynamic_add_media_table then
			-- minetest.dynamic_add_media() blocks in
			-- Minetest 5.3 and 5.4 until media loads
			loaded_maps[id] = true
			dynamic_add_media(map_textures_path .. texture, function() end)
			if callback then callback(texture) end
		else
			-- minetest.dynamic_add_media() never blocks
			-- in Minetest 5.5, callback runs after load
			dynamic_add_media(map_textures_path .. texture, function()
				loaded_maps[id] = true
				if callback then callback(texture) end
			end)
		end
	end

	if loaded_maps[id] then
		if callback then callback(texture) end
		return texture
	end
end

function mcl_maps.load_map_item(itemstack)
	return mcl_maps.load_map(itemstack:get_meta():get_string("mcl_maps:id"))
end

local function fill_map(itemstack, placer, pointed_thing)
	local new_stack = mcl_util.call_on_rightclick(itemstack, placer, pointed_thing)
	if new_stack then
		return new_stack
	end

	if minetest.settings:get_bool("enable_real_maps", true) then
		local new_map = mcl_maps.create_map(placer:get_pos())
		itemstack:take_item()
		if itemstack:is_empty() then
			return new_map
		else
			local inv = placer:get_inventory()
			if inv:room_for_item("main", new_map) then
				inv:add_item("main", new_map)
			else
				minetest.add_item(placer:get_pos(), new_map)
			end
			return itemstack
		end
	end
end

minetest.register_craftitem("mcl_maps:empty_map", {
	description = S("Empty Map"),
	_doc_items_longdesc = S("Empty maps are not useful as maps, but they can be stacked and turned to maps which can be used."),
	_doc_items_usagehelp = S("Rightclick to create a filled map (which can't be stacked anymore)."),
	inventory_image = "mcl_maps_map_empty.png",
	on_place = fill_map,
	on_secondary_use = fill_map,
	stack_max = 64,
})

local filled_def = {
	description = S("Map"),
	_tt_help = S("Shows a map image."),
	_doc_items_longdesc = S("When created, the map saves the nearby area as an image that can be viewed any time by holding the map."),
	_doc_items_usagehelp = S("Hold the map in your hand. This will display a map on your screen."),
	inventory_image = "mcl_maps_map_filled.png^(mcl_maps_map_filled_markings.png^[colorize:#000000)",
	stack_max = 64,
	groups = {not_in_creative_inventory = 1, filled_map = 1, tool = 1},
}

minetest.register_craftitem("mcl_maps:filled_map", filled_def)

local filled_wield_def = table.copy(filled_def)
filled_wield_def.use_texture_alpha = minetest.features.use_texture_alpha_string_modes and "opaque" or false
filled_wield_def.visual_scale = 1
filled_wield_def.wield_scale = {x = 1, y = 1, z = 1}
filled_wield_def.paramtype = "light"
filled_wield_def.drawtype = "mesh"
filled_wield_def.node_placement_prediction = ""
filled_wield_def.range = minetest.registered_items[""].range
filled_wield_def.on_place = mcl_util.call_on_rightclick

for _, texture in pairs(mcl_skins.list) do
	local def = table.copy(filled_wield_def)
	def.tiles = {texture .. ".png"}
	def.mesh = "mcl_meshhand.b3d"
	def._mcl_hand_id = texture
	minetest.register_node("mcl_maps:filled_map_" .. texture, def)

	local female_def = table.copy(def)
	female_def.mesh = "mcl_meshhand_female.b3d"
	female_def._mcl_hand_id = texture .. "_female"
	minetest.register_node("mcl_maps:filled_map_" .. texture .. "_female", female_def)
end

local old_add_item = minetest.add_item
function minetest.add_item(pos, stack)
	stack = ItemStack(stack)
	if get_item_group(stack:get_name(), "filled_map") > 0 then
		stack:set_name("mcl_maps:filled_map")
	end
	return old_add_item(pos, stack)
end

tt.register_priority_snippet(function(itemstring, _, itemstack)
	if itemstack and get_item_group(itemstring, "filled_map") > 0 then
		local id = itemstack:get_meta():get_string("mcl_maps:id")
		if id ~= "" then
			return "#" .. id, mcl_colors.GRAY
		end
	end
end)

minetest.register_craft({
	output = "mcl_maps:empty_map",
	recipe = {
		{ "mcl_core:paper", "mcl_core:paper", "mcl_core:paper" },
		{ "mcl_core:paper", "group:compass", "mcl_core:paper" },
		{ "mcl_core:paper", "mcl_core:paper", "mcl_core:paper" },
	}
})

minetest.register_craft({
	type = "shapeless",
	output = "mcl_maps:filled_map 2",
	recipe = {"group:filled_map", "mcl_maps:empty_map"},
})

local function on_craft(itemstack, player, old_craft_grid, craft_inv)
	if itemstack:get_name() == "mcl_maps:filled_map" then
		for _, stack in pairs(old_craft_grid) do
			if get_item_group(stack:get_name(), "filled_map") > 0 then
				itemstack:get_meta():from_table(stack:get_meta():to_table())
				return itemstack
			end
		end
	end
end

minetest.register_on_craft(on_craft)
minetest.register_craft_predict(on_craft)

local maps = {}
local huds = {}

minetest.register_on_joinplayer(function(player)
	local map_def = {
		hud_elem_type = "image",
		text = "blank.png",
		position = {x = 0.75, y = 0.8},
		alignment = {x = 0, y = -1},
		offset = {x = 0, y = 0},
		scale = {x = 2, y = 2},
	}
	local marker_def = table.copy(map_def)
	marker_def.alignment = {x = 0, y = 0}
	huds[player] = {
		map = player:hud_add(map_def),
		marker = player:hud_add(marker_def),
	}
end)

minetest.register_on_leaveplayer(function(player)
	maps[player] = nil
	huds[player] = nil
end)

minetest.register_globalstep(function(dtime)
	for _, player in pairs(get_connected_players()) do
		local wield = player:get_wielded_item()
		local texture = mcl_maps.load_map_item(wield)
		local hud = huds[player]
		if texture then
			local wield_def = wield:get_definition()
			local hand_def = player:get_inventory():get_stack("hand", 1):get_definition()

			if hand_def and wield_def and hand_def._mcl_hand_id ~= wield_def._mcl_hand_id then
				wield:set_name("mcl_maps:filled_map_" .. hand_def._mcl_hand_id)
				player:set_wielded_item(wield)
			end

			if texture ~= maps[player] then
				player:hud_change(hud.map, "text", "[combine:140x140:0,0=mcl_maps_map_background.png:6,6=" .. texture)
				maps[player] = texture
			end

			local pos = vector.round(player:get_pos())
			local meta = wield:get_meta()
			local minp = string_to_pos(meta:get_string("mcl_maps:minp"))
			local maxp = string_to_pos(meta:get_string("mcl_maps:maxp"))

			local marker = "mcl_maps_player_arrow.png"

			if pos.x < minp.x then
				marker = "mcl_maps_player_dot.png"
				pos.x = minp.x
			elseif pos.x > maxp.x then
				marker = "mcl_maps_player_dot.png"
				pos.x = maxp.x
			end

			if pos.z < minp.z then
				marker = "mcl_maps_player_dot.png"
				pos.z = minp.z
			elseif pos.z > maxp.z then
				marker = "mcl_maps_player_dot.png"
				pos.z = maxp.z
			end

			if marker == "mcl_maps_player_arrow.png" then
				local yaw = (math.floor(player:get_look_horizontal() * 180 / math.pi / 90 + 0.5) % 4) * 90
				marker = marker .. "^[transformR" .. yaw
			end

			player:hud_change(hud.marker, "text", marker)
			player:hud_change(hud.marker, "offset", {x = (6 - 140 / 2 + pos.x - minp.x) * 2, y = (6 - 140 + maxp.z - pos.z) * 2})
		elseif maps[player] then
			player:hud_change(hud.map, "text", "blank.png")
			player:hud_change(hud.marker, "text", "blank.png")
			maps[player] = nil
		end
	end
end)
