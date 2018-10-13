local function register(name, def)
    table.insert(def.drops, {5, "tigris_mobs:cursed_brain"})

    tigris.mobs.register(name, {
        description = def.desc,
        collision = {-0.4, 0, -0.4, 0.4, 2, 0.4},
        box = {
            {-0.4, 1, -0.4, 0.4, 2, 0.4},
            {-0.4, 0, -0.1, -0.3, 1, 0.1},
            {0.3, 0, -0.1, 0.4, 1, 0.1},
        },
        textures = {
            def.texture,
            def.texture,
            def.texture,
            def.texture,
            def.texture,
            def.texture .. "^tigris_mobs_shambler_face.png",
        },

        group = "hunters",
        level = def.level,

        drops = def.drops,
        armor = def.armor,

        habitat_nodes = def.nodes,

        on_init = function(self, data)
            self.hp_max = 6 * def.strength
            data.jump = 5
            data.speed = 3
            data.fast_speed = 3
            data.damage = def.damage
            data.regen = 5
            data.drown = def.drown or false
            data.node_damage = def.node_damage or false
        end,

        start = "wander",
        script = tigris.mobs.common.hunter(),
    })

    tigris.mobs.register_spawn(name, {
        ymax = def.underground and (def.ymax or 0) or tigris.world_limits.max.y,
        ymin = def.underground and tigris.world_limits.min.y or (def.ymin or -24),

        light_min = 0,
        light_max = def.light,

        chance = def.chance,

        nodes = def.nodes,
    })
end

register("tigris_mobs:sand_shambler", {
    desc = "Sand Shambler",
    nodes = {"group:sand"},
    texture = "default_sand.png",
    underground = false,
    light = minetest.LIGHT_MAX,
    damage = {fleshy = 2, heat = 1},
    level = 2,
    chance = 5000,
    strength = 1,
    armor = {fleshy = 100, heat = 30},
    drops = {
        {80, "default:sand"},
        {50, "default:sand"},
        {40, "default:desert_sand"},
        {40, "default:desert_sand"},
    },
    drown = 1,
    node_damage = true,
})

register("tigris_mobs:dirt_shambler", {
    desc = "Dirt Shambler",
    nodes = {"group:soil"},
    texture = "default_dirt.png",
    underground = false,
    light = minetest.LIGHT_MAX / 2,
    damage = {fleshy = 2},
    level = 2,
    chance = 7000,
    strength = 1,
    drops = {
        {80, "default:dirt"},
        {50, "default:dirt 2"},
    },
    drown = 1,
    node_damage = true,
})

register("tigris_mobs:ice_shambler", {
    desc = "Ice Shambler",
    nodes = {"default:ice", "default:snow", "default:snowblock"},
    texture = "default_ice.png",
    underground = false,
    light = minetest.LIGHT_MAX,
    damage = {fleshy = 1, cold = 3},
    level = 2,
    chance = 5000,
    strength = 0.75,
    armor = {fleshy = 75, cold = 15},
    drops = {
        {50, "default:ice 2"},
        {25, "default:snow 6"},
        {25, "default:snowblock"},
    },
    node_damage = true,
})

register("tigris_mobs:stone_shambler", {
    desc = "Stone Shambler",
    nodes = {"group:stone"},
    texture = "default_stone.png",
    underground = true,
    light = minetest.LIGHT_MAX / 2,
    damage = {fleshy = 4},
    level = 3,
    chance = 8000,
    strength = 2,
    armor = {fleshy = 50, cold = 50, heat = 50},
    drops = {
        {80, "default:stone"},
        {50, "default:stone 2"},
        {30, "default:iron_lump 3"},
        {30, "default:copper_lump 3"},
        {30, "default:tin_lump 3"},
    },
})

register("tigris_mobs:mese_shambler", {
    desc = "Mese Shambler",
    nodes = {"group:stone"},
    texture = "default_mese_block.png",
    underground = true,
    ymax = -300,
    light = minetest.LIGHT_MAX / 2,
    damage = {fleshy = 6},
    level = 4,
    chance = 15000,
    strength = 3,
    armor = {fleshy = 50, cold = 75, heat = 75},
    drops = {
        {100, "tigris_mobs:mese_heart"},
        {75, "default:mese_crystal"},
        {75, "default:mese_crystal"},
        {75, "default:mese_crystal"},
        {10, "default:mese"},
    },
})

register("tigris_mobs:obsidian_shambler", {
    desc = "Obsidian Shambler",
    nodes = {"group:stone"},
    texture = "default_obsidian.png",
    underground = true,
    ymax = -500,
    light = minetest.LIGHT_MAX / 2,
    damage = {fleshy = 5},
    level = 4,
    chance = 25000,
    strength = 4,
    armor = {fleshy = 25, cold = 50, heat = 0},
    drops = {
        {75, "default:obsidian_shard"},
        {75, "default:obsidian_shard"},
        {75, "default:obsidian_shard"},
        {30, "default:obsidian"},
    },
})
