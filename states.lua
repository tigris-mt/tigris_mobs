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
            minetest.remove_node(context.data.target)
            m.effects.eat(self)
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
            if not target then
                return {name = "escaped"}
            end
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

m.register_state("teleport", {
    func = function(self, context)
        local target = context.data.target and context.data.target or (self.enemy and self.enemy:getpos() and vector.add(self.enemy:getpos(),
            self.enemy:get_properties().collisionbox[5] * 0.75))
        self.teleport_timer = (self.teleport_timer or 0) + context.dtime
        if self.teleport_timer > (self._data.teleport_time or 5) then
            if target then
                self.object:setpos(target)
            end
            self.teleport_timer = 0
            return {name = "arrived"}
        end
    end,
})
