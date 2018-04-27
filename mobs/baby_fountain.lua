tigris.mobs.register("tigris_mobs:baby_fountain", {
    description = "Baby Fountain",
    collision = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
    box = {
        {-0.25, -0.5, -0.5, 0.25, 0.5, 0.5},
    },
    textures = {
        "default_ice.png^tigris_mobs_water_lung.png",
    },

    group = "peaceful",
    level = 1,

    drops = {
        {75, "tigris_mobs:water_lung"},
        {25, "tigris_mobs:water_lung"},
    },

    on_init = function(self, data)
        self.hp_max = 15
        data.regen = 2
        data.drown = 0
        data.float = false
        data.teleport_time = 30
    end,

    habitat_nodes = {"group:soil"},

    start = "wander",

    script = {
        global = {
            events = {
                timeout = "wander",
                hit = "ignore",
                node_damage = "ignore",
            },
        },

        wander = {
            actions = {
                "timeout",
                "regenerate",
                "spew_water",
                "find_habitat",
            },
            events = {
                found = "teleport",
            },
        },

        teleport = {
            actions = {
                "timeout",
                "regenerate",
                "spew_water",
            },
            events = {
                arrived = "wander",
            },
        },
    },
})

tigris.mobs.register_spawn("tigris_mobs:baby_fountain", {
    ymax = tigris.world_limits.max.y,
    ymin = -24,

    light_min = 0,
    light_max = minetest.LIGHT_MAX,

    chance = 30000,

    nodes = {"group:soil"},
})

tigris.mobs.register_action("spew_water", {
    func = function(self, context)
        local pos = self.object:getpos()
        local point = vector.add(pos, vector.new(0, 2, 0))
        local nn = minetest.get_node(point).name
        local d = minetest.registered_nodes[nn]
        if minetest.get_item_group(nn, "liquid") == 0 and d.buildable_to then
            minetest.place_node(point, {name = "default:water_flowing"})
        end
    end,
})
