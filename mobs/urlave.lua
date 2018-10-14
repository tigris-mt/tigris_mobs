tigris.mobs.register("tigris_mobs:urlave", {
    description = "Urlave",
    collision = {-0.25, -0.1, -0.5, 0.25, 0.1, 0.5},
    box = {
        {-0.25, -0.1, -0.5, 0.25, 0.1, 0.5},
        {-0.05, 0.05, 0.5, 0.05, 0.1, 1},
        {-0.1, -0.1, -0.5, 0.1, 0.1, -0.75},
        {-0.25, -0.1, -0.5, -0.1, 0.25, -0.6},
        {0.1, -0.1, -0.5, 0.25, 0.25, -0.6},
    },
    textures = {
        "wool_white.png",
        "wool_white.png",
        "wool_white.png",
        "wool_white.png",
        "wool_white.png",
        "wool_white.png^tigris_mobs_rat_face.png",
    },

    group = "ur-demons",
    level = 1,

    drops = {},

    habitat_nodes = {"group:stone"},

    on_init = function(self, data)
        self.hp_max = 5
        data.jump = 5
        data.speed = 4
        data.fast_speed = 4
        data.regen = 5
        data.damage = {fleshy = 2}
    end,

    start = "wander",
    script = tigris.mobs.common.hunter(nil, function(s)
        table.insert(s.flee.actions, "break_urlave_infested")
    end),
})

local break_time = 10
tigris.mobs.register_action("break_urlave_infested", {
    func = function(self, context)
        local pos = self.object:getpos()
        self.break_infested_timer = (self.break_infested_timer or break_time) + context.dtime
        if self.break_infested_timer > break_time then
            local r = vector.new(5, 3, 5)
            -- For all infested nodes in area, remove (thus triggering spawn).
            for _,pos in ipairs(minetest.find_nodes_in_area(vector.subtract(pos, r), vector.add(pos, r), {"group:tigris_mobs_urlave_infested"})) do
                minetest.remove_node(pos)
            end
            self.break_infested_timer = 0
        end
    end,
})

function tigris.mobs.register_urlave_infested(node, groups)
    local def = table.copy(minetest.registered_nodes[node])
    def.description = "Urlave Infested " .. def.description
    def.drop = ""
    def.groups = def.groups or {}
    def.groups.tigris_mobs_urlave_infested = 1
    for k,v in pairs(groups) do
        def.groups[k] = v
    end
    def.on_destruct = function(pos)
        tigris.mobs.spawn("tigris_mobs:urlave", pos)
    end
    minetest.register_node(":" .. node .. "_urlave_infested", def)
end

for _,n in ipairs{
    {"default:stone", {cracky = 1}},
} do
    tigris.mobs.register_urlave_infested(n[1], n[2])
end
