local m = tigris.mobs

function m.state_timeout(self, context, seconds)
    context.data.time = (context.data.time or 0) + context.dtime
    if context.data.time > seconds then
        return {name = "timeout"}
    end
end

m.register_state("wander", {
    func = function(self, context) return m.state_timeout(self, context, 15) end,
})

m.register_state("goto", {
    func = function(self, context)
        local pos = self.object:getpos()
        local target = (type(context.data.target) == "table") and context.data.target or context.data.target:getpos()

        if vector.distance(pos, target) < 1 then
            self.object:setvelocity(vector.new(0, 0, 0))
            return {name = "arrived", data = {
                target = target,
            }}
        end

        self.object:setyaw(math.atan2(target.z - pos.z, target.x - pos.x) + 1.57)
        local vel = vector.new(
            math.sign(target.x - pos.x),
            self.object:getvelocity().y,
            math.sign(target.z - pos.z)
        )

        if self._data.jump then
            context.data.goto_last_pos = context.data.goto_last_pos or pos
            if vector.distance(context.data.goto_last_pos, pos) < 0.5 * context.dtime and (
                    minetest.registered_nodes[minetest.get_node(
                        vector.add(pos, vector.new(0, -1, 0))
                    ).name].walkable
                ) then
                    vel.y = self._data.jump
            end
            context.data.goto_last_pos = pos
        end

        self.object:setvelocity(vel)

        return m.state_timeout(self, context, 15)
    end,
})

m.register_state("standing", {
    func = function(self, context) return m.state_timeout(self, context, 15) end,
})

m.register_state("eat", {
    func = function(self, context)
        if minetest.find_node_near(context.data.target, 0, context.def.food_nodes, true) then
            self.object:set_hp(self.hp_max)
            minetest.remove_node(context.data.target)
            return {name = "done"}
        else
            return {name = "gone"}
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
            target = nodes[math.random(1, #nodes)],
        }}
    end
end

m.register_action("find_food", {
    func = function(self, context)
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
