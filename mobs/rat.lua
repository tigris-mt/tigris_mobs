tigris.mobs.register("tigris_mobs:rat", {
    description = "Rat",
    collision = {-0.25, -0.1, -0.5, 0.25, 0.1, 0.5},
    box = {
        {-0.25, -0.1, -0.5, 0.25, 0.1, 0.5},
        {-0.05, 0.05, 0.5, 0.05, 0.1, 1},
        {-0.1, -0.1, -0.5, 0.1, 0.1, -0.75},
        {-0.25, -0.1, -0.5, -0.1, 0.25, -0.6},
        {0.1, -0.1, -0.5, 0.25, 0.25, -0.6},
    },
    textures = {
        "wool_dark_grey.png",
        "wool_dark_grey.png",
        "wool_dark_grey.png",
        "wool_dark_grey.png",
        "wool_dark_grey.png",
        "wool_dark_grey.png^tigris_mobs_rat_face.png",
    },

    group = "peaceful",
    level = 1,

    drops = {
        {20, "mobs:meat_raw"},
        {15, "tigris_mobs:bone"},
        {15, "tigris_mobs:eye"},
    },

    habitat_nodes = {"group:stone"},

    on_init = function(self, data)
        self.hp_max = 2
        data.jump = 5
        data.speed = 1
        data.fast_speed = 3
        data.regen = 10
    end,

    start = "wander",
    script = tigris.mobs.common.peaceful(),
})

tigris.mobs.register_spawn("tigris_mobs:rat", {
    ymax = tigris.world_limits.max.y,
    ymin = tigris.world_limits.min.y,

    light_min = 0,
    light_max = minetest.LIGHT_MAX / 2,

    chance = 5000,

    nodes = {"group:stone"},
})
