local dim = {"x", "z"}

local modpath = minetest.get_modpath(minetest.get_current_modname())

local function load_schem(filename)
	local file = io.open(modpath .. "/schems/" .. filename, "r")
	local data = minetest.deserialize(file:read())
	file:close()
	return data
end

local wither_spawn_schems = {}

for _, d in pairs(dim) do
	wither_spawn_schems[d] = load_schem("wither_spawn_" .. d .. ".we")
end

local function check_schem(pos, schem)
	for _, n in pairs(schem) do
		if minetest.get_node(vector.add(pos, n)).name ~= n.name then
			return false
		end
	end
	return true
end

local function remove_schem(pos, schem)
	for _, n in pairs(schem) do
		minetest.remove_node(vector.add(pos, n))
	end
end

local function wither_spawn(pos)
	for _, d in pairs(dim) do
		for i = 0, 2 do
			local p = vector.add(pos, {x = 0, y = -2, z = 0, [d] = -i})
			local schem = wither_spawn_schems[d]
			if check_schem(p, schem) then
				remove_schem(p, schem)
				minetest.add_entity(vector.add(p, {x = 0, y = 1, z = 0, [d] = 1}), "mobs_mc:wither")
				local objects = minetest.get_objects_inside_radius(pos, 20)
				for _, players in ipairs(objects) do
					if players:is_player() then
						awards.unlock(players:get_player_name(), "mcl:witheringHeights")
					end
				end
			end
		end
	end
end

local wither_head = minetest.registered_nodes["mcl_heads:wither_skeleton"]
local old_on_place = wither_head.on_place
function wither_head.on_place(itemstack, placer, pointed)
	local n = minetest.get_node(vector.offset(pointed.above,0,-1,0))
	if n and n.name  == "mcl_nether:soul_sand" then
		minetest.after(0, wither_spawn, pointed.above)
	end
	return old_on_place(itemstack, placer, pointed)
end
