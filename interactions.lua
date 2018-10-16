local m = tigris.mobs
m.register_interaction("feed", {
    func = function(self, context)
        local stack = context.other:get_wielded_item()
        local item = stack:get_name()
        local ok = false
        for _,v in ipairs(context.def.food_items or {}) do
            ok = ok or (item == v)
        end
        if ok then
            stack:take_item()
            context.other:set_wielded_item(stack)
            m.effects.eat(self)
            self._data.tame = self._data.tame or (math.random() < 0.25)
        end
    end,
})
