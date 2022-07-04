local get_connected_players = minetest.get_connected_players

mcl_weather.snow = {}

local PARTICLES_COUNT_SNOW = tonumber(minetest.settings:get("mcl_weather_snow_particles")) or 99
mcl_weather.snow.init_done = false

local psdef= {
	amount = PARTICLES_COUNT_SNOW,
	time = 0, --stay on til we turn it off
	minpos = vector.new(-25,20,-25),
	maxpos =vector.new(25,25,25),
	minvel = vector.new(-0.2,-1,-0.2),
	maxvel = vector.new(0.2,-4,0.2),
	minacc = vector.new(0,-1,0),
	maxacc = vector.new(0,-4,0),
	minexptime = 3,
	maxexptime = 5,
	minsize = 2,
	maxsize = 5,
	collisiondetection = true,
	collision_removal = true,
	object_collision = true,
	vertical = true,
	glow = 1
}

function mcl_weather.snow.set_sky_box()
	mcl_weather.skycolor.add_layer(
		"weather-pack-snow-sky",
		{{r=0, g=0, b=0},
		{r=85, g=86, b=86},
		{r=135, g=135, b=135},
		{r=85, g=86, b=86},
		{r=0, g=0, b=0}})
	mcl_weather.skycolor.active = true
	for _, player in pairs(get_connected_players()) do
		player:set_clouds({color="#ADADADE8"})
	end
	mcl_weather.skycolor.active = true
end

function mcl_weather.snow.clear()
	mcl_weather.skycolor.remove_layer("weather-pack-snow-sky")
	mcl_weather.snow.init_done = false
	mcl_weather.remove_all_spawners()
end

-- Simple random texture getter
function mcl_weather.snow.get_texture()
	return "weather_pack_snow_snowflake"..math.random(1,2)..".png"
end

local timer = 0
minetest.register_globalstep(function(dtime)
	if mcl_weather.state ~= "snow" then
		return false
	end

	timer = timer + dtime;
	if timer >= 0.5 then
		timer = 0
	else
		return
	end

	if mcl_weather.snow.init_done == false then
		mcl_weather.snow.set_sky_box()
		mcl_weather.snow.init_done = true
	end

	for _, player in pairs(get_connected_players()) do
		if mcl_weather.is_underwater(player) or not mcl_worlds.has_weather(player:get_pos()) then
			mcl_weather.remove_spawners_player(player)
		else
			for i=1,2 do
				psdef.texture="weather_pack_snow_snowflake"..i..".png"
				mcl_weather.add_spawner_player(player,"snow"..i,psdef)
			end
		end
	end
end)

-- register snow weather
if mcl_weather.reg_weathers.snow == nil then
	mcl_weather.reg_weathers.snow = {
		clear = mcl_weather.snow.clear,
		light_factor = 0.6,
		-- 10min - 20min
		min_duration = 600,
		max_duration = 1200,
		transitions = {
			[65] = "none",
			[80] = "rain",
			[100] = "thunder",
		}
	}
end
