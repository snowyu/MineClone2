local adjacents = {
	vector.new(1,0,0),
	vector.new(1,0,1),
	vector.new(1,0,-1),
	vector.new(-1,0,0),
	vector.new(-1,0,1),
	vector.new(-1,0,-1),
	vector.new(0,0,1),
	vector.new(0,0,-1),
	vector.new(0,-1,0)
}

local plane_adjacents = {
	vector.new(1,0,0),
	vector.new(-1,0,0),
	vector.new(0,0,1),
	vector.new(0,0,-1),
}

local function set_node_no_bedrock(pos,node)
	local n = minetest.get_node(pos)
	if n.name == "mcl_core:bedrock" then return end
	return minetest.set_node(pos,node)
end

local function airtower(pos,tbl,h)
	for i=1,h do
		table.insert(tbl,vector.offset(pos,0,i,0))
	end
end

local function makelake(pos,size,liquid,placein,border,pr)
	local node_under = minetest.get_node(vector.offset(pos,0,-1,0))
	local p1 = vector.offset(pos,-size,-1,-size)
	local p2 = vector.offset(pos,size,-1,size)
	minetest.emerge_area(p1, p2, function(blockpos, action, calls_remaining, param)
		if calls_remaining ~= 0 then return end
		local nn = minetest.find_nodes_in_area(p1,p2,placein)
		table.sort(nn,function(a, b)
		   return vector.distance(vector.new(pos.x,0,pos.z), a) < vector.distance(vector.new(pos.x,0,pos.z), b)
		end)
		if not nn[1] then return end
		local y = pos.y - pr:next(1,2)
		local lq = {}
		local air = {}
		local r = pr:next(1,#nn)
		if r > #nn then return end
		for i=1,r do
			if nn[i].y == y then
				airtower(nn[i],air,55)
				table.insert(lq,nn[i])
			end
		end
		minetest.bulk_set_node(lq,{name=liquid})
		minetest.bulk_set_node(air,{name="air"})
		air = {}
		local br = {}
		for k,v in pairs(lq) do
			for kk,vv in pairs(adjacents) do
				local pp = vector.add(v,vv)
				local an = minetest.get_node(pp)
				local un = minetest.get_node(vector.offset(pp,0,1,0))
				if not border then
					if minetest.get_item_group(an.name,"solid") > 0 then
						border = an.name
					elseif minetest.get_item_group(minetest.get_node(nn[1]).name,"solid") > 0 then
						border = minetest.get_node_or_nil(nn[1]).name
					else
						border = "mcl_core:stone"
					end
					if border == nil or border == "mcl_core:dirt" then border = "mcl_core:dirt_with_grass" end
				end
				if an.name ~= liquid then
					table.insert(br,pp)
					if un.name ~= liquid then
						airtower(pp,air,55)
					end
				end
			end
		end
		minetest.bulk_set_node(br,{name=border})
		minetest.bulk_set_node(air,{name="air"})
		return true
	end)
	return true
end

mcl_structures.register_structure("lavapool",{
	place_on = {"group:sand", "group:dirt", "group:stone"},
	terrain_feature = true,
	noise_params = {
		offset = 0,
		scale = 0.0000022,
		spread = {x = 250, y = 250, z = 250},
		seed = 78375213,
		octaves = 3,
		persist = 0.001,
		flags = "absvalue",
	},
	flags = "place_center_x, place_center_z, force_placement",
	y_max = mcl_vars.mg_overworld_max,
	y_min = minetest.get_mapgen_setting("water_level"),
	place_func = function(pos,def,pr)
		return makelake(pos,5,"mcl_core:lava_source",{"group:material_stone", "group:sand", "group:dirt"},"mcl_core:stone",pr)
	end
})

mcl_structures.register_structure("water_lake",{
	place_on = {"group:dirt","group:stone"},
	terrain_feature = true,
	noise_params = {
		offset = 0,
		scale = 0.000032,
		spread = {x = 250, y = 250, z = 250},
		seed = 756641353,
		octaves = 3,
		persist = 0.001,
		flags = "absvalue",
	},
	flags = "place_center_x, place_center_z, force_placement",
	y_max = mcl_vars.mg_overworld_max,
	y_min = minetest.get_mapgen_setting("water_level"),
	place_func = function(pos,def,pr)
		return makelake(pos,5,"mcl_core:water_source",{"group:material_stone", "group:sand", "group:dirt","group:grass_block"},nil,pr)
	end
})

local pool_adjacents = {
	vector.new(1,0,0),
	vector.new(-1,0,0),
	vector.new(0,-1,0),
	vector.new(0,0,1),
	vector.new(0,0,-1),
}

mcl_structures.register_structure("basalt_column",{
	place_on = {"mcl_blackstone:blackstone","mcl_blackstone:basalt"},
	terrain_feature = true,
	spawn_by = {"air"},
	num_spawn_by = 2,
	noise_params = {
		offset = 0,
		scale = 0.003,
		spread = {x = 250, y = 250, z = 250},
		seed = 72235213,
		octaves = 5,
		persist = 0.3,
		flags = "absvalue",
	},
	flags = "all_floors",
	y_max = mcl_vars.mg_nether_max - 20,
	y_min = mcl_vars.mg_lava_nether_max + 1,
	biomes = { "BasaltDelta" },
	place_func = function(pos,def,pr)
		local nn = minetest.find_nodes_in_area(vector.offset(pos,-5,-1,-5),vector.offset(pos,5,-1,5),{"air","mcl_blackstone:basalt","mcl_blackstone:blackstone"})
		table.sort(nn,function(a, b)
		   return vector.distance(vector.new(pos.x,0,pos.z), a) < vector.distance(vector.new(pos.x,0,pos.z), b)
		end)
		if #nn < 1 then return false end
		local basalt = {}
		local magma = {}
		for i=1,pr:next(1,#nn) do
			if minetest.get_node(vector.offset(nn[i],0,-1,0)).name ~= "air" then
				local dst=vector.distance(pos,nn[i])
				local r = pr:next(1,14)-dst
				for ii=0,r do
					if pr:next(1,25) == 1 then
						table.insert(magma,vector.new(nn[i].x,nn[i].y + ii,nn[i].z))
					else
						table.insert(basalt,vector.new(nn[i].x,nn[i].y + ii,nn[i].z))
					end
				end
			end
		end
		minetest.bulk_set_node(magma,{name="mcl_nether:magma"})
		minetest.bulk_set_node(basalt,{name="mcl_blackstone:basalt"})
		return true
	end
})
mcl_structures.register_structure("basalt_pillar",{
	place_on = {"mcl_blackstone:blackstone","mcl_blackstone:basalt"},
	terrain_feature = true,
	noise_params = {
		offset = 0,
		scale = 0.001,
		spread = {x = 250, y = 250, z = 250},
		seed = 7113,
		octaves = 5,
		persist = 0.1,
		flags = "absvalue",
	},
	flags = "all_floors",
	y_max = mcl_vars.mg_nether_max-40,
	y_min = mcl_vars.mg_lava_nether_max + 1,
	biomes = { "BasaltDelta" },
	place_func = function(pos,def,pr)
		local nn = minetest.find_nodes_in_area(vector.offset(pos,-2,-1,-2),vector.offset(pos,2,-1,2),{"air","mcl_blackstone:basalt","mcl_blackstone:blackstone"})
		table.sort(nn,function(a, b)
		   return vector.distance(vector.new(pos.x,0,pos.z), a) < vector.distance(vector.new(pos.x,0,pos.z), b)
		end)
		if #nn < 1 then return false end
		local basalt = {}
		local magma = {}
		for i=1,pr:next(1,#nn) do
			if minetest.get_node(vector.offset(nn[i],0,-1,0)).name ~= "air" then
				local dst=vector.distance(pos,nn[i])
				for ii=0,pr:next(19,35)-dst do
					if pr:next(1,20) == 1 then
						table.insert(magma,vector.new(nn[i].x,nn[i].y + ii,nn[i].z))
					else
						table.insert(basalt,vector.new(nn[i].x,nn[i].y + ii,nn[i].z))
					end
				end
			end
		end
		minetest.bulk_set_node(basalt,{name="mcl_blackstone:basalt"})
		minetest.bulk_set_node(magma,{name="mcl_nether:magma"})
		return true
	end
})

mcl_structures.register_structure("lavadelta",{
	place_on = {"mcl_blackstone:blackstone","mcl_blackstone:basalt"},
	spawn_by = {"mcl_blackstone:basalt","mcl_blackstone:blackstone"},
	num_spawn_by = 2,
	terrain_feature = true,
	noise_params = {
		offset = 0,
		scale = 0.005,
		spread = {x = 250, y = 250, z = 250},
		seed = 78375213,
		octaves = 5,
		persist = 0.1,
		flags = "absvalue",
	},
	flags = "all_floors",
	y_max = mcl_vars.mg_nether_max,
	y_min = mcl_vars.mg_lava_nether_max + 1,
	biomes = { "BasaltDelta" },
	place_func = function(pos,def,pr)
		local nn = minetest.find_nodes_in_area_under_air(vector.offset(pos,-10,-1,-10),vector.offset(pos,10,-2,10),{"mcl_blackstone:basalt","mcl_blackstone:blackstone","mcl_nether:netherrack"})
		table.sort(nn,function(a, b)
		   return vector.distance(vector.new(pos.x,0,pos.z), a) < vector.distance(vector.new(pos.x,0,pos.z), b)
		end)
		if #nn < 1 then return false end
		local lava = {}
		for i=1,pr:next(1,#nn) do
			table.insert(lava,nn[i])
		end
		minetest.bulk_set_node(lava,{name="mcl_nether:nether_lava_source"})
		local basalt = {}
		local magma = {}
		for _,v in pairs(lava) do
			for _,vv in pairs(adjacents) do
				local p = vector.add(v,vv)
				if minetest.get_node(p).name ~= "mcl_nether:nether_lava_source" then
					table.insert(basalt,p)

				end
			end
			if math.random(3) == 1 then
				table.insert(magma,v)
			end
		end
		minetest.bulk_set_node(basalt,{name="mcl_blackstone:basalt"})
		minetest.bulk_set_node(magma,{name="mcl_nether:magma"})
		return true
	end
})
