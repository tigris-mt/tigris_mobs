local function textures(color, shorn)
    local s = shorn and "^tigris_mobs_sheep_shorn.png" or ""
    return {
        "wool_" .. color .. ".png" .. s,
        "wool_" .. color .. ".png" .. s,
        "wool_" .. color .. ".png" .. s,
        "wool_" .. color .. ".png" .. s,
        "wool_" .. color .. ".png" .. s,
        "wool_" .. color .. ".png^tigris_mobs_sheep_face.png",
    }
end

local colors = {"white", "black", "brown", "grey", "dark_grey"}
for _,color in ipairs(colors) do
    local name = "tigris_mobs:sheep_" .. color
    tigris.mobs.register(name, {
        description = "Sheep",
        collision = {-0.4, -0.4, -0.4, 0.4, 0.4, 0.4},
        box = {
            {-0.25, 0, -0.5, 0.25, 0.6, 0.5},
            {-0.25, -0.5, -0.5, -0.1, 0, -0.35},
            {0.1, -0.5, -0.5, 0.25, 0, -0.35},
            {-0.25, -0.5, 0.35, -0.1, 0, 0.5},
            {0.1, -0.5, 0.35, 0.25, 0, 0.5},
            {-0.25, 0, -0.5, 0.25, 0.5, -0.75},
            {-0.1, 0.4, 0.5, 0.1, 0.5, 0.75},
        },
        textures = textures(color, false),

        group = "peaceful",
        level = 1,

        drops = {
            {100, "mobs:meat_raw"},
            {100, "tigris_mobs:bone"},
            {25, "tigris_mobs:eye"},
            {15, "tigris_mobs:eye"},
            {75, "wool:" .. color},
        },

        food_nodes = {
            "group:grass",
            "group:flora",
        },

        food_items = {
            "farming:wheat",
            "farming:seed_wheat",
        },

        habitat_nodes = {"group:soil"},

        color = color,

        on_init = function(self, data)
            self.hp_max = 4
            data.jump = 5
        end,

        start = "wander",

        script = tigris.mobs.common.peaceful({
            eat = true,
            breed = true,
        }, function(s)
            s.global.interactions.shear_wool = true
            s.flee.interactions.shear_wool = false
            table.insert(s.wander.actions, "grow_wool")
            table.insert(s.standing.actions, "grow_wool")
        end),
    })

    tigris.mobs.register_mob_node(name .. "_shorn", name, {
        tiles = textures(color, true),
    })

    tigris.mobs.register_spawn(name, {
        ymax = tigris.world_limits.max.y,
        ymin = -24,

        light_min = 0,
        light_max = minetest.LIGHT_MAX,

        chance = 5000 * #colors,

        nodes = {"group:soil"},
    })
end
