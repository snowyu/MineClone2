-- Liquids: River Water

local source = table.copy(minetest.registered_nodes["mcl_core:water_source"])
source.description = "Still River Water"
source.liquid_range = 2
source.liquid_alternative_flowing = "mclx_core:river_water_flowing"
source.liquid_alternative_source = "mclx_core:river_water_source"
source.liquid_renewable = false
source._doc_items_longdesc = "River water has the same properties as water, but has a reduced flowing distance and is not renewable."
source._doc_items_entry_name = "River Water"
-- Auto-expose entry only in valleys mapgen
source._doc_items_hidden = minetest.get_mapgen_setting("mg_name") ~= "valleys"
source.post_effect_color = {a=204, r=0x2c, g=0x88, b=0x8c}
source.tiles = {
	{name="default_river_water_source_animated.png", animation={type="vertical_frames", aspect_w=16, aspect_h=16, length=5.0}}
}
source.special_tiles = {
	-- New-style water source material (mostly unused)
	{
		name="default_river_water_source_animated.png",
		animation={type="vertical_frames", aspect_w=16, aspect_h=16, length=5.0},
		backface_culling = false,
	}
}

local flowing = table.copy(minetest.registered_nodes["mcl_core:water_flowing"])
flowing.description = "Flowing River Water"
flowing.liquid_range = 2
flowing.liquid_alternative_flowing = "mclx_core:river_water_flowing"
flowing.liquid_alternative_source = "mclx_core:river_water_source"
flowing.liquid_renewable = false
flowing.tiles = {"default_river_water_flowing_animated.png^[verticalframe:64:0"}
flowing.post_effect_color = {a=204, r=0x2c, g=0x88, b=0x8c}
flowing.special_tiles = {
	{
		image="default_river_water_flowing_animated.png",
		backface_culling=false,
		animation={type="vertical_frames", aspect_w=16, aspect_h=16, length=4.0}
	},
	{
		image="default_river_water_flowing_animated.png",
		backface_culling=true,
		animation={type="vertical_frames", aspect_w=16, aspect_h=16, length=4.0}
	},
}

minetest.register_node("mclx_core:river_water_source", source)
minetest.register_node("mclx_core:river_water_flowing", flowing)

if minetest.get_modpath("doc") then
	doc.add_entry_alias("nodes", "mclx_core:river_water_source", "nodes", "mclx_core:river_water_flowing")
end
