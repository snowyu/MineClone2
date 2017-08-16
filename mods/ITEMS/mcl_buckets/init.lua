-- Minetest 0.4 mod: bucket
-- See README.txt for licensing and other information.

minetest.register_alias("bucket:bucket_empty", "mcl_buckets:bucket_empty")
minetest.register_alias("bucket:bucket_water", "mcl_buckets:bucket_water")
minetest.register_alias("bucket:bucket_lava", "mcl_buckets:bucket_lava")

local mod_doc = minetest.get_modpath("doc")
local mod_mcl_core = minetest.get_modpath("mcl_core")

if mod_mcl_core then
	minetest.register_craft({
		output = 'mcl_buckets:bucket_empty 1',
		recipe = {
			{'mcl_core:iron_ingot', '', 'mcl_core:iron_ingot'},
			{'', 'mcl_core:iron_ingot', ''},
		}
	})
end

mcl_buckets = {}
mcl_buckets.liquids = {}

-- Sound helper functions for placing and taking liquids
local sound_place = function(itemname, pos)
	local def = minetest.registered_nodes[itemname]
	if def and def.sounds and def.sounds.place then
		minetest.sound_play(def.sounds.place, {gain=1.0, pos = pos})
	end
end

local sound_take = function(itemname, pos)
	local def = minetest.registered_nodes[itemname]
	if def and def.sounds and def.sounds.dug then
		minetest.sound_play(def.sounds.dug, {gain=1.0, pos = pos})
	end
end

-- Register a new liquid
--   source_place = a string or function.
--      * string: name of the node to place
--      * function(pos): will returns name of the node to place with pos being the placement position
--   source_take = table of liquid source node names to take
--   itemname = itemstring of the new bucket item (or nil if liquid is not takeable)
--   inventory_image = texture of the new bucket item (ignored if itemname == nil)
--   name = user-visible bucket description
--   longdesc = long explanatory description (for help)
--   usagehelp = short usage explanation (for help)
--   extra_check = optional function(pos) which can returns false to avoid placing the liquid
--
-- This function can be called from any mod (which depends on this one)
function mcl_buckets.register_liquid(source_place, source_take, itemname, inventory_image, name, longdesc, usagehelp, extra_check)
	for i=1, #source_take do
		mcl_buckets.liquids[source_take[i]] = {
			source_place = source_place,
			source_take = source_take[i],
			itemname = itemname,
		}
		if type(source_place) == "string" then
			mcl_buckets.liquids[source_place] = mcl_buckets.liquids[source_take[i]]
		end
	end

	if itemname ~= nil then
		minetest.register_craftitem(itemname, {
			description = name,
			_doc_items_longdesc = longdesc,
			_doc_items_usagehelp = usagehelp,
			inventory_image = inventory_image,
			stack_max = 16,
			liquids_pointable = true,
			on_place = function(itemstack, user, pointed_thing)
				-- Must be pointing to node
				if pointed_thing.type ~= "node" then
					return
				end

				local node = minetest.get_node(pointed_thing.under)
				local place_pos = pointed_thing.under
				local nn = node.name
				-- Call on_rightclick if the pointed node defines it
				if user and not user:get_player_control().sneak then
					if minetest.registered_nodes[nn] and minetest.registered_nodes[nn].on_rightclick then
						return minetest.registered_nodes[nn].on_rightclick(place_pos, node, user, itemstack) or itemstack
					end
				end

				local place_liquid = function(pos, itemstring)
					local fullness = minetest.registered_nodes[itemstring].liquid_range
					sound_place(itemstring, pos)
					minetest.add_node(pos, {name=itemstring, param2=fullness})
				end

				local node_place
				if type(source_place) == "function" then
					node_place = source_place(place_pos)
				else
					node_place = source_place
				end
				-- Check if pointing to a buildable node
				local item = itemstack:get_name()

				if extra_check and extra_check(place_pos) == false then
					-- Fail placement of liquid
				elseif item == "mcl_buckets:bucket_water" and
						(nn == "mcl_cauldrons:cauldron" or
						nn == "mcl_cauldrons:cauldron_1" or
						nn == "mcl_cauldrons:cauldron_2") then
					-- Put water into cauldron
					minetest.set_node(place_pos, {name="mcl_cauldrons:cauldron_3"})

					sound_place("mcl_core:water_source", pos)
				elseif item == "mcl_buckets:bucket_water" and nn == "mcl_cauldrons:cauldron_3" then
					sound_place("mcl_core:water_source", pos)
				elseif minetest.registered_nodes[nn] and minetest.registered_nodes[nn].buildable_to then
					-- buildable; replace the node
					local pns = user:get_player_name()
					if minetest.is_protected(place_pos, pns) then
						return itemstack
					end
					place_liquid(place_pos, node_place)
					if mod_doc and doc.entry_exists("nodes", node_place) then
						doc.mark_entry_as_revealed(user:get_player_name(), "nodes", node_place)
					end
				else
					-- not buildable to; place the liquid above
					-- check if the node above can be replaced
					local abovenode = minetest.get_node(pointed_thing.above)
					if minetest.registered_nodes[abovenode.name] and minetest.registered_nodes[abovenode.name].buildable_to then
						local pn = user:get_player_name()
						if minetest.is_protected(pointed_thing.above, pn) then
							return itemstack
						end
						place_liquid(pointed_thing.above, node_place)
						if mod_doc and doc.entry_exists("nodes", node_place) then
							doc.mark_entry_as_revealed(user:get_player_name(), "nodes", node_place)
						end
					else
						-- do not remove the bucket with the liquid
						return
					end
				end

				-- Handle bucket item and inventory stuff
				if not minetest.settings:get_bool("creative_mode") then
					-- Add empty bucket and put it into inventory, if possible.
					-- Drop empty bucket otherwise.
					local new_bucket = ItemStack("mcl_buckets:bucket_empty")
					if itemstack:get_count() == 1 then
						return new_bucket
					else
						local inv = user:get_inventory()
						if inv:room_for_item("main", new_bucket) then
							inv:add_item("main", new_bucket)
						else
							minetest.add_item(user:getpos(), new_bucket)
						end
						itemstack:take_item()
						return itemstack
					end
				else
					return
				end
			end
		})
	end
