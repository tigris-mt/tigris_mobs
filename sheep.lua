for _,color in ipairs({"white", "black"}) do
    tigris.mobs.register("tigris_mobs:sheep_" .. color, {
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
        textures = {
            "wool_" .. color .. ".png",
            "wool_" .. color .. ".png",
            "wool_" .. color .. ".png",
            "wool_" .. color .. ".png",
            "wool_" .. color .. ".png",
            "wool_" .. color .. ".png^tigris_mobs_sheep_face.png",
        },

        drops = {
            {100, "mobs:meat_raw"},
            {100, "tigris_mobs:bone"},
            {25, "tigris_mobs:eye"},
            {15, "tigris_mobs:eye"},
            {75, "wool:" .. color},
            {50, "wool:" .. color},
        },

        food_nodes = {
            "group:grass",
            "group:flora",
        },

        habitat_nodes = {
            "group:flora",
            "group:grass",
            "group:dirt",
            "group:soil",
            "group:sand",
        },

        on_init = function(self, data)
            self.hp_max = 4
            data.jump = 5
        end,

        start = "wander",

        script = {
            wander = {
                actions = {
                    "find_food",
                    "find_habitat",
                },
                events = {
                    found = "goto",
                    hit = "flee",
                    timeout = "wander",
                },
            },

            standing = {
                actions = {
                    "check_food",
                },
                events = {
                    timeout = "wander",
                    at_food = "eat",
                    hit = "flee",
                },
            },

            eat = {
                events = {
                    done = "standing",
                    gone = "wander",
                },
            },

            goto = {
                events = {
                    hit = "flee",
                    arrived = "standing",
                    timeout = "wander",
                    stuck = "wander",
                },
            },

            flee = {
                events = {
                    hit = "flee",
                    timeout = "wander",
                    escaped = "wander",
                    stuck = "flee",
                }
            },
        },
    })
end
