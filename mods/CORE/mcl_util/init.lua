mcl_util = {}

-- Updates all values in t using values from to*.
function table.update(t, ...)
	for _, to in ipairs{...} do
		for k,v in pairs(to) do
			t[k] = v
		end
	end
	return t
end

-- Updates nil values in t using values from to*.
function table.update_nil(t, ...)
	for _, to in ipairs{...} do
		for k,v in pairs(to) do
			if t[k] == nil then
				t[k] = v
			end
		end
	end
	return t
end

-- Based on minetest.rotate_and_place

--[[
Attempt to predict the desired orientation of the pillar-like node
defined by `itemstack`, and place it accordingly in one of 3 possible
orientations (X, Y or Z).

Stacks are handled normally if the `infinitestacks`
field is false or omitted (else, the itemstack is not changed).
* `invert_wall`: if `true`, place wall-orientation on the ground and ground-
  orientation on wall

This function is a simplified version of minetest.rotate_and_place.
The Minetest function is seen as inappropriate because this includes mirror
images of possible orientations, causing problems with pillar shadings.
]]
function mcl_util.rotate_axis_and_place(itemstack, placer, pointed_thing, infinitestacks, invert_wall)
	local unode = minetest.get_node_or_nil(pointed_thing.under)
	if not unode then
		return
	end
	local undef = minetest.registered_nodes[unode.name]
	if undef and undef.on_rightclick then
		undef.on_rightclick(pointed_thing.under, unode, placer,
				itemstack, pointed_thing)
		return
	end
	local fdir = minetest.dir_to_facedir(placer:get_look_dir())
	local wield_name = itemstack:get_name()

	local above = pointed_thing.above
	local under = pointed_thing.under
	local is_x = (above.x ~= under.x)
	local is_y = (above.y ~= under.y)
	local is_z = (above.z ~= under.z)

	local anode = minetest.get_node_or_nil(above)
	if not anode then
		return
	end
	local pos = pointed_thing.above
	local node = anode

	if undef and undef.buildable_to then
		pos = pointed_thing.under
		node = unode
	end

	if minetest.is_protected(pos, placer:get_player_name()) then
		minetest.record_protection_violation(pos, placer:get_player_name())
		return
	end

	local ndef = minetest.registered_nodes[node.name]
	if not ndef or not ndef.buildable_to then
		return
	end

	local p2
	if is_y then
		if invert_wall then
			if fdir == 3 or fdir == 1 then
				p2 = 12
			else
				p2 = 6
			end
		end
	elseif is_x then
		if invert_wall then
			p2 = 0
		else
			p2 = 12
		end
	elseif is_z then
		if invert_wall then
			p2 = 0
		else
			p2 = 6
		end
	end
	minetest.set_node(pos, {name = wield_name, param2 = p2})

	if not infinitestacks then
		itemstack:take_item()
		return itemstack
	end
end

-- Wrapper of above function for use as `on_place` callback (Recommended).
-- Similar to minetest.rotate_node.
function mcl_util.rotate_axis(itemstack, placer, pointed_thing)
	mcl_util.rotate_axis_and_place(itemstack, placer, pointed_thing,
		minetest.is_creative_enabled(placer:get_player_name()),
		placer:get_player_control().sneak)
	return itemstack
end

-- Returns position of the neighbor of a double chest node
-- or nil if node is invalid.
-- This function assumes that the large chest is actually intact
-- * pos: Position of the node to investigate
-- * param2: param2 of that node
-- * side: Which "half" the investigated node is. "left" or "right"
function mcl_util.get_double_container_neighbor_pos(pos, param2, side)
	if side == "right" then
		if param2 == 0 then
			return {x=pos.x-1, y=pos.y, z=pos.z}
		elseif param2 == 1 then
			return {x=pos.x, y=pos.y, z=pos.z+1}
		elseif param2 == 2 then
			return {x=pos.x+1, y=pos.y, z=pos.z}
		elseif param2 == 3 then
			return {x=pos.x, y=pos.y, z=pos.z-1}
		end
	else
		if param2 == 0 then
			return {x=pos.x+1, y=pos.y, z=pos.z}
		elseif param2 == 1 then
			return {x=pos.x, y=pos.y, z=pos.z-1}
		elseif param2 == 2 then
			return {x=pos.x-1, y=pos.y, z=pos.z}
		elseif param2 == 3 then
			return {x=pos.x, y=pos.y, z=pos.z+1}
		end
	end