end

minetest.register_craftitem("mcl_buckets:bucket_empty", {
	description = "Empty Bucket",
	_doc_items_longdesc = "A bucket can be used to collect and release liquids.",
	_doc_items_usagehelp = "Punch a liquid source to collect the liquid. With the filled bucket, you can right-click somewhere to empty the bucket which will create a liquid source at the position you've clicked at.",

	inventory_image = "bucket.png",
	stack_max = 16,
	liquids_pointable = true,
	on_place = function(itemstack, user, pointed_thing)
		-- Must be pointing to node
		if pointed_thing.type ~= "node" then
			return
		end

		-- Call on_rightclick if the pointed node defines it
		local node = minetest.get_node(pointed_thing.under)
		local nn = node.name
		if user and not user:get_player_control().sneak then
			if minetest.registered_nodes[nn] and minetest.registered_nodes[nn].on_rightclick then
				return minetest.registered_nodes[nn].on_rightclick(pointed_thing.under, node, user, itemstack) or itemstack
			end
		end

		-- Check if pointing to a liquid source
		liquiddef = mcl_buckets.liquids[nn]
		local new_bucket
		if liquiddef ~= nil and liquiddef.itemname ~= nil and (nn == liquiddef.source_take) then

			-- Fill bucket, but not in Creative Mode
			if not minetest.settings:get_bool("creative_mode") then
				new_bucket = ItemStack({name = liquiddef.itemname, metadata = tostring(node.param2)})
			end

			minetest.add_node(pointed_thing.under, {name="air"})
			sound_take(nn, pointed_thing.under)

			if mod_doc and doc.entry_exists("nodes", nn) then
				doc.mark_entry_as_revealed(user:get_player_name(), "nodes", nn)
			end

		elseif nn == "mcl_cauldrons:cauldron_3" then
			-- Take water out of full cauldron
			minetest.set_node(pointed_thing.under, {name="mcl_cauldrons:cauldron"})
			if not minetest.settings:get_bool("creative_mode") then
				new_bucket = ItemStack("mcl_buckets:bucket_water")
			end
			sound_take("mcl_core:water_source", pointed_thing.under)
		end

		-- Add liquid bucket and put it into inventory, if possible.
		-- Drop new bucket otherwise.
		if new_bucket then
			if itemstack:get_count() == 1 then
				return new_bucket
			else
				local inv = user:get_inventory()
				if inv:room_for_item("main", new_bucket) then
					inv:add_item("main", new_bucket)
				else
					minetest.add_item(user:getpos(), new_bucket)
				end
				if not minetest.settings:get_bool("creative_mode") then
					itemstack:take_item()
				end
				return itemstack
			end
		end
	end,
})

if mod_mcl_core then
	-- Water bucket
	mcl_buckets.register_liquid(
		"mcl_core:water_source",
		{"mcl_core:water_source"},
		"mcl_buckets:bucket_water",
		"bucket_water.png",
		"Water Bucket",
		"A bucket can be used to collect and release liquids. This one is filled with water.",
		"Right-click on any block to empty the bucket and put a water source on this spot.",
		function(pos)
			local _, dim = mcl_util.y_to_layer(pos.y)
			if dim == "nether" then
				minetest.sound_play("fire_extinguish_flame", {pos = pos, gain = 0.25, max_hear_distance = 16})
				return false
			else
				return true
			end
		end
	)

	-- Lava bucket
	mcl_buckets.register_liquid(
		function(pos)
			local _, dim = mcl_util.y_to_layer(pos.y)
			if dim == "nether" then
				return "mcl_nether:nether_lava_source"
			else
				return "mcl_core:lava_source"
			end
		end,
		{"mcl_core:lava_source", "mcl_nether:nether_lava_source"},
		"mcl_buckets:bucket_lava",
		"bucket_lava.png",
		"Lava Bucket",
		"A bucket can be used to collect and release liquids. This one is filled with hot lava, safely contained inside. Use with caution.",
		"Choose a place where you want to empty the bucket, then get in a safe spot somewhere above it. Be prepared to run away when something goes wrong as the lava will soon start to flow after placing. To empty the bucket (which places a lava source), right-click on your chosen place."
	)
end

minetest.register_craft({
	type = "fuel",
	recipe = "mcl_buckets:bucket_lava",
	burntime = 1000,
	replacements = {{"mcl_buckets:bucket_lava", "mcl_buckets:bucket_empty"}},
})
