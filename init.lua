local m = {}
tigris.mobs = m

function m.spawn(name, pos)
    local obj = minetest.add_entity(pos, name)
    return obj
end

function m.register(name, def)
    minetest.register_node(name, {
        description = def.description,

        drawtype = "nodebox",
        wield_scale = vector.new(0.6, 0.6, 0.6),
        node_box = {type = "fixed", fixed = def.box},
        tiles = def.textures,

        groups = {not_in_creative_inventory = 1, tigris_mob = 1},

        on_place = function(itemstack, placer, pointed_thing)
            m.spawn(name, minetest.get_pointed_thing_position(pointed_thing, true))
            itemstack:take_item()
            return itemstack
        end,
    })

    minetest.register_entity(name, {
        physical = true,
        collisionbox = def.collision or def.box[1],
        selectionbox = def.collision or def.box[1],
        hp_max = 1,

        visual = "wielditem",
        visual_size = {x = 1, y = 1},
        textures = {name},

        _on_init = function(self)
            self._data = {
                created = os.time(),
                timeout = 300,
            }

            if def.on_init then
                def.on_init(self, self._data)
            end

            self.object:set_properties(self)
            self.object:set_hp(self.hp_max)
        end,

        on_death = function(self)
            self._drops = table.copy(def.drops)

            if def.on_death then
                def.on_death(self)
            end

            for _,drop in ipairs(self._drops or {}) do
                if math.random() * 100 <= drop[1] then
                    minetest.add_item(self.object:getpos(), ItemStack(drop[2]))
                end
            end
        end,

        on_activate = function(self, data)
            self._data = minetest.deserialize(data)
            if type(self._data) ~= "table" then
                self:_on_init()
            else
                for k,v in pairs(self._data.p) do
                    self[k] = v
                end
                self._data.p = nil
                self.object:set_hp(self._data.hp or 0)
            end
            self.object:set_properties(self)
        end,

        get_staticdata = function(self)
            self._data.p = self.object:get_properties()
            self._data.hp = self.object:get_hp()
            return minetest.serialize(self._data)
        end,

        on_step = function(self, dtime)
            self._data.created = self._data.created or 0

            if def.on_step then
                def.on_step(self, dtime)
            end

            if self._data.timeout and os.time() - self._data.created > self._data.timeout then
                self.object:set_hp(0)
            end

            if self.object:get_hp() <= 0 then
                self:on_death()
                self.object:remove()
                return
            end

            self.infotext = ("%d/%d ♥"):format(self.object:get_hp(), self.hp_max)
            self.object:set_properties(self)
        end,
    })
end

tigris.include("items.lua")
tigris.include("sheep.lua")
