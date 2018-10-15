local m = {}
tigris.mobs.effects = m

function m.eat(self)
    self._data.eaten = minetest.get_gametime()
    self.object:set_hp(self.hp_max)
end
