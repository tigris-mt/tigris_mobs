local m = tigris.mobs
m.register_action("find_enemy", {
    func = function(self, context)
        for _,obj in ipairs(minetest.get_objects_inside_radius(self.object:getpos(), 16)) do
            if m.valid_enemy(self, obj, true) and not tigris.check_pos_safe(obj:getpos()) then
                self.other = obj
                return {name = "found"}
            end
        end
    end,
})

local function find_node(self, context, nodes, above)
    local search = vector.new(8, 8, 8)
    local min = vector.subtract(self.object:getpos(), search)
    local max = vector.add(self.object:getpos(), search)
    local nodes = minetest.find_nodes_in_area_under_air(min, max, nodes)
    if #nodes > 0 then
        return {name = "found", data = {
            target = vector.add(nodes[math.random(1, #nodes)], vector.new(0, above and 0 or 1, 0)),
        }}
    end
end

m.register_action("find_food", {
    func = function(self, context)
        if self.object:get_hp() >= self.hp_max and (minetest.get_gametime() - (self._data.eaten or 0) < 60 * 15) then
            return
        end
        return find_node(self, context, context.def.food_nodes, true)
    end,
})

m.register_action("find_habitat", {
    func = function(self, context)
        return find_node(self, context, context.def.habitat_nodes, false)
    end,
})

m.register_action("find_random", {
    func = function(self, context)
        return {name = "found", data = {
            target = vector.add(self.object:getpos(), vector.new((math.random() - 0.5) * 2 * 16, 0, (math.random() - 0.5) * 2 * 16)),
        }}
    end,
})

m.register_action("check_food", {
    func = function(self, context)
        if context.data.target then
            if minetest.find_node_near(context.data.target, 0, context.def.food_nodes, true) then
                return {name = "at_food", data = {
                    target = context.data.target,
                }}
            end
        end
    end,
})

m.register_action("find_food_interest", {
    func = function(self, context)
        for _,obj in ipairs(minetest.get_objects_inside_radius(self.object:getpos(), 8)) do
            if obj:is_player() and not m.is_protected(self.object, obj:get_player_name()) then
                for _,v in ipairs(context.def.food_items) do
                    if v == obj:get_wielded_item():get_name() then
                        self.other = obj
                        return {name = "interest"}
                    end
                end
            end
        end
    end
})

m.register_action("check_food_interest", {
    func = function(self, context)
        if not self.other then
            return
        end
        for _,v in ipairs(context.def.food_items) do
            if v == self.other:get_wielded_item():get_name() then
                return
            end
        end
        return {name = "gone"}
    end,
})

m.register_action("timeout", {
    func = function(self, context)
        if not self._data.tame and not self.faction and self._data.timeout and minetest.get_gametime() - self._data.last_active > self._data.timeout then
            self.object:remove()
        end
    end,
})

m.register_action("reset_timeout", {
    func = function(self, context)
        self._data.last_active = minetest.get_gametime()
    end,
})


m.register_action("check_hp", {
    func = function(self, context)
        if self.object:get_hp() <= self.hp_max / 2 then
            return {name = "low_hp"}
        end
    end,
})

m.register_action("check_target", {
    func = function(self, context)
        local rc = true
        if self.other and self.other:getpos() then
            if vector.distance(self.object:getpos(), self.other:getpos()) > 32 then
                self.other = nil
                rc = false
            end
        else
            rc = false
            self.other = nil
        end
        if not rc then
            if self.had_target then
                self.had_target = false
                return {name = "gone"}
            else
                return
            end
        end
        self.had_target = true
    end,
})

m.register_action("regenerate", {
    func = function(self, context)
        self.regen_timer = (self.regen_timer or 0) + context.dtime
        if self._data.regen and self.regen_timer > self._data.regen then
            self.regen_timer = 0
            self.object:set_hp(self.object:get_hp() + 1)
        end
    end,
})

m.register_action("fight_tick", {
    func = function(self, context)
        self.fight_timer = (self.fight_timer or 0) + context.dtime
    end,
})

m.register_action("other_reset", {
    func = function(self, context)
        self.other = nil
    end,
})

m.register_action("fight", {
    func = function(self, context)
        if self.fight_timer > 1 and self.other and self.other:getpos() then
            local d = {}
            for k,v in pairs(self._data.damage) do
                d[k] = v
            end
            tigris.damage.apply(self.other, d, self.object)
            self.fight_timer = 0
            return {name = "done"}
        else
            return {name = "wait"}
        end
    end,
})

m.register_action("throw", {
    func = function(self, context)
        if self.fight_timer > 1 and self.other and self.other:getpos() then
            local from = vector.add(self.object:getpos(), vector.new(0, self.object:get_properties().collisionbox[5] * 0.75, 0))
            local to = self.other:getpos()
            to.y = to.y + self.other:get_properties().collisionbox[5] * 0.75
            local dir = vector.normalize{x = to.x - from.x, y = to.y - from.y, z = to.z - from.z}

            tigris.create_projectile(self._data.projectile, {
                pos = from,
                velocity = vector.multiply(dir, 10),
                gravity = 0,
                owner = self.uid,
                owner_object = self.object,
            })

            self.fight_timer = 0

            return {name = "done"}
        else
            return {name = "wait"}
        end
    end,
})
