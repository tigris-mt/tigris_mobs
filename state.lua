local m = tigris.mobs

-- Registrations.
m.actions = {}
m.states = {}
m.interactions = {}

function m.register_action(n, d)
    m.actions[n] = d
end

function m.register_state(n, d)
    m.states[n] = d
end

function m.register_interaction(n, d)
    m.interactions[n] = d
end

-- Reset state for self to new state <s> with data.
function m.reset_state(self, s, data)
    self._data.state_data = data or {}
    self.sdata = self._data.state_data
    self._data.state = s
end

-- Apply global events and interactions from def to the current context.
local function apply_global(def, context)
    -- When global exists in the script, add events and interactions to the current script as long as they're not already specified.
    if def.script.global and context.script then
        if def.script.global.events then
            for k,v in pairs(def.script.global.events) do
                context.script.events[k] = context.script.events[k] or v
            end
        end
        if def.script.global.interactions then
            for k,v in pairs(def.script.global.interactions) do
                local o = context.script.interactions[k]
                context.script.interactions[k] = (o == nil) and v or o
            end
        end
    end
end

-- Build a context from self with globals applied.
local function get_context(self)
    if not self._data.state then
        return
    end
    local context = {
        def = self.def,
        -- The current state's script.
        script = self.def.script[self._data.state] and table.copy(self.def.script[self._data.state]) or nil,
    }
    if not context.script then
        return
    end
    apply_global(self.def, context)
    return context
end

-- Fire an event to self.
function m.fire_event(self, event)
    local context = get_context(self)
    if not context then
        return
    end
    local sname = context.script.events[event.name]
    if sname == "ignore" then
        return
    end
    assert(sname, "Invalid event: " .. tostring(event.name))
    -- Reset to the new state.
    m.reset_state(self, sname, event.data)
end

-- Apply an interaction to self by other.
function m.interaction(self, other)
    local context = get_context(self)
    if not context then
        return
    end
    context.other = other
    for k,v in pairs(context.script.interactions) do
        if v then
            assert(m.interactions[k], "Invalid interaction: " .. tostring(k))
            m.interactions[k].func(self, context)
        end
    end
end

-- Run the current state.
function m.state(self, dtime, def)
    self._data.state_data = self._data.state_data or {}
    self.sdata = self._data.state_data

    local state = self._data.state
    local context = {
        dtime = dtime,
        def = def,
        script = def.script[state] and table.copy(def.script[state]) or nil,
        data = self.sdata,
    }

    apply_global(def, context)

    if m.states[state] and context.script then
        -- Run the base state function.
        local event = m.states[state].func(self, context)
        -- If no event came up, run through actions.
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
        -- If the base function or an action returned an event, then fire it.
        if event then
            if context.script.events[event.name] then
                m.fire_event(self, event)
            else
                minetest.log("warning", def.name .. " with invalid event: " .. tostring(state) .. ":" .. tostring(event.name))
            end
        end
    else
        minetest.log("warning", def.name .. " with invalid state: " .. tostring(state))
    end
end

-- The nil action.
m.register_action("", {
    func = function()
        return
    end,
})

tigris.include("states.lua")
tigris.include("actions.lua")
tigris.include("interactions.lua")
