mcl_info = {}
local refresh_interval      = .63
local huds                  = {}
local default_debug         = 0
local after                 = minetest.after
local get_connected_players = minetest.get_connected_players
local get_biome_name        = minetest.get_biome_name
local get_biome_data        = minetest.get_biome_data
local format                = string.format

local min1, min2, min3 = mcl_vars.mg_overworld_min, mcl_vars.mg_end_min, mcl_vars.mg_nether_min
local max1, max2, max3 = mcl_vars.mg_overworld_max, mcl_vars.mg_end_max, mcl_vars.mg_nether_max + 128

local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)
local S = minetest.get_translator(modname)
local storage = minetest.get_mod_storage()
local player_dbg = {}

local function check_setting(s)
	return s
end

--return player setting, set it to 2nd argument if supplied
local function player_setting(p,s)
	local name = p:get_player_name()
	if check_setting(s) then
		p:get_meta():set_string("mcl_info_show",s)
		player_dbg[name] = tonumber(s)
	end
	if not player_dbg[name] then
		local r = p:get_meta():get_string("mcl_info_show")
		if r == nil or r == "" then r = 0 end
		player_dbg[name] = tonumber(r)
	end
	return player_dbg[name]
end

mcl_info.registered_debug_fields = {}
local fields_keyset = {}
function mcl_info.register_debug_field(name,def)
	table.insert(fields_keyset,name)
	mcl_info.registered_debug_fields[name]=def
end

local function nodeinfo(pos)
	local n = minetest.get_node_or_nil(pos)
	if not n then return "" end
	local l = minetest.get_node_light(pos)
	local ld = minetest.get_node_light(pos,0.5)
	local r = n.name .. " p1:"..n.param1.." p2:"..n.param2
	if l and ld then
		r = r .. " Light: "..l.."/"..ld
	end
	return r
end

local function get_text(player, bits)
	local pos = vector.offset(player:get_pos(),0,0.5,0)
	local bits = bits
	if bits == 0 then return "" end

	local r = ""
	for _,key in ipairs(fields_keyset) do
		local def = mcl_info.registered_debug_fields[key]
		if def.level == nil or def.level <= bits then
			r = r ..key..": "..tostring(def.func(player,pos)).."\n"
		end
	end

	return r
end

local function info()
	for _, player in pairs(get_connected_players()) do
		local name = player:get_player_name()
		local s = player_setting(player)
		local pos = player:get_pos()
		local text = get_text(player, s)
		local hud = huds[name]
		if s and not hud then
			local def = {
				hud_elem_type = "text",
				alignment     = {x = 1, y = -1},
				scale         = {x = 100, y = 100},
				position      = {x = 0.0073, y = 0.889},
				text          = text,
				style         = 5,
				["number"]    = 0xcccac0,
				z_index       = 0,
			}
			local def_bg = table.copy(def)
			def_bg.offset = {x = 2, y = 1}
			def_bg["number"] = 0
			def_bg.z_index = -1
			huds[name] = {
				player:hud_add(def),
				player:hud_add(def_bg),
				text,
			}
		elseif text ~= hud[3] then
			hud[3] = text
			player:hud_change(huds[name][1], "text", text)
			player:hud_change(huds[name][2], "text", text)
		end
	end
	after(refresh_interval, info)
end
minetest.after(0,info)

minetest.register_on_leaveplayer(function(p)
	local name = p:get_player_name()
	huds[name] = nil
	player_dbg[name] = nil
end)

minetest.register_chatcommand("debug",{
	description = S("Set debug bit mask: 0 = disable, 1 = biome name, 2 = coordinates, 3 = all"),
	params = S("<bitmask>"),
	privs = { debug = true },
	func = function(name, params)
		local player = minetest.get_player_by_name(name)
		if params == "" then return true, "Debug bitmask is "..player_setting(player) end
		local dbg = math.floor(tonumber(params) or default_debug)
		if dbg < 0 or dbg > 4 then
			minetest.chat_send_player(name, S("Error! Possible values are integer numbers from @1 to @2", 0, 4))
			return false,"Current bitmask: "..player_setting(player)
		end
		return true, "Debug bit mask set to "..player_setting(player,dbg)
	end
})

mcl_info.register_debug_field("Node feet",{
	level = 4,
	func = function(pl,pos)
		return nodeinfo(pos)
	end
})
mcl_info.register_debug_field("Node below",{
	level = 4,
	func = function(pl,pos)
		return nodeinfo(vector.offset(pos,0,-1,0))
	end
})
mcl_info.register_debug_field("Biome",{
	level = 3,
	func = function(pl,pos)
		local biome_data = get_biome_data(pos)
		local biome = biome_data and get_biome_name(biome_data.biome) or "No biome"
		if biome_data then
			return format("%s (%s), Humidity: %.1f, Temperature: %.1f",biome, biome_data.biome, biome_data.humidity, biome_data.heat)
		end
		return "No biome"
	end
})
mcl_info.register_debug_field("Coords",{
	level = 2,
	func = function(pl,pos)
		return format("x:%.1f y:%.1f z:%.1f", pos.x, pos.y, pos.z)
	end
})
