local m = {}
tigris.mobs = m

-- If enabled, will display debug information.
m.debug = minetest.settings:get_bool("tigris.mobs.debug", false)
-- Multiplier for spawn chance (1 = normal, 2 = twice as many, etc.)
m.spawn_factor = tonumber(minetest.settings:get("tigris.mobs.spawn_factor")) or 1

-- Spawn mob <name> at <pos> with optional <owner>.
function m.spawn(name, pos, owner)
    local obj = minetest.add_entity(pos, name)
    if obj then
        obj:get_luaentity().faction = owner and tigris.player_faction(owner) or nil
        obj:get_luaentity()._data.tame = not not owner
    end
    return obj
end

local uids = 0

function m.register_mob_node(name, mob, overrides)
    local def = minetest.registered_entities[mob].mob_def
    local d = {
        description = def.description,

        -- Just use the mob as the nodebox.
        drawtype = "nodebox",
        wield_scale = vector.new(0.6, 0.6, 0.6),
        node_box = {type = "fixed", fixed = def.box},
        tiles = def.textures,

        -- We're not actually placing a node.
        node_placement_prediction = "",

        groups = {not_in_creative_inventory = 1, tigris_mob = 1, dig_immediate = 3},
    }
    for k,v in pairs(overrides) do
        d[k] = v
    end
    minetest.register_node(name, d)
end

function m.register(name, def)
    def.name = name
    for k,v in pairs(def.script) do
        v.events = v.events or {}
        v.actions = v.actions or {}
        v.interactions = v.interactions or {}
    end

    minetest.register_entity(name, {
        -- Basic entity properties.
        physical = true,
        collisionbox = def.collision or def.box[1],
        selectionbox = def.collision or def.box[1],

        -- Initial max HP.
        hp_max = 1,

        -- This is a tigris mob.
        tigris_mob = name,

        visual = "wielditem",
        visual_size = {x = 1, y = 1},
        textures = {name},

        -- Full mob definition.
        mob_def = def,

        -- Create initial data.
        _on_init = function(self)
            self._data = {
                created = os.time(),
                timeout = 300,
                jump = 5,
                speed = 1,
                fast_speed = 2,
                drown = 1,
                node_damage = true,
                float = true,
                teleport_time = 5,
            }

            -- Run def init.
            if def.on_init then
                def.on_init(self, self._data)
            end

            -- Set properties and HP.
            self.object:set_properties(self)
            self.object:set_hp(self.hp_max)

            -- Set starting state.
            self._data.state = def.start
        end,

        on_death = function(self)
            -- Set drop table (for def.on_death to use)
            self._drops = table.copy(def.drops)

            -- Run def death.
            if def.on_death then
                def.on_death(self)
            end

            -- Drop items.
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

        -- Update data and save.
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

            -- Initialize counters if necessary.
            self.last_pos = self.last_pos or self.object:getpos()
            self.last_ground = self.last_ground or self.object:getpos()

            -- Run def step.
            if def.on_step then
                def.on_step(self, dtime)
            end

            -- Check for ground node.
            local node = minetest.get_node(vector.subtract(self.object:getpos(), vector.new(0, 1, 0)))
            local rn = minetest.registered_nodes[node.name]
            -- Found one.
            if rn and rn.walkable then
                -- Fall damage.
                self.object:set_hp(self.object:get_hp() - math.max(0, math.floor(
                    math.abs(self.object:getpos().y - self.last_ground.y) / 2 - 2) * (self._data.fall or 1)))
                self.last_ground = self.object:getpos()
            end

            -- Check if we're inside something.
            local rn = minetest.registered_nodes[minetest.get_node(self.object:getpos()).name]

            -- Gravity factor for node.
            local g = 1
            -- Damage factor for node.
            local d = 0

            local liquid = (rn.groups.liquid and rn.groups.liquid > 0)

            -- Node damage?
            if self._data.node_damage and (rn.damage_per_second > 0) then
                d = rn.damage_per_second * dtime
                m.fire_event(self, {name = "node_damage"})
            -- Should we drown in liquid?
            elseif self._data.drown and liquid then
                d = self._data.drown * dtime
                m.fire_event(self, {name = "node_damage"})
            -- No damage from node.
            else
                self.node_damage_inc = 0
            end

            -- Apply floating.
            if liquid and self._data.float then
                g = 0
                self.object:setvelocity(vector.add(self.object:getvelocity(), vector.new(0, self.object:getvelocity().y < 0.5 and 0.5 or 0, 0)))
            end

            -- Set gravity with factor.
            self.object:set_acceleration(vector.new(0, -8.5 * g, 0))

            -- Increment node damage so we aren't just applying fractions floored to 0.
            self.node_damage_inc = (self.node_damage_inc or 0) + d
            -- If incremented node damage is big enough, then apply it.
            if self.node_damage_inc > 1 then
                self.object:set_hp(self.object:get_hp() - self.node_damage_inc)
                self.node_damage_inc = 0
            end

            -- Handle death.
            if self.object:get_hp() <= 0 then
                self:on_death()
                self.object:remove()
                return
            end

            -- Set infotext with important information.
            self.infotext = ("%s %d/%d ♥%s%s%s"):format(
                def.description,
                self.object:get_hp(),
                self.hp_max,
                (self.faction and (" " .. self.faction) or ""),
                (m.debug and (" " .. (self._data.state or "?")) or ""),
                ((m.debug and self._data.tame) and " tame" or "")
            )
            -- Update properties.
            self.object:set_properties(self)

            -- Handle state.
            tigris.mobs.state(self, dtime, def)

            -- Record last known position.
            self.last_pos = self.object:getpos()
        end,

        on_punch = function(self, puncher)
            -- Set our other if the puncher is valid.
            if m.valid_enemy(self, puncher) then
                self.other = puncher
            end
            m.fire_event(self, {name = "hit"})
        end,

        on_rightclick = function(self, clicker)
            m.interaction(self, clicker)
        end,
    })

    -- Register spawn item and default appearance.
    m.register_mob_node(name, name, {
        -- Simple spawn and return.
        on_place = function(itemstack, placer, pointed_thing)
            m.spawn(name, minetest.get_pointed_thing_position(pointed_thing, true), placer:get_player_name())
            itemstack:take_item()
            return itemstack
        end,
    })
end

function m.valid_enemy(self, obj, find)
    if not obj then
        return false
    end

    if obj:is_player() then
        return not self.faction or tigris.player_faction(obj:get_player_name()) ~= self.faction
    else
        local ent = obj:get_luaentity()
        if not ent then
            return false
        end
        if ent.tigris_mob and (ent.def.level < self.def.level or not find) and ent.def.group ~= self.def.group then
            return (not self.faction) or (not ent.faction) or (ent.faction ~= self.faction)
        end
    end

    return false
end

function m.is_protected(obj, name)
    local ent = obj:get_luaentity()
    assert(ent and ent.tigris_mob)
    return ent.faction and ent.faction ~= tigris.player_faction(name)
end

tigris.include("state.lua")
tigris.include("effects.lua")

tigris.include("breeding.lua")
tigris.include("wool.lua")

tigris.include("items.lua")

tigris.include("spawning.lua")
tigris.include("spawner.lua")

--[[
Demonic Naming convention:
Domain: Ur (Underground), Se (Surface), Lu (Sky)
Element: Chi (Fire), Mi (Water), La (Earth), Tha (Air)
Danger: Ko (Hard), Ja (Medium), Ve (Easy)
--]]

tigris.include("mob_common.lua")
tigris.include_dir("mobs")
