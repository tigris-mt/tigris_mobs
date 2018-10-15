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
            s.global.interactions.sheep_shear = true
            s.flee.interactions.sheep_shear = false
            table.insert(s.wander.actions, "sheep_grow_wool")
            table.insert(s.standing.actions, "sheep_grow_wool")
        end),
    })

    tigris.mobs.register_mob_node("tigris_mobs:sheep_" .. color .. "_shorn", "tigris_mobs:sheep_" .. color, {
        tiles = textures(color, true),
    })

    tigris.mobs.register_spawn("tigris_mobs:sheep_" .. color, {
        ymax = tigris.world_limits.max.y,
        ymin = -24,

        light_min = 0,
        light_max = minetest.LIGHT_MAX,

        chance = 5000 * #colors,

        nodes = {"group:soil"},
    })
end

tigris.mobs.register_action("sheep_grow_wool", {
    func = function(self, context)
        if not self._data.shorn then
            return
        end
        local leat = self._data.eaten or 0
        local lshear = self._data.last_shorn or 0
        if leat < lshear then
            return
        end
        if minetest.get_gametime() - lshear >= 60 * 10 then
            self.textures = {"tigris_mobs:sheep_" .. self.def.color}
            self._data.shorn = false
        end
    end,
})

tigris.mobs.register_interaction("sheep_shear", {
    func = function(self, context)
        local stack = context.other:get_wielded_item()
        if stack:get_name() ~= "mobs:shears" or self._data.shorn or tigris.mobs.is_protected(self.object, context.other:get_player_name()) then
            return
        end

        self._data.shorn = true
        self._data.last_shorn = minetest.get_gametime()
        self.textures = {"tigris_mobs:sheep_" .. self.def.color .. "_shorn"}

        local obj = minetest.add_item(self.object:getpos(), ItemStack("wool:" .. self.def.color .. " " .. math.random(1, 3)))
        if obj then
            obj:setvelocity(vector.new(math.random() * 2 - 1, math.random() * 4 - 2, math.random() * 2 - 1))
        end

        stack:add_wear(655)
        context.other:set_wielded_item(stack)
    end,
})
