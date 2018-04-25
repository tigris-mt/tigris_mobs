local m = tigris.mobs

m.actions = {}
m.states = {}

function m.register_action(n, d)
    m.actions[n] = d
end

function m.register_state(n, d)
    m.states[n] = d
end

function m.reset_state(self, s, data)
    self._data.state_data = data or {}
    self.sdata = self._data.state_data
    self._data.state = s
end

function m.fire_event(self, event)
    if not self._data.state then
        return
    end
    local context = {
        script = self.def.script[self._data.state],
    }
    if not context.script then
        return
    end
    m.reset_state(self, context.script.events[event.name], event.data)
end

function m.state(self, dtime, def)
    self._data.state_data = self._data.state_data or {}
    self.sdata = self._data.state_data

    local state = self._data.state
    local context = {
        dtime = dtime,
        def = def,
        script = def.script[state],
        data = self.sdata,
    }

    if m.states[state] and context.script then
        local event = m.states[state].func(self, context)
        if not event then
            for _,v in ipairs(context.script.actions or {}) do
                if m.actions[v] then
                    event = m.actions[v].func(self, context)
                    if event then
                        break
                    end
                else
                    minetest.log("warning", def.name .. " with invalid action: " .. tostring(v))
                end
            end
        end
        if event then
            if context.script.events[event.name] then
                m.fire_event(self, event)
            else
                minetest.log("warning", def.name .. " with invalid event: " .. tostring(event.name))
            end
        end
    else
        minetest.log("warning", def.name .. " with invalid state: " .. tostring(state))
    end
end

tigris.include("states.lua")
