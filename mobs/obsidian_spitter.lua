tigris.mobs.register("tigris_mobs:obsidian_spitter", {
    description = "Obsidian Spitter",
    collision = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
    box = {
        {-0.25, -0.5, -0.25, 0.25, 0.5, 0.25},
    },
    textures = {
        "default_obsidian.png^tigris_mobs_eye.png",
    },

    group = "ur-demons",
    level = 3,

    drops = {
        {50, "default:obsidian"},
        {50, "default:obsidian_shard 3"},
        {50, "default:obsidian_shard 3"},
        {25, "tigris_mobs:eye"},
        {25, "tigris_mobs:eye"},
        {15, "tigris_mobs:eye"},
    },

    armor = {fleshy = 75},

    on_init = function(self, data)
        self.hp_max = 12
        data.regen = 5
        data.projectile = "tigris_mobs:obsidian_spitter_projectile"
    end,

    start = "wander",

    script = tigris.mobs.common.turret(),
})

tigris.mobs.register_spawn("tigris_mobs:obsidian_spitter", {
    ymax = 0,
    ymin = tigris.world_limits.min.y,

    light_min = 0,
    light_max = 6,

    chance = 10000,

    nodes = {"group:stone"},
})

tigris.register_projectile("tigris_mobs:obsidian_spitter_projectile", {
    texture = "default_obsidian_shard.png",
    on_node_hit = function(self, pos)
        return true
    end,
    on_entity_hit = function(self, obj)
        tigris.damage.apply(obj, {fleshy = 1}, self._owner_object)
        return true
    end,
})
