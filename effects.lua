local m = {}
tigris.mobs.effects = m

function m.eat(self)
    self.eaten = minetest.get_gametime()
    self.object:set_hp(self.hp_max)
end
