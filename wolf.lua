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
                hit = "goto",
                timeout = "wander",
            },
        },

        goto = {
            actions = {
                "fight_tick",
                "check_hp",
                "check_target",
            },
            events = {
                hit = "goto",
                arrived = "standing",
                arrived_entity = "fight",
                stuck = "wander",
                gone = "wander",
                timeout = "standing",
                low_hp = "flee",
            },
        },

        standing = {
            actions = {
                "timeout",
                "regenerate",
                "fight_tick",
            },
            events = {
                hit = "goto",
                timeout = "wander",
            },
        },

        fight = {
            actions = {
                "fight_tick",
                "fight",
            },
            events = {
                wait = "goto",
                done = "goto",
                hit = "goto",
            },
        },

        flee = {
            actions = {
                "fight_tick",
                "regenerate",
            },
            events = {
                hit = "flee",
                timeout = "wander",
                escaped = "wander",
                stuck = "wander",
            }
        },
    },
})

