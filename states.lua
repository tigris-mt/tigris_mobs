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

    if not invert and vector.distance(pos, target) < 1 then
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

    local function solid(pos)
        return minetest.registered_nodes[minetest.get_node(pos).name].walkable
    end

    if self._data.jump then
        self._data.glp = self._data.glp or pos
        local dojump = solid(vector.add(pos, vector.new(vel.x, 0, vel.z))) and solid(vector.add(pos, vector.new(0, -1, 0)))
        if dojump or vector.distance(pos, self._data.glp) < speed * context.dtime * 0.1 then
            local fok = not solid(vector.add(pos, vector.new(vel.x, 1, vel.z))) and not solid(vector.add(pos, vector.new(vel.x, 2, vel.z)))
            local aok = not solid(vector.add(pos, vector.new(0, 1, 0))) and not solid(vector.add(pos, vector.new(0, 2, 0)))
            if fok and aok then
                vel.y = self._data.jump
            else
                return {name = "stuck"}
            end
        end
        self._data.glp = pos
    end

    self.object:setvelocity(vel)
end

m.register_state("wander", {
    func = function(self, context) return m.state_timeout(self, context, 15) end,
})

m.register_state("goto", {
    func = function(self, context)
        local target = (type(context.data.target) == "table") and context.data.target or context.data.target:getpos()
        return m.go(self, context, target, self._data.speed) or m.state_timeout(self, context, 15)
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
        if self.puncher then
            target = self.puncher:getpos()
            if vector.distance(self.object:getpos(), target) < 12 then
                m.reset_timeout(self, context)
            end
        else
            target = context.data.punch_pos
        end
        return m.go(self, context, target, self._data.fast_speed, true) or m.state_timeout(self, context, 15)
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
