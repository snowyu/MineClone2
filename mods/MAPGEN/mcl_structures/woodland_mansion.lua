local modname = minetest.get_current_modname()
local S = minetest.get_translator(modname)
local modpath = minetest.get_modpath(modname)

mcl_structures.register_structure("woodland_cabin",{
	place_on = {"group:grass_block","group:dirt","mcl_core:dirt_with_grass"},
	fill_ratio = 0.01,
	flags = "place_center_x, place_center_z",
	solid_ground = true,
	make_foundation = true,
	chunk_probability = 800,
	y_max = mcl_vars.mg_overworld_max,
	y_min = 1,
	biomes = { "RoofedForest" },
	sidelen = 32,
	filenames = {
		modpath.."/schematics/mcl_structures_woodland_cabin.mts",
		modpath.."/schematics/mcl_structures_woodland_outpost.mts",
	},
	after_place = function(p,def,pr)
		local spawnon = {"mcl_deepslate:deepslate","mcl_core:birchwood","mcl_wool:red_carpet","mcl_wool:brown_carpet"}
		local p1=vector.offset(p,-def.sidelen,-1,-def.sidelen)
		local p2=vector.offset(p,def.sidelen,def.sidelen,def.sidelen)
		local sp = minetest.find_nodes_in_area_under_air(p1,p2,spawnon)
		if sp and #sp > 0 then
			for i=1,5 do
				local pos = sp[pr:next(1,#sp)]
				if pos then
					minetest.add_entity(pos,"mobs_mc:vindicator")
				end
			end
			local pos = sp[pr:next(1,#sp)]
			if pos then
				minetest.add_entity(pos,"mobs_mc:evoker")
			end
		end
		local parrot = minetest.find_node_near(p,25,{"mcl_heads:wither_skeleton"})
		if parrot then
			minetest.add_entity(parrot,"mobs_mc:parrot")
		end
	end,
	loot = {
		["mcl_chests:chest_small" ] ={{
			stacks_min = 3,
			stacks_max = 3,
			items = {
				{ itemstring = "mcl_mobitems:bone", weight = 10, amount_min = 1, amount_max=8 },
				{ itemstring = "mcl_mobitems:gunpowder", weight = 10, amount_min = 1, amount_max = 8 },
				{ itemstring = "mcl_mobitems:rotten_flesh", weight = 10, amount_min = 1, amount_max=8 },
				{ itemstring = "mcl_mobitems:string", weight = 10, amount_min = 1, amount_max=8 },

				{ itemstring = "mcl_core:gold_ingot", weight = 15, amount_min = 2, amount_max = 7 },
			}},{
				stacks_min = 1,
				stacks_max = 4,
				items = {
				{ itemstring = "mcl_farming:wheat_item", weight = 20, amount_min = 1, amount_max = 4 },
				{ itemstring = "mcl_farming:bread", weight = 20, amount_min = 1, amount_max = 1 },
				{ itemstring = "mcl_core:coal_lump", weight = 15, amount_min = 1, amount_max = 4 },
				{ itemstring = "mesecons:mesecon", weight = 15, amount_min = 1, amount_max = 4 },
				{ itemstring = "mcl_farming:beetroot_seeds", weight = 10, amount_min = 2, amount_max = 4 },
				{ itemstring = "mcl_farming:melon_seeds", weight = 10, amount_min = 2, amount_max = 4 },
				{ itemstring = "mcl_farming:pumpkin_seeds", weight = 10, amount_min = 2, amount_max = 4 },
				{ itemstring = "mcl_core:iron_ingot", weight = 10, amount_min = 1, amount_max = 4 },
				{ itemstring = "mcl_buckets:bucket_empty", weight = 10, amount_min = 1, amount_max = 1 },
				{ itemstring = "mcl_core:gold_ingot", weight = 5, amount_min = 1, amount_max = 4 },
			}},{
				stacks_min = 1,
				stacks_max = 4,
				items = {
				--{ itemstring = "FIXME:lead", weight = 20, amount_min = 1, amount_max = 1 },
				{ itemstring = "mcl_mobs:nametag", weight = 2, amount_min = 1, amount_max = 3 },
				{ itemstring = "mcl_books:book", weight = 1, func = function(stack, pr)mcl_enchanting.enchant_uniform_randomly(stack, {"soul_speed"}, pr) end },
				{ itemstring = "mcl_armor:chestplate_chain", weight = 1, },
				{ itemstring = "mcl_armor:chestplate_diamond", weight = 1, },
				{ itemstring = "mcl_core:apple_gold_enchanted", weight = 2, },
			}
		}}
	}
})
