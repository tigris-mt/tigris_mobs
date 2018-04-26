tigris.mobs.register("tigris_mobs:urchija", {
    description = "Urchija",
    collision = {-0.5, -0.5, -0.5, 0.5, 2.5, 0.5},
    box = {
        {-0.25, -0.5, -0.25, 0.25, 2.5, 0.25},
        {-2, 2.3, -0.1, 2, 2.5, 0.1},
    },
    textures = {
        "default_obsidian.png^tigris_mobs_eye.png",
    },

    group = "ur-demons",
    level = 8,

    drops = {
        {15, "tigris_mobs:eye"},
        {15, "tigris_mobs:cursed_brain"},
        {20, "tigris_magic:body_essence"},
        {20, "tigris_magic:mana_essence"},
    },

    armor = {fleshy = 75, heat = 25},

    on_init = function(self, data)
        self.hp_max = 20
        data.regen = 3
        data.projectile = "tigris_mobs:urchija_projectile"
        data.fall = 0
    end,

    on_activate = function(self)
        self.automatic_rotate = 2
    end,

    start = "wander",

    script = {
        global = {
            events = {
                timeout = "wander",
                hit = "teleport",
            },
        },

        wander = {
            actions = {
                "enemy_reset",
                "fight_tick",
                "timeout",
                "regenerate",
                "find_target",
            },
            events = {
                found = "teleport",
            },
        },

        teleport = {
            actions = {
                "check_target",
                "fight_tick",
                "throw",
            },
            events = {
                gone = "wander",
                wait = "teleport",
                done = "teleport",
                arrived = "fight",
            },
        },

        fight = {
            actions = {
                "fight_tick",
                "throw",
            },
            events = {
                wait = "teleport",
                done = "teleport",
            },
        },
    },
})

tigris.mobs.register_spawn("tigris_mobs:urchija", {
    ymax = -400,
    ymin = tigris.world_limits.min.y,

    light_min = 0,
    light_max = 6,

    chance = 30000,

    nodes = {"group:stone"},
})

tigris.register_projectile("tigris_mobs:urchija_projectile", {
    texture = "fire_basic_flame.png",
    on_node_hit = function(self, pos)
        if minetest.get_item_group(minetest.get_node(pos).name, "flammable") > 0 then
            minetest.set_node(pos, {name = "fire:basic_flame"})
        end
        return true
    end,
    on_entity_hit = function(self, obj)
        tigris.damage.apply(obj, {heat = 4}, self._owner_object)
        return true
    end,
})