end

-- Iterates through all items in the given inventory and
-- returns the slot of the first item which matches a condition.
-- Returns nil if no item was found.
--- source_inventory: Inventory to take the item from
--- source_list: List name of the source inventory from which to take the item
--- destination_inventory: Put item into this inventory
--- destination_list: List name of the destination inventory to which to put the item into
--- condition: Function which takes an itemstack and returns true if it matches the desired item condition.
---            If set to nil, the slot of the first item stack will be taken unconditionally.
-- dst_inventory and dst_list can also be nil if condition is nil.
function mcl_util.get_eligible_transfer_item_slot(src_inventory, src_list, dst_inventory, dst_list, condition)
	local size = src_inventory:get_size(src_list)
	local stack
	for i=1, size do
		stack = src_inventory:get_stack(src_list, i)
		if not stack:is_empty() and (condition == nil or condition(stack, src_inventory, src_list, dst_inventory, dst_list)) then
			return i
		end
	end
	return nil
end

-- Returns true if itemstack is a shulker box
local function is_not_shulker_box(itemstack)
	local g = minetest.get_item_group(itemstack:get_name(), "shulker_box")
	return g == 0 or g == nil
end

-- Moves a single item from one inventory to another.
--- source_inventory: Inventory to take the item from
--- source_list: List name of the source inventory from which to take the item
--- source_stack_id: The inventory position ID of the source inventory to take the item from (-1 for first occupied slot)
--- destination_inventory: Put item into this inventory
--- destination_list: List name of the destination inventory to which to put the item into

-- Returns true on success and false on failure
-- Possible failures: No item in source slot, destination inventory full
function mcl_util.move_item(source_inventory, source_list, source_stack_id, destination_inventory, destination_list)
	if source_stack_id == -1 then
		source_stack_id = mcl_util.get_first_occupied_inventory_slot(source_inventory, source_list)
		if source_stack_id == nil then
			return false
		end
	end

	if not source_inventory:is_empty(source_list) then
		local stack = source_inventory:get_stack(source_list, source_stack_id)
		if not stack:is_empty() then
			local new_stack = ItemStack(stack)
			new_stack:set_count(1)
			if not destination_inventory:room_for_item(destination_list, new_stack) then
				return false
			end
			stack:take_item()
			source_inventory:set_stack(source_list, source_stack_id, stack)
			destination_inventory:add_item(destination_list, new_stack)
			return true
		end
	end
	return false
end

