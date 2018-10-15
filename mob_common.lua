local m = {}
tigris.mobs.common = m

-- eat: boolean [false]
function m.peaceful(params)
    return {
        global = {
            interactions = {
                feed = true,
            },
            events = {
                hit = "flee",
                timeout = "wander",
                stuck = "wander",
                node_damage = "flee",
            },
        },

        wander = {
            actions = {
                "other_reset",
                "timeout",
                params.eat and "find_food" or "",
                params.breed and "find_mate" or "",
                "find_habitat",
                "find_random",
            },
            events = {
                found = "goto",
            },
        },

        standing = {
            actions = {
                "check_food",
            },
            events = {
                at_food = "eat",
            },
        },

        eat = {
            events = {
                done = "standing",
                gone = "wander",
            },
        },

        goto = {
            events = {
                arrived = "standing",
                arrived_entity = "breed",
            },
        },

        breed = {
            actions = {
                "check_target",
            },
            events = {
                gone = "wander",
                done = "wander",
            },
        },

        flee = {
            interactions = {
                feed = false,
            },
            events = {
                escaped = "wander",
            }
        },
    }
end

function m.turret(params)
    return {
        global = {
            events = {
                timeout = "wander",
                hit = "fight",
                node_damage = "ignore",
            },
        },

        wander = {
            actions = {
                "other_reset",
                "fight_tick",
                "timeout",
                "regenerate",
                "find_enemy",
            },
            events = {
                found = "fight",
            },
        },

        fight = {
            actions = {
                "fight_tick",
                "throw",
            },
            events = {
                wait = "wander",
                done = "wander",
            },
        },
    }
end

function m.hunter(params)
    return {
        global = {
            events = {
                low_hp = "flee",
                hit = "goto",
                timeout = "wander",
                stuck = "wander",
                node_damage = "flee",
            },
        },

        wander = {
            actions = {
                "other_reset",
                "fight_tick",
                "timeout",
                "regenerate",
                "find_enemy",
                "find_habitat",
                "find_random",
            },
            events = {
                found = "goto",
            },
        },

        goto = {
            actions = {
                "fight_tick",
                "check_hp",
                "check_target",
            },
            events = {
                arrived = "standing",
                arrived_enemy = "fight",
                gone = "wander",
            },
        },

        standing = {
            actions = {
                "timeout",
                "regenerate",
                "fight_tick",
            },
            events = {},
        },

        fight = {
            actions = {
                "fight_tick",
                "fight",
            },
            events = {
                wait = "goto",
                done = "goto",
            },
        },

        flee = {
            actions = {
                "fight_tick",
                "regenerate",
            },
            events = {
                hit = "flee",
                escaped = "wander",
            }
        },
    }
end

for k,v in pairs(m) do
    m[k] = function(params, after)
        local ret = v(params or {})
        if after then
            after(ret)
        end
        return ret
    end
end
