-- Code based from mcl_anvils

local S = minetest.get_translator(minetest.get_current_modname())

local MAX_WEAR = 65535

-- formspecs
local function get_grindstone_formspec()
	return "size[9,8.75]"..
	"image[3,1.5;1.5,1;gui_crafting_arrow.png]"..
	"label[0,4.0;"..minetest.formspec_escape(minetest.colorize("#313131", S("Inventory"))).."]"..
	"label[1,0.1;"..minetest.formspec_escape(minetest.colorize("#313131", S("Repair & Disenchant"))).."]"..
	"list[context;main;0,0;8,4;]"..
	"list[current_player;main;0,4.5;9,3;9]"..
	mcl_formspec.get_itemslot_bg(0,4.5,9,3)..
	"list[current_player;main;0,7.74;9,1;]"..
	mcl_formspec.get_itemslot_bg(0,7.74,9,1)..
	"list[context;input;1,1;1,1;]"..
	mcl_formspec.get_itemslot_bg(1,1,1,1)..
	"list[context;input;1,2;1,1;1]"..
	mcl_formspec.get_itemslot_bg(1,2,1,1)..
	"list[context;output;6,1.5;1,1;]"..
	mcl_formspec.get_itemslot_bg(6,1.5,1,1)..
	"listring[context;output]"..
	"listring[current_player;main]"..
	"listring[context;input]"..
	"listring[current_player;main]"
end

-- Creates a new item with the wear of the items and custom name
local function create_new_item(name_item, meta, wear)
	local new_item = ItemStack(name_item)
	if wear ~= nil then
			new_item:set_wear(wear)
	end
	local new_meta = new_item:get_meta()
	new_meta:set_string("name", meta:get_string("name"))
	tt.reload_itemstack_description(new_item)
	return new_item
end

-- If an item has an enchanment then remove "_enchanted" from the name
local function remove_enchant_name(stack)
	if mcl_enchanting.is_enchanted(stack:get_name()) then
		local name = stack:get_name()
		return name.sub(name, 1, -11)
	else
		return stack:get_name()
	end
end

-- If an input has a curse transfer it to the new item
local function transfer_curse(old_itemstack, new_itemstack)
	local enchants = mcl_enchanting.get_enchantments(old_itemstack)
	for enchant, level in pairs(enchants) do
		if mcl_enchanting.enchantments[enchant].curse == true then
			new_itemstack = mcl_enchanting.enchant(new_itemstack, enchant, level)
		end
	end
	return new_itemstack
end

-- Depending on an enchantment level and isn't a curse multiply xp given
local function calculate_xp(stack)
	local xp = 0
	local enchants = mcl_enchanting.get_enchantments(stack)
	for enchant, level in pairs(enchants) do
		if level > 0 and mcl_enchanting.enchantments[enchant].curse == false then
			-- Add a bit of uniform randomisation
			xp = xp + math.random(7, 13) * level
		end
	end
	return xp
end

-- Helper function to make sure update_grindstone_slots NEVER overstacks the output slot
local function fix_stack_size(stack)
	if not stack or stack == "" then return "" end
	local count = stack:get_count()
	local max_count = stack:get_stack_max()

	if count > max_count then
		stack:set_count(max_count)
		count = max_count
	end
	return count
end