-- Moves a single item from one container node into another. Performs a variety of high-level
-- checks to prevent invalid transfers such as shulker boxes into shulker boxes
--- source_pos: Position ({x,y,z}) of the node to take the item from
--- destination_pos: Position ({x,y,z}) of the node to put the item into
--- source_list (optional): List name of the source inventory from which to take the item. Default is normally "main"; "dst" for furnace
--- source_stack_id (optional): The inventory position ID of the source inventory to take the item from (-1 for slot of the first valid item; -1 is default)
--- destination_list (optional): List name of the destination inventory. Default is normally "main"; "src" for furnace
-- Returns true on success and false on failure.
function mcl_util.move_item_container(source_pos, destination_pos, source_list, source_stack_id, destination_list)
	local dpos = table.copy(destination_pos)
	local spos = table.copy(source_pos)
	local snode = minetest.get_node(spos)
	local dnode = minetest.get_node(dpos)

	local dctype = minetest.get_item_group(dnode.name, "container")
	local sctype = minetest.get_item_group(snode.name, "container")

	-- Container type 7 does not allow any movement
	if sctype == 7 then
		return false
	end

	-- Normalize double container by forcing to always use the left segment first
	local function normalize_double_container(pos, node, ctype)
		if ctype == 6 then
			pos = mcl_util.get_double_container_neighbor_pos(pos, node.param2, "right")
			if not pos then
				return false
			end
			node = minetest.get_node(pos)
			ctype = minetest.get_item_group(node.name, "container")
			-- The left segment seems incorrect? We better bail out!
			if ctype ~= 5 then
				return false
			end
		end
		return pos, node, ctype
	end

	spos, snode, sctype = normalize_double_container(spos, snode, sctype)
	dpos, dnode, dctype = normalize_double_container(dpos, dnode, dctype)
	if not spos or not dpos then return false end

	local smeta = minetest.get_meta(spos)
	local dmeta = minetest.get_meta(dpos)

	local sinv = smeta:get_inventory()
	local dinv = dmeta:get_inventory()

	-- Default source lists
	if not source_list then
		-- Main inventory for most container types
		if sctype == 2 or sctype == 3 or sctype == 5 or sctype == 6 or sctype == 7 then
			source_list = "main"
		-- Furnace: output
		elseif sctype == 4 then
			source_list = "dst"
		-- Unknown source container type. Bail out
		else
			return false
		end
	end

	-- Automatically select stack slot ID if set to automatic
	if not source_stack_id then
		source_stack_id = -1
	end
	if source_stack_id == -1 then
		local cond = nil
		-- Prevent shulker box inception
		if dctype == 3 then
			cond = is_not_shulker_box
		end
		source_stack_id = mcl_util.get_eligible_transfer_item_slot(sinv, source_list, dinv, dpos, cond)
		if not source_stack_id then
			-- Try again if source is a double container
			if sctype == 5 then
				spos = mcl_util.get_double_container_neighbor_pos(spos, snode.param2, "left")
				smeta = minetest.get_meta(spos)
				sinv = smeta:get_inventory()

				source_stack_id = mcl_util.get_eligible_transfer_item_slot(sinv, source_list, dinv, dpos, cond)
				if not source_stack_id then
					return false
				end
			else
				return false
			end
		end
	end

	-- Abort transfer if shulker box wants to go into shulker box
	if dctype == 3 then
		local stack = sinv:get_stack(source_list, source_stack_id)
		if stack and minetest.get_item_group(stack:get_name(), "shulker_box") == 1 then
			return false
		end
	end
	-- Container type 7 does not allow any placement
	if dctype == 7 then
		return false
	end

	-- If it's a container, put it into the container
	if dctype ~= 0 then
		-- Automatically select a destination list if omitted
		if not destination_list then
			-- Main inventory for most container types
			if dctype == 2 or dctype == 3 or dctype == 5 or dctype == 6 or dctype == 7 then
				destination_list = "main"
			-- Furnace source slot
			elseif dctype == 4 then
				destination_list = "src"
			end
		end
		if destination_list then
			-- Move item
			local ok = mcl_util.move_item(sinv, source_list, source_stack_id, dinv, destination_list)

			-- Try transfer to neighbor node if transfer failed and double container
			if not ok and dctype == 5 then
				dpos = mcl_util.get_double_container_neighbor_pos(dpos, dnode.param2, "left")
				dmeta = minetest.get_meta(dpos)
				dinv = dmeta:get_inventory()

				ok = mcl_util.move_item(sinv, source_list, source_stack_id, dinv, destination_list)
			end

			-- Update furnace
			if ok and dctype == 4 then
				-- Start furnace's timer function, it will sort out whether furnace can burn or not.
				minetest.get_node_timer(dpos):start(1.0)
			end

			return ok
		end
	end
	return false
end

-- Returns the ID of the first non-empty slot in the given inventory list
-- or nil, if inventory is empty.
function mcl_util.get_first_occupied_inventory_slot(inventory, listname)
	return mcl_util.get_eligible_transfer_item_slot(inventory, listname)
