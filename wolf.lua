tigris.mobs.register("tigris_mobs:wolf", {
    description = "Wolf",
    collision = {-0.4, -0.4, -0.4, 0.4, 0.4, 0.4},
    box = {
        {-0.25, 0, -0.5, 0.25, 0.6, 0.5},
        {-0.25, -0.5, -0.5, -0.1, 0, -0.35},
        {0.1, -0.5, -0.5, 0.25, 0, -0.35},
        {-0.25, -0.5, 0.35, -0.1, 0, 0.5},
        {0.1, -0.5, 0.35, 0.25, 0, 0.5},
        {-0.25, 0, -0.5, 0.25, 0.5, -0.75},
        {-0.25, 0, -0.5, 0.25, 0.25, -1.2},
        {-0.1, 0.4, 0.5, 0.1, 0.5, 0.75},
    },
    textures = {
        "wool_dark_grey.png",
        "wool_dark_grey.png",
        "wool_dark_grey.png",
        "wool_dark_grey.png",
        "wool_dark_grey.png",
        "wool_dark_grey.png^tigris_mobs_wolf_face.png",
    },

    level = 2,

    drops = {
        {100, "mobs:meat_raw"},
        {100, "tigris_mobs:bone"},
        {100, "tigris_mobs:fang"},
        {25, "tigris_mobs:fang"},
        {25, "tigris_mobs:eye"},
        {15, "tigris_mobs:eye"},
    },

    habitat_nodes = tigris.mobs.nodes.dirt,

    on_init = function(self, data)
        self.hp_max = 6
        data.jump = 5
        data.speed = 3.5
        data.fast_speed = 4
        data.damage = {fleshy = 2}
        data.regen = 5
    end,

    start = "wander",

    script = {
        global = {
            events = {
                low_hp = "flee",
                hit = "goto",
                timeout = "wander",
                stuck = "wander",
                node_damage = "flee",
            },
        },

        wander = {
            actions = {
                "enemy_reset",
                "fight_tick",
                "timeout",
                "regenerate",
                "find_target",
                "find_habitat",
                "find_random",
            },
            events = {
                found = "goto",
            },
        },

        goto = {
            actions = {
                "fight_tick",
                "check_hp",
                "check_target",
            },
            events = {
                arrived = "standing",
                arrived_entity = "fight",
                gone = "wander",
            },
        },

        standing = {
            actions = {
                "timeout",
                "regenerate",
                "fight_tick",
            },
            events = {},
        },

        fight = {
            actions = {
                "fight_tick",
                "fight",
            },
            events = {
                wait = "goto",
                done = "goto",
            },
        },

        flee = {
            actions = {
                "fight_tick",
                "regenerate",
            },
            events = {
                hit = "flee",
                escaped = "wander",
            }
        },
    },
})

tigris.mobs.register_spawn("tigris_mobs:wolf", {
    ymax = tigris.world_limits.max.y,
    ymin = -24,

    light_min = 0,
    light_max = minetest.LIGHT_MAX,

    chance = 20000,

    nodes = tigris.mobs.nodes.dirt,
})
