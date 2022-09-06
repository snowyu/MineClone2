local modname = minetest.get_current_modname()
local S = minetest.get_translator(modname)
local modpath = minetest.get_modpath(modname)

mcl_structures.register_structure("pillager_outpost",{
	place_on = {"group:grass_block","group:dirt","mcl_core:dirt_with_grass","group:sand"},
	fill_ratio = 0.01,
	flags = "place_center_x, place_center_z",
	solid_ground = true,
	make_foundation = true,
	sidelen = 23,
	y_offset = 0,
	chunk_probability = 600,
	y_max = mcl_vars.mg_overworld_max,
	y_min = 1,
	biomes = { "Desert", "Plains", "Savanna", "IcePlains", "Taiga" },
	filenames = { modpath.."/schematics/mcl_structures_pillager_outpost.mts" },
	loot = {
		["mcl_chests:chest_small" ] ={
		{
			stacks_min = 2,
			stacks_max = 3,
			items = {
				{ itemstring = "mcl_farming:wheat_item", weight = 7, amount_min = 3, amount_max=5 },
				{ itemstring = "mcl_farming:carrot_item", weight = 5, amount_min = 3, amount_max=5 },
				{ itemstring = "mcl_farming:potato_item", weight = 5, amount_min = 2, amount_max=5 },
			}
		},
		{
			stacks_min = 1,
			stacks_max = 2,
			items = {
				{ itemstring = "mcl_experience:bottle", weight = 6, amount_min = 0, amount_max=1 },
				{ itemstring = "mcl_bows:arrow", weight = 4, amount_min = 2, amount_max=7 },
				{ itemstring = "mcl_mobitems:string", weight = 4, amount_min = 1, amount_max=6 },
				{ itemstring = "mcl_core:iron_ingot", weight = 3, amount_min = 1, amount_max = 3 },
				{ itemstring = "mcl_books:book", weight = 1, func = function(stack, pr)
					mcl_enchanting.enchant_uniform_randomly(stack, {"soul_speed"}, pr)
				end },
			}
		},
		{
			stacks_min = 1,
			stacks_max = 3,
			items = {
				{ itemstring = "mcl_core:darktree", amount_min = 2, amount_max=3 },
			}
		},
		{
			stacks_min = 1,
			stacks_max = 1,
			items = {
				{ itemstring = "mcl_bows:crossbow" },
			}
		}}
	},
	after_place = function(p,def,pr)
		local p1 = vector.offset(p,-7,0,-7)
		local p2 = vector.offset(p,7,14,7)
		local spawnon = {"mcl_core:stripped_oak"}
		local sp = minetest.find_nodes_in_area_under_air(p1,p2,spawnon)
		for _,n in pairs(minetest.find_nodes_in_area(p1,p2,{"group:wall"})) do
			local def = minetest.registered_nodes[minetest.get_node(n).name:gsub("_%d+$","")]
			if def and def.on_construct then
				def.on_construct(n)
			end
		end
		if sp and #sp > 0 then
			for i=1,5 do
				local pos = sp[pr:next(1,#sp)]
				if pos then
					minetest.add_entity(pos,"mobs_mc:pillager")
				end
			end
			local pos = sp[pr:next(1,#sp)]
			if pos then
				minetest.add_entity(pos,"mobs_mc:evoker")
			end
		end
	end
})
