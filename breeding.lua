local m = tigris.mobs
local fertile_threshold = 5
local fertile_timer = 10

local function is_fertile(obj)
    local d = obj:get_luaentity()._data
    return (d.fertile or 0) >= fertile_threshold and (minetest.get_gametime() - (d.fertile_timer or minetest.get_gametime())) > fertile_timer
end

local function set_fertile(obj, x)
    obj:get_luaentity()._data.fertile = x
end

local function reset_fertile(obj)
    set_fertile(obj, 0)
    obj:get_luaentity()._data.fertile_timer = minetest.get_gametime()
end

local function name_in(name, list)
    for _,v in ipairs(list) do
        if v == name then
            return true
        end
    end
    return false
end

m.register_action("find_mate", {
    func = function(self, context)
        self._data.fertile_timer = self._data.fertile_timer or minetest.get_gametime()
        if not is_fertile(self.object) then
            return
        end
        local possible = {}
        for _,obj in ipairs(minetest.get_objects_inside_radius(self.object:getpos(), 16)) do
            if obj ~= self.object and obj:get_luaentity() and name_in(obj:get_luaentity().name, self.def.breedable or {self.def.name}) and is_fertile(obj) then
                table.insert(possible, obj)
            end
        end
        if #possible > 0 then
            self.other = possible[math.random(#possible)]
            return {name = "found"}
        end
    end,
})

m.register_state("breed", {
    func = function(self, context)
        if is_fertile(self.object) and is_fertile(self.other) then
            reset_fertile(self.object)
            reset_fertile(self.other)
            local obj = tigris.mobs.spawn(context.def.name, self.object:getpos())
            if obj then
                obj:get_luaentity()._data.tame = true
                minetest.log("Bred " .. context.def.name .. " at " .. minetest.pos_to_string(vector.round(self.object:getpos())))
            end
            return {name = "done"}
        else
            return {name = "gone"}
        end
    end,
})

local old = m.effects.eat
m.effects.eat = function(self)
    old(self)
    self._data.fertile = (self._data.fertile or 0) + 1
end
