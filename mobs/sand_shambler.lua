tigris.mobs.register("tigris_mobs:sand_shambler", {
    description = "Sand Shambler",
    collision = {-0.4, 0, -0.4, 0.4, 2, 0.4},
    box = {
        {-0.4, 1, -0.4, 0.4, 2, 0.4},
        {-0.4, 0, -0.1, -0.3, 1, 0.1},
        {0.3, 0, -0.1, 0.4, 1, 0.1},
    },
    textures = {
        "default_sand.png",
        "default_sand.png",
        "default_sand.png",
        "default_sand.png",
        "default_sand.png",
        "default_sand.png^tigris_mobs_shambler_face.png",
    },

    group = "hunters",
    level = 2,

    drops = {
        {80, "default:sand"},
        {50, "default:sand"},
        {40, "default:desert_sand"},
        {40, "default:desert_sand"},
        {5, "tigris_mobs:cursed_brain"},
    },

    habitat_nodes = {"group:sand"},

    on_init = function(self, data)
        self.hp_max = 6
        data.jump = 5
        data.speed = 3
        data.fast_speed = 3
        data.damage = {fleshy = 2, heat = 1}
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

tigris.mobs.register_spawn("tigris_mobs:sand_shambler", {
    ymax = tigris.world_limits.max.y,
    ymin = -24,

    light_min = 0,
    light_max = minetest.LIGHT_MAX,

    chance = 7000,

    nodes = {"group:sand"},
})