-- Update the inventory slots of an grindstone node.
-- meta: Metadata of grindstone node
local function update_grindstone_slots(meta)
	local inv = meta:get_inventory()
	local input1 = inv:get_stack("input", 1)
	local input2 = inv:get_stack("input", 2)
	local meta = input1:get_meta()

	local new_output

	-- Both input slots are occupied
	if (not input1:is_empty() and not input2:is_empty()) then
		local def1 = input1:get_definition()
		local def2 = input2:get_definition()
		-- Remove enchant name if they have one
		local name1 = remove_enchant_name(input1)
		local name2 = remove_enchant_name(input2)

		-- Calculate repair
		local function calculate_repair(dur1, dur2)
			-- Grindstone gives a 5% bonus to durability
			local new_durability = (MAX_WEAR - dur1) + (MAX_WEAR - dur2) * 1.05
			return math.max(0, math.min(MAX_WEAR, MAX_WEAR - new_durability))
		end

		-- Check if both are tools and have the same tool type
		if def1.type == "tool" and def2.type == "tool" and name1 == name2 then
			local new_wear = calculate_repair(input1:get_wear(), input2:get_wear())
			local new_item = create_new_item(name1, meta, new_wear)
			-- Transfer curses if both items have any
			new_output = transfer_curse(input1, new_item)
			new_output = transfer_curse(input2, new_output)
		else
			new_output = ""
		end
	-- Check if at least one input has an item
	-- Check if the item is's an enchanted book or tool
	elseif (not input1:is_empty() and input2:is_empty()) or (input1:is_empty() and not input2:is_empty()) then
		if input2:is_empty() then
			local def1 = input1:get_definition()
			local meta = input1:get_meta()
			if def1.type == "tool" and mcl_enchanting.is_enchanted(input1:get_name()) then
				local name = remove_enchant_name(input1)
				local wear = input1:get_wear()
				local new_item = create_new_item(name, meta, wear)
				new_output = transfer_curse(input1, new_item)
			elseif input1:get_name() == "mcl_enchanting:book_enchanted" then
				new_item = create_new_item("mcl_books:book", meta, nil)
				new_output = transfer_curse(input1, new_item)
			else
				new_output = ""
			end
		else
			local def2 = input2:get_definition()
			local meta = input2:get_meta()
			if def2.type == "tool" and mcl_enchanting.is_enchanted(input2:get_name()) then
				local name = remove_enchant_name(input2)
				local wear = input2:get_wear()
				local new_item = create_new_item(name, meta, wear)
				new_output = transfer_curse(input2, new_item)
			elseif input2:get_name() == "mcl_enchanting:book_enchanted" then
				new_item = create_new_item("mcl_books:book", meta, nil)
				new_output = transfer_curse(input2, new_item)
			else
				new_output = ""
			end
		end
	else
		new_output = ""
	end

	-- Set the new output slot
	if new_output then
		fix_stack_size(new_output)
		inv:set_stack("output", 1, new_output)
	end
end

-- Drop any items inside the grindstone if destroyed
local function drop_grindstone_items(pos, meta)
	local inv = meta:get_inventory()
	for i=1, inv:get_size("input") do
		local stack = inv:get_stack("input", i)
		if not stack:is_empty() then
			local p = {x=pos.x+math.random(0, 10)/10-0.5, y=pos.y, z=pos.z+math.random(0, 10)/10-0.5}
			minetest.add_item(p, stack)
		end
	end
end

local node_box = {
	type = "fixed",
	-- created with nodebox editor
	fixed = {
		{-0.25, -0.25, -0.375, 0.25, 0.5, 0.375},
		{-0.375, -0.0625, -0.1875, -0.25, 0.3125, 0.1875},
		{0.25, -0.0625, -0.1875, 0.375, 0.3125, 0.1875},
		{0.25, -0.5, -0.125, 0.375, -0.0625, 0.125},
		{-0.375, -0.5, -0.125, -0.25, -0.0625, 0.125},
	}
}

