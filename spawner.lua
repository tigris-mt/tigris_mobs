minetest.register_node("tigris_mobs:spawner", {
    description = "Mob Spawner",
    tiles = {"tigris_mobs_spawner.png"},
    drawtype = "glasslike",
    light_source = 5,
    paramtype = "light",
    sunlight_propagates = true,
    sounds = default.node_sound_metal_defaults(),
    groups = {cracky = 1, level = 2},
    drop = "",
    on_timer = function(pos)
        local n = 0
        for _,obj in ipairs(minetest.get_objects_inside_radius(pos, 6)) do
            if obj:get_luaentity() and obj:get_luaentity().tigris_mob then
                n = n + 1
            end
        end
        if n > 6 then
            return true
        end

        local meta = minetest.get_meta(pos)
        local mob = meta:get_string("mob")
        local function try(a)
            for x=pos.x-2*a,pos.x+2*a do
            for y=pos.y-a,pos.y+a do
            for z=pos.z-2*a,pos.z+2*a do
                local pos = vector.new(x, y, z)
                local ok = true
                for i=0,1 do
                    if minetest.get_node(vector.add(pos, vector.new(0, i, 0))).name ~= "air" then
                        ok = false
                    end
                end
                if ok then
                    local obj = tigris.mobs.spawn(mob, pos)
                    if obj then
                        minetest.log("Spawned spawner " .. mob .. " at " .. minetest.pos_to_string(pos))
                        return true
                    end
                end
            end
            end
            end
            return false
        end
        if not try(1) and not try(2) then
            minetest.log("Failed to spawn spawner " .. mob .. " from " .. minetest.pos_to_string(pos))
        end
        minetest.get_node_timer(pos):start(math.random(10, 40))
        return false
    end,
    on_construct = function(pos)
        tigris.mobs.set_spawner(pos, "tigris_mobs:rat")
    end,
})

function tigris.mobs.set_spawner(pos, mob)
    local meta = minetest.get_meta(pos)
    meta:set_string("mob", mob)
    minetest.get_node_timer(pos):start(1)
end

local function is_type(node, min, max)
    return #minetest.find_nodes_in_area_under_air(min, max, {node}) > 5
end

local function random_mob(pos, min, max)
    local l = {
        "tigris_mobs:dirt_shambler",
    }
    if pos.y < -1000 then
        table.insert(l, "tigris_mobs:mese_shambler")
    end
    if is_type(minetest.registered_aliases["mapgen_sandstonebrick"], min, max) then
        table.insert(l, "tigris_mobs:sand_shambler")
    elseif is_type(minetest.registered_aliases["mapgen_desert_stone"], min, max) then
        table.insert(l, "tigris_mobs:sand_shambler")
    else
        table.insert(l, "tigris_mobs:stone_shambler")
    end
    return l[math.random(#l)]
end

local function place_spawner(tab, min, max)
    for _,pos in ipairs(tab) do
        pos.y = pos.y - 4
        local ok = false
        for i=0,4 do
            if not ok then
                pos.y = pos.y + i
                if minetest.get_node(pos).name ~= "air" then
                    if minetest.get_node(vector.add(pos, vector.new(0, 1, 0))).name == "air" then
                        pos.y = pos.y + 1
                        ok = true
                    end
                end
            end
        end
        if ok then
            minetest.set_node(pos, {name = "tigris_mobs:spawner"})
            tigris.mobs.set_spawner(pos, random_mob(pos, min, max))
            return
        end
    end
end

minetest.set_gen_notify({dungeon = true, temple = true})
minetest.register_on_generated(function(min, max)
    local ntf = minetest.get_mapgen_object("gennotify")
    if ntf and ntf.dungeon and #ntf.dungeon > 0 then
        minetest.after(1, place_spawner, table.copy(ntf.dungeon), min, max)
    end
end)
