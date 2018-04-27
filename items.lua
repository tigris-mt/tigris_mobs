-- WTFPL PilzAdam Mobs - Meat
minetest.register_craftitem(":mobs:meat_raw", {
    description = "Raw Meat",
    inventory_image = "mobs_meat_raw.png",
})

minetest.register_craftitem(":mobs:meat", {
    description = "Meat",
    inventory_image = "mobs_meat.png",
    on_use = minetest.item_eat(8),
})

minetest.register_craft({
    type = "cooking",
    output = "mobs:meat",
    recipe = "mobs:meat_raw",
    cooktime = 5,
})

minetest.register_craftitem("tigris_mobs:bone", {
    description = "Bone",
    inventory_image = "tigris_mobs_bone.png",
})

minetest.register_craftitem("tigris_mobs:eye", {
    description = "Eye",
    inventory_image = "tigris_mobs_eye.png",
    on_use = minetest.item_eat(1),
})

minetest.register_craftitem("tigris_mobs:fang", {
    description = "Fang",
    inventory_image = "tigris_mobs_fang.png",
})

minetest.register_craftitem("tigris_mobs:cursed_brain", {
    description = "Cursed Brain",
    inventory_image = "tigris_mobs_cursed_brain.png",
    on_use = minetest.item_eat(1),
})

minetest.register_craftitem("tigris_mobs:water_lung", {
    description = "Water Lung",
    inventory_image = "tigris_mobs_water_lung.png",
    on_use = minetest.item_eat(1),
})