minetest.register_node("mcl_grindstone:grindstone", {
	description = S("Grindstone"),
	_tt_help = S("Used to disenchant/fix tools"),
	_doc_items_longdesc = S("Grindstone disenchants tools and armour except for curses, and repairs two items of the same type it is also the weapon smith's work station."),
	_doc_items_usagehelp = S("To use the grindstone, rightclick it, Two input slots (on the left) and a single output slot.").."\n"..
	S("To disenchant an item place enchanted item in one of the input slots and take the disenchanted item from the output.").."\n"..
	S("To repair a tool you need a tool of the same type and material, put both items in the input slot and the output slot will combine two items durabilities with 5% bonus.").."\n"..
	S("If both items have enchantments the player will get xp from both items from the disenchant.").."\n"..
	S("Curses cannot be removed and will be transfered to the new repaired item, if both items have a different curse the curses will be combined."),
	tiles = {
		"grindstone_top.png",
		"grindstone_top.png",
		"grindstone_side.png",
		"grindstone_side.png",
		"grindstone_front.png",
		"grindstone_front.png"
	},
	drawtype = "nodebox",
	paramtype2 = "facedir",
	node_box = node_box,
	selection_box = node_box,
	collision_box = node_box,
	sounds = mcl_sounds.node_sound_stone_defaults(),
	groups = {pickaxey = 1, deco_block = 1},

	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		local meta = minetest.get_meta(pos)
		local meta2 = meta:to_table()
		meta:from_table(oldmetadata)
		drop_grindstone_items(pos, meta)
		meta:from_table(meta2)
	end,
	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		local name = player:get_player_name()
		if minetest.is_protected(pos, name) then
			minetest.record_protection_violation(pos, name)
			return 0
		else
			return stack:get_count()
		end
	end,
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		local name = player:get_player_name()
		if minetest.is_protected(pos, name) then
			minetest.record_protection_violation(pos, name)
			return 0
		elseif listname == "output" then
			return 0
		else
			return stack:get_count()
		end
	end,
	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		local name = player:get_player_name()
		if minetest.is_protected(pos, name) then
			minetest.record_protection_violation(pos, name)
			return 0
		elseif to_list == "output" then
			return 0
		elseif from_list == "output" and to_list == "input" then
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			if inv:get_stack(to_list, to_index):is_empty() then
				return count
			else
				return 0
			end
		else
			return count
		end
	end,
	on_metadata_inventory_put = function(pos, listname, index, stack, player)
		local meta = minetest.get_meta(pos)
		update_grindstone_slots(meta)
	end,
	on_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		local meta = minetest.get_meta(pos)
		if from_list == "output" and to_list == "input" then
			local inv = meta:get_inventory()
			for i=1, inv:get_size("input") do
				if i ~= to_index then
					local istack = inv:get_stack("input", i)
					istack:set_count(math.max(0, istack:get_count() - count))
					inv:set_stack("input", i, istack)
				end
			end
		end
		update_grindstone_slots(meta)
	end,
	on_metadata_inventory_take = function(pos, listname, index, stack, player)
		local meta = minetest.get_meta(pos)
		if listname == "output" then
			local xp_earnt = 0
			local inv = meta:get_inventory()
			local input1 = inv:get_stack("input", 1)
			local input2 = inv:get_stack("input", 2)
			-- Both slots occupied?
			if not input1:is_empty() and not input2:is_empty() then
				-- Get xp earnt from the enchanted items
				xp_earnt = calculate_xp(input1) + calculate_xp(input1)
				input1:take_item()
				input2:take_item()
				inv:set_stack("input", 1, input1)
				inv:set_stack("input", 2, input2)
			else
				-- If only one input item
				if not input1:is_empty() then
					xp_earnt = calculate_xp(input1)
					input1:set_count(math.max(0, input1:get_count() - stack:get_count()))
					inv:set_stack("input", 1, input1)
				end
				if not input2:is_empty() then
					xp_earnt = calculate_xp(input2)
					input2:set_count(math.max(0, input2:get_count() - stack:get_count()))
					inv:set_stack("input", 2, input2)
				end
			end
			-- Give the player xp
			if mcl_experience.throw_xp and xp_earnt > 0 then
				mcl_experience.throw_xp(pos, xp_earnt)
			end
		elseif listname == "input" then
			update_grindstone_slots(meta)
		end
	end,

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		inv:set_size("input", 2)
		inv:set_size("output", 1)
		local form = get_grindstone_formspec()
		meta:set_string("formspec", form)
	end,
	on_rightclick = function(pos, node, player, itemstack)
		if not player:get_player_control().sneak then
			local meta = minetest.get_meta(pos)
			update_grindstone_slots(meta)
			meta:set_string("formspec", get_grindstone_formspec())
		end
	end,
	_mcl_blast_resistance = 6,
	_mcl_hardness = 2
})

minetest.register_craft({
	output = "mcl_grindstone:grindstone",
	recipe = {
		{ "mcl_core:stick", "mcl_stairs:slab_stone_rough", "mcl_core:stick"},
		{ "group:wood", "", "group:wood"},
	}
})
