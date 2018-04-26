local m = tigris.mobs

function m.state_timeout(self, context, seconds)
    context.data.time = (context.data.time or 0) + context.dtime
    if context.data.time > seconds then
        return {name = "timeout"}
    end
end

function m.reset_timeout(self, context)
    context.data.time = 0
end

function m.go(self, context, target, speed, invert)
    local pos = self.object:getpos()
    local cvel = self.object:getvelocity()

    if not invert and vector.distance(pos, target) < 1.5 then
        self.object:setvelocity(vector.new(0, 0, 0))
        return {name = "arrived", data = {
            target = target,
        }}
    end

    local yaw = math.atan2((target.z - pos.z) * (invert and -1 or 1), (target.x - pos.x) * (invert and -1 or 1))
    self.object:setyaw(yaw + 1.57)

    local v = {
        x = math.cos(yaw),
        z = math.sin(yaw),
    }

    local vel = vector.new(
        v.x * speed,
        cvel.y,
        v.z * speed
    )

    local function solid(pos, liquid)
        local n = minetest.registered_nodes[minetest.get_node(pos).name]
        return n.walkable or (liquid and n.groups.liquid and n.groups.liquid > 0)
    end

    if self._data.jump then
        self._data.glp = self._data.glp or pos
        if vector.distance(self._data.glp, pos) > 0.1 * context.dtime then
            local dojump = solid(vector.add(pos, vector.new(vel.x, 0, vel.z))) and solid(vector.add(pos, vector.new(0, -1, 0)), true)
            if dojump or vector.distance(pos, self._data.glp) < speed * context.dtime * 0.1 then
                local fok = not solid(vector.add(pos, vector.new(vel.x, 1, vel.z))) and not solid(vector.add(pos, vector.new(vel.x, 2, vel.z)))
                local aok = not solid(vector.add(pos, vector.new(0, 1, 0))) and not solid(vector.add(pos, vector.new(0, 2, 0)))
                if fok and aok then
                    vel.y = self._data.jump
                else
                    return {name = "stuck"}
                end
            end
        end
        self._data.glp = pos
    end

    self.object:setvelocity(vel)
end

m.register_state("wander", {
    func = function(self, context) return m.state_timeout(self, context, 15) end,
})

m.register_state("fight", {
    func = function() end,
})

m.register_state("goto", {
    func = function(self, context)
        local target = context.data.target and context.data.target or (self.enemy and self.enemy:getpos())
        local g
        if target then
            g = m.go(self, context, target, self._data.speed)
            if g and g.name == "arrived" and not context.data.target then
                g = {name = "arrived_entity"}
            end
        end
        return g or m.state_timeout(self, context, 15)
    end,
})

m.register_state("standing", {
    func = function(self, context) return m.state_timeout(self, context, 5) end,
})

m.register_state("eat", {
    func = function(self, context)
        if minetest.find_node_near(context.data.target, 0, context.def.food_nodes, true) then
            self.eaten = true
            self.object:set_hp(self.hp_max)
            minetest.remove_node(context.data.target)
            return {name = "done"}
        else
            return {name = "gone"}
        end
    end,
})

m.register_state("flee", {
    func = function(self, context)
        local target
        context.data.punch_pos = context.data.punch_pos or self.object:getpos()
        if self.enemy then
            target = self.enemy:getpos()
            local dist = vector.distance(self.object:getpos(), target)
            if dist < 12 then
                m.reset_timeout(self, context)
            elseif dist > 16 then
                return {name = "escaped"}
            end
        else
            target = context.data.punch_pos
        end
        return m.go(self, context, target, self._data.fast_speed, true) or m.state_timeout(self, context, 15)
    end,
})

m.register_action("find_target", {
    func = function(self, context)
        for _,obj in ipairs(minetest.get_objects_inside_radius(self.object:getpos(), 16)) do
            if obj:is_player() then
                self.enemy = obj
                return {name = "found"}
            elseif obj:get_luaentity().tigris_mob and obj:get_luaentity().def.level < context.def.level then
                self.enemy = obj
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
        if self.object:get_hp() >= self.hp_max and self.eaten then
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

m.register_action("timeout", {
    func = function(self, context)
        if self._data.timeout and os.time() - self._data.created > self._data.timeout then
            self.object:remove()
        end
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
        if self.enemy and (not self.enemy:getpos() or vector.distance(self.object:getpos(), self.enemy:getpos()) > 32) then
            self.enemy = nil
            return {name = "gone"}
        end
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

m.register_action("enemy_reset", {
    func = function(self, context)
        self.enemy = nil
    end,
})

m.register_action("fight", {
    func = function(self, context)
        if self.fight_timer > 1 and self.enemy and self.enemy:getpos() then
            local d = {}
            for k,v in pairs(self._data.damage) do
                d[k] = v * self.fight_timer
            end
            tigris.damage.apply(self.enemy, d, self.object)
            self.fight_timer = 0
            return {name = "done"}
        else
            return {name = "wait"}
        end
    end,
})

m.register_action("throw", {
    func = function(self, context)
        if self.fight_timer > 1 and self.enemy and self.enemy:getpos() then
            local from = vector.add(self.object:getpos(), vector.new(0, self.object:get_properties().collisionbox[5] * 0.75, 0))
            local to = self.enemy:getpos()
            to.y = to.y + self.enemy:get_properties().collisionbox[5] * 0.75
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
