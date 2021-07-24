mcl_item_id = {
    mod_namespaces = {},
}

local game = "mineclone"

function mcl_item_id.set_mod_namespace(modname, namespace)
    local namespace = namespace or modname
    mcl_item_id.mod_namespaces[modname] = namespace
    minetest.register_on_mods_loaded(function()
        for item, def in pairs(minetest.registered_items) do
            local item_split = item:find(":")
            if item_split then
                local id_modname = item:sub(1, item_split - 1)
                local id_string = item:sub(item_split)
                if id_modname == modname and modname ~= namespace then
                    minetest.register_alias_force(namespace .. id_string, item)
                end
            end
        end
    end)
end

function mcl_item_id.get_mod_namespace(modname)
    local namespace = mcl_item_id.mod_namespaces[modname]
    if namespace then
        return namespace
    else
        return game
    end
end

local same_id = {
    enchanting = { "table" },
    experience = { "bottle" },
    heads = { "skeleton", "zombie", "creeper", "wither_skeleton" },
    mobitems = { "rabbit", "chicken" },
    walls = {
        "andesite", "brick", "cobble", "diorite", "endbricks",
        "granite", "mossycobble", "netherbrick", "prismarine",
        "rednetherbrick", "redsandstone", "sandstone", 
        "stonebrick", "stonebrickmossy", 
    },
    wool = {
        "black", "blue", "brown", "cyan", "green",
        "grey", "light_blue", "lime", "magenta", "orange",
        "pink", "purple", "red", "silver", "white", "yellow",
    },
}

tt.register_snippet(function(itemstring)
    local def = minetest.registered_items[itemstring]
    local item_split = itemstring:find(":")
    local id_string = itemstring:sub(item_split)
    local id_modname = itemstring:sub(1, item_split - 1)
    local new_id = game .. id_string
    local mod_namespace = mcl_item_id.get_mod_namespace(id_modname)
    for mod, ids in pairs(same_id) do
        for _, id in pairs(ids) do
            if itemstring == "mcl_" .. mod .. ":" .. id  then
                new_id = game .. ":" .. id .. "_" .. mod:gsub("s", "")
            end
        end
    end
    if mod_namespace ~= game then
        new_id = mod_namespace .. id_string
    else
        minetest.register_alias_force(new_id, itemstring)
    end
    if minetest.settings:get_bool("mcl_item_id_debug", false) then
        return new_id, "#555555"
    end
end)