end

local function drop_item_stack(pos, stack)
	if not stack or stack:is_empty() then return end
	local drop_offset = vector.new(math.random() - 0.5, 0, math.random() - 0.5)
	minetest.add_item(vector.add(pos, drop_offset), stack)
end

function mcl_util.drop_items_from_meta_container(listname)
	return function(pos, oldnode, oldmetadata)
		if oldmetadata and oldmetadata.inventory then
			-- process in after_dig_node callback
			local main = oldmetadata.inventory.main
			if not main then return end
			for _, stack in pairs(main) do
				drop_item_stack(pos, stack)
			end
		else
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			for i = 1, inv:get_size("main") do
				drop_item_stack(pos, inv:get_stack("main", i))
			end
			meta:from_table()
		end
	end
end

-- Returns true if item (itemstring or ItemStack) can be used as a furnace fuel.
-- Returns false otherwise
function mcl_util.is_fuel(item)
	return minetest.get_craft_result({method="fuel", width=1, items={item}}).time ~= 0
end

-- Returns a on_place function for plants
-- * condition: function(pos, node, itemstack)
--    * A function which is called by the on_place function to check if the node can be placed
--    * Must return true, if placement is allowed, false otherwise.
--    * If it returns a string, placement is allowed, but will place this itemstring as a node instead
--    * pos, node: Position and node table of plant node
--    * itemstack: Itemstack to place
function mcl_util.generate_on_place_plant_function(condition)
	return function(itemstack, placer, pointed_thing)
		if pointed_thing.type ~= "node" then
			-- no interaction possible with entities
			return itemstack
		end

		-- Call on_rightclick if the pointed node defines it
		local node = minetest.get_node(pointed_thing.under)
		if placer and not placer:get_player_control().sneak then
			if minetest.registered_nodes[node.name] and minetest.registered_nodes[node.name].on_rightclick then
				return minetest.registered_nodes[node.name].on_rightclick(pointed_thing.under, node, placer, itemstack) or itemstack
			end
		end

		local place_pos
		local def_under = minetest.registered_nodes[minetest.get_node(pointed_thing.under).name]
		local def_above = minetest.registered_nodes[minetest.get_node(pointed_thing.above).name]
		if not def_under or not def_above then
			return itemstack
		end
		if def_under.buildable_to then
			place_pos = pointed_thing.under
		elseif def_above.buildable_to then
			place_pos = pointed_thing.above
		else
			return itemstack
		end

		-- Check placement rules
		local result, param2 = condition(place_pos, node, itemstack)
		if result == true then
			local idef = itemstack:get_definition()
			local new_itemstack, success = minetest.item_place_node(itemstack, placer, pointed_thing, param2)

			if success then
				if idef.sounds and idef.sounds.place then
					minetest.sound_play(idef.sounds.place, {pos=pointed_thing.above, gain=1}, true)
				end
			end
			itemstack = new_itemstack
		end

		return itemstack
	end
end

-- adjust the y level of an object to the center of its collisionbox
-- used to get the origin position of entity explosions
function mcl_util.get_object_center(obj)
	local collisionbox = obj:get_properties().collisionbox
	local pos = obj:get_pos()
	local ymin = collisionbox[2]
	local ymax = collisionbox[5]
	pos.y = pos.y + (ymax - ymin) / 2.0
	return pos
end

function mcl_util.get_color(colorstr)
	local mc_color = mcl_colors[colorstr:upper()]
	if mc_color then
		colorstr = mc_color
	elseif #colorstr ~= 7 or colorstr:sub(1, 1) ~= "#" then
		return
	end
	local hex = tonumber(colorstr:sub(2, 7), 16)
	if hex then
		return colorstr, hex
	end
end

