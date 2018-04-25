local m = tigris.mobs

m.actions = {}
m.states = {}

function m.register_action(n, d)
    m.actions[n] = d
end

function m.register_state(n, d)
    m.states[n] = d
end

function m.state(self, dtime, def)
    self._data.state_data = self._data.state_data or {}
    self.sdata = self._data.state_data

    local function reset_state(s, data)
        self._data.state_data = data or {}
        self.sdata = self._data.state_data
        self._data.state = s
    end

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
                reset_state(context.script.events[event.name], event.data)
            else
                minetest.log("warning", def.name .. " with invalid event: " .. tostring(event.name))
            end
        end
    else
        minetest.log("warning", def.name .. " with invalid state: " .. tostring(state))
    end
end

tigris.include("states.lua")
