function tigris.mobs.register_spawn(mob, def)
    minetest.register_abm({
        nodenames = def.nodes,
        neighbors = {"air"},
        interval = 30,
        chance = def.chance,
        label = mob,

        action = function(pos, node, _, all_count)
            if all_count > 32 then
                return
            end

            local ml = minetest.registered_entities[mob].mob_def.level
            local dl = tigris.danger_level(pos)

            if ml > dl then
                return
            end

            pos.y = pos.y + 1

            local function cn(pos)
                if pos.y > def.ymax or pos.y < def.ymin then
                    return false
                end

                if minetest.is_protected(pos, "") then
                    return false
                end

                local light = minetest.get_node_light(pos)
                if not light or light > def.light_max or light < def.light_min then
                    return false
                end

                local rn = minetest.registered_nodes[minetest.get_node(pos).name]
                if rn.walkable then
                    return false
                end

                return true
            end

            if not cn(pos) then
                pos.y = pos.y + 1
                if not cn(pos) then
                    pos.y = pos.y + 1
                    if not cn(pos) then
                        pos.y = pos.y + 1
                        if not cn(pos) then
                            return
                        end
                    end
                end
            end

            local obj = tigris.mobs.spawn(mob, pos)
            if obj then
                minetest.log("Spawned " .. mob .. " at " .. minetest.pos_to_string(pos) .. " level " .. ml .. " <= " .. dl)
            else
                minetest.log("Failed to spawn " .. mob .. " at " .. minetest.pos_to_string(pos))
            end
        end,
    })
end