function mcl_util.call_on_rightclick(itemstack, player, pointed_thing)
	-- Call on_rightclick if the pointed node defines it
	if pointed_thing and pointed_thing.type == "node" then
		local pos = pointed_thing.under
		local node = minetest.get_node(pos)
		if player and not player:get_player_control().sneak then
			local nodedef = minetest.registered_nodes[node.name]
			local on_rightclick = nodedef and nodedef.on_rightclick
			if on_rightclick then
				return on_rightclick(pos, node, player, itemstack, pointed_thing) or itemstack
			end
		end
	end
end

function mcl_util.calculate_durability(itemstack)
	local unbreaking_level = mcl_enchanting.get_enchantment(itemstack, "unbreaking")
	local armor_uses = minetest.get_item_group(itemstack:get_name(), "mcl_armor_uses")

	local uses

	if armor_uses > 0 then
		uses = armor_uses
		if unbreaking_level > 0 then
			uses = uses / (0.6 + 0.4 / (unbreaking_level + 1))
		end
	else
		local def = itemstack:get_definition()
		if def then
			local fixed_uses = def._mcl_uses
			if fixed_uses then
				uses = fixed_uses
				if unbreaking_level > 0 then
					uses = uses * (unbreaking_level + 1)
				end
			end
		end

		local _, groupcap = next(itemstack:get_tool_capabilities().groupcaps)
		uses = uses or (groupcap or {}).uses
	end

	return uses or 0
end

function mcl_util.use_item_durability(itemstack, n)
	local uses = mcl_util.calculate_durability(itemstack)
	itemstack:add_wear(65535 / uses * n)
end

function mcl_util.deal_damage(target, damage, mcl_reason)
	local luaentity = target:get_luaentity()

	if luaentity then
		if luaentity.deal_damage then
			luaentity:deal_damage(damage, mcl_reason or {type = "generic"})
			return
		elseif luaentity.is_mob then
			-- local puncher = mcl_reason and mcl_reason.direct or target
			-- target:punch(puncher, 1.0, {full_punch_interval = 1.0, damage_groups = {fleshy = damage}}, vector.direction(puncher:get_pos(), target:get_pos()), damage)
			if luaentity.health > 0 then
				luaentity.health = luaentity.health - damage
			end
			return
		end
	end

	local hp = target:get_hp()

	if hp > 0 then
		target:set_hp(hp - damage, {_mcl_reason = mcl_reason})
	end
end

function mcl_util.get_hp(obj)
	local luaentity = obj:get_luaentity()

	if luaentity and luaentity.is_mob then
		return luaentity.health
	else
		return obj:get_hp()
	end
end

function mcl_util.get_inventory(object, create)
	if object:is_player() then
		return object:get_inventory()
	else
		local luaentity = object:get_luaentity()
		local inventory = luaentity.inventory

		if create and not inventory and luaentity.create_inventory then
			inventory = luaentity:create_inventory()
		end

		return inventory
	end
end

function mcl_util.get_wielded_item(object)
	if object:is_player() then
		return object:get_wielded_item()
	else
		-- ToDo: implement getting wielditems from mobs as soon as mobs have wielditems
		return ItemStack()
	end
end

function mcl_util.get_object_name(object)
	if object:is_player() then
		return object:get_player_name()
	else
		local luaentity = object:get_luaentity()

		if not luaentity then
			return tostring(object)
		end

		return luaentity.nametag and luaentity.nametag ~= "" and luaentity.nametag or luaentity.description or luaentity.name
	end
end

function mcl_util.replace_mob(obj, mob)
	local rot = obj:get_yaw()
	local pos = obj:get_pos()
	obj:remove()
	obj = minetest.add_entity(pos, mob)
	obj:set_yaw(rot)
	return obj
end

function mcl_util.get_pointed_thing(player, liquid)
	local pos = vector.offset(player:get_pos(), 0, player:get_properties().eye_height, 0)
	local look_dir = vector.multiply(player:get_look_dir(), 5)
	local pos2 = vector.add(pos, look_dir)
	local ray = minetest.raycast(pos, pos2, false, liquid)

	if ray then
		for pointed_thing in ray do
			return pointed_thing
		end
	end
end
