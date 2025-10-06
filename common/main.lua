local liana = require("test_liana")
print("LianaGL module loaded successfully.")

local loader = runtime.getProcAddress()
if not loader then
    error("Host 'runtime' object did not provide getProcAddress function")
end

liana.setup(loader)
liana.init()
print("LianaGL initialized.")

local pattern_tex = {
    id = liana.load_texture("assets/pattern.png"),
    w = 256,
    h = 256
}

local character_tex = {
    id = liana.load_texture("assets/character.jpeg"),
    w = 512,
    h = 512
}

local a = 0
local function onEnterFrame(event)
    a = a + 0.01
    local time = a

    liana.add_rect(50, 50, 0.5, 150, 100, 
        {r=1, g=0, b=0, a=1}, 
        {tl=20, tr=20, br=0, bl=20}
    )

    local bg_w, bg_h = 400, 300
    local bg_id = liana.add_rect(200, 150, 0.9, bg_w, bg_h,
        {r=1, g=1, b=1, a=0.5}
    )

    local obj_aspect = bg_w / bg_h
    local tex_aspect = pattern_tex.w / pattern_tex.h
    
    local uv_scale = {x=1, y=1}
    if obj_aspect > tex_aspect then
        uv_scale.x = obj_aspect / tex_aspect
    else
        uv_scale.y = tex_aspect / obj_aspect
    end

    liana.set_texture(bg_id, pattern_tex.id, {
        scale = uv_scale
    })
    
    local circle_size = 120
    local circle_id = liana.add_rect(10, 200, 0.2, circle_size, circle_size, 
        {r=1, g=1, b=1, a=1},
        {tl=60, tr=60, br=60, bl=60}
    )

    liana.set_texture(circle_id, character_tex.id, {
        scale = {x=1.5, y=1.5},
        offset = {x=-0.25, y=-0.25},
        rotation = time
    })


    liana.render(event.width, event.height)
end

local function onResize(event)
    liana.setViewport(event.width, event.height)
end

runtime.addEventListener("enterFrame", onEnterFrame)
runtime.addEventListener("resizeWindow", onResize)

local initialWidth = 800
local initialHeight = 600
liana.setViewport(initialWidth, initialHeight)

-- garbagecollector("stop")