local m = {}
tigris.mobs = m

function m.spawn(name, pos, owner)
    local obj = minetest.add_entity(pos, name)
    obj:get_luaentity().faction = owner and tigris.player.faction(owner) or nil
    return obj
end

local uids = 0

function m.register(name, def)
    def.name = name

    minetest.register_node(name, {
        description = def.description,

        drawtype = "nodebox",
        wield_scale = vector.new(0.6, 0.6, 0.6),
        node_box = {type = "fixed", fixed = def.box},
        tiles = def.textures,

        node_placement_prediction = "",

        groups = {not_in_creative_inventory = 1, tigris_mob = 1},

        on_place = function(itemstack, placer, pointed_thing)
            m.spawn(name, minetest.get_pointed_thing_position(pointed_thing, true), placer:get_player_name())
            itemstack:take_item()
            return itemstack
        end,
    })

    minetest.register_entity(name, {
        physical = true,
        collisionbox = def.collision or def.box[1],
        selectionbox = def.collision or def.box[1],
        hp_max = 1,

        tigris_mob = name,

        visual = "wielditem",
        visual_size = {x = 1, y = 1},
        textures = {name},

        mob_def = def,

        _on_init = function(self)
            self._data = {
                created = os.time(),
                timeout = 300,
                jump = 5,
                speed = 1,
                fast_speed = 2,
                drown = 1,
                node_damage = true,
            }

            if def.on_init then
                def.on_init(self, self._data)
            end

            self.object:set_properties(self)
            self.object:set_hp(self.hp_max)

            self._data.state = def.start
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
            self.def = def

            self._data = minetest.deserialize(data)
            if type(self._data) ~= "table" then
                self:_on_init()
            else
                for k,v in pairs(self._data.p) do
                    self[k] = v
                end
                self._data.p = nil
                self.faction = self._data.faction or self.faction
                self.object:set_hp(self._data.hp or 0)
            end

            if def.on_activate then
                def.on_activate(self)
            end

            if def.armor then
                self.object:set_armor_groups(def.armor)
            end

            self.object:set_properties(self)

            uids = uids + 1
            self.uid = uids
        end,

        get_staticdata = function(self)
            self._data.p = self.object:get_properties()
            self._data.hp = self.object:get_hp()
            self._data.faction = self.faction
            return minetest.serialize(self._data)
        end,

        on_step = function(self, dtime)
            if not self._data.created then
                minetest.log("warning", "Removed invalid " .. def.name .. " at " .. minetest.pos_to_string(self.object:getpos()))
                self.object:remove()
                return
            end

            self.last_pos = self.last_pos or self.object:getpos()
            self.last_ground = self.last_ground or self.object:getpos()

            if def.on_step then
                def.on_step(self, dtime)
            end

            local node = minetest.get_node(vector.subtract(self.object:getpos(), vector.new(0, 1, 0)))
            local rn = minetest.registered_nodes[node.name]
            if rn and rn.walkable then
                self.object:set_hp(self.object:get_hp() - math.max(0, math.floor(
                    math.abs(self.object:getpos().y - self.last_ground.y) / 2 - 2) * (self._data.fall or 1)))
                self.last_ground = self.object:getpos()
            end

            local rn = minetest.registered_nodes[minetest.get_node(self.object:getpos()).name]

            local g = 1
            local d = 0

            local liquid = (rn.groups.liquid and rn.groups.liquid > 0)

            if self._data.node_damage and (rn.damage_per_second > 0) then
                d = rn.damage_per_second * dtime
                m.fire_event(self, {name = "node_damage"})
            elseif self._data.drown and liquid then
                d = 1 * dtime
                m.fire_event(self, {name = "node_damage"})
            else
                self.node_damage_inc = 0
            end

            if liquid then
                g = 0
                self.object:setvelocity(vector.add(self.object:getvelocity(), vector.new(0, self.object:getvelocity().y < 0.5 and 0.5 or 0, 0)))
            end

            self.object:set_acceleration(vector.new(0, -8.5 * g, 0))

            self.node_damage_inc = (self.node_damage_inc or 0) + d
            if self.node_damage_inc > 1 then
                self.object:set_hp(self.object:get_hp() - self.node_damage_inc)
                self.node_damage_inc = 0
            end

            if self.object:get_hp() <= 0 then
                self:on_death()
                self.object:remove()
                return
            end

            self.infotext = ("%s %d/%d ♥%s"):format(def.description, self.object:get_hp(), self.hp_max,
                self.faction and (" " .. self.faction) or "")
            self.object:set_properties(self)

            tigris.mobs.state(self, dtime, def)

            self.last_pos = self.object:getpos()
        end,

        on_punch = function(self, puncher)
            if m.valid_enemy(self, puncher) then
                self.enemy = puncher
            end
            m.fire_event(self, {name = "hit"})
        end,
    })
end

function m.valid_enemy(self, obj, find)
    if obj:is_player() then
        return not self.faction or tigris.player.faction(obj:get_player_name()) ~= self.faction
    else
        local ent = obj:get_luaentity()
        if ent.tigris_mob and (ent.def.level < self.def.level or not find) and ent.def.group ~= self.def.group then
            return (not self.faction) or (not ent.faction) or (ent.faction ~= self.faction)
        end
    end

    return false
end

tigris.include("state.lua")
tigris.include("items.lua")
tigris.include("spawning.lua")

tigris.mobs.nodes = {
    dirt = {
        "group:dirt",
        "group:soil",
    },

    sand = {
        "group:sand",
    },
}

-- Passive.
tigris.include("mobs/rat.lua")
tigris.include("mobs/sheep.lua")

-- Aggressive.
tigris.include("mobs/wolf.lua")

-- Demonic.
--[[
Naming convention:
Domain: Ur (Underground), Se (Surface), Lu (Sky)
Element: Chi (Fire), Mi (Water), La (Earth), Tha (Air)
Danger: Ko (Hard), Ja (Medium), Ve (Easy)
--]]
--- Greater.
tigris.include("mobs/urchija.lua")
--- Lesser.
tigris.include("mobs/obsidian_spitter.lua")
