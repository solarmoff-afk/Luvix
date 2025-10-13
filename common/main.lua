local liana = require("luvix.render.liana")

local loader = runtime.getProcAddress()
liana.setup(loader)

local screenWidth, screenHeight = 800, 600

local font_regular = liana.liana_load_font("font.ttf", 16)
if not font_regular then
    return
end

local rectId = liana.new_rect({
    x = 50, y = 50,
    w = 150, h = 100,
    color = {r = 0.2, g = 0.4, b = 1.0, a = 1.0},
    z = 0.0
})
liana.set_rounded(rectId, 20, 20, 20, 20)

local textId = liana.new_text({
    x = 100, y = 400,
    w = 600, h = 50,
    color = {r = 1.0, g = 1.0, b = 1.0, a = 1.0},
    z = 10.0,
    text = "Hello liana!",
    font = font_regular
})

local a = 0
local function onEnterFrame(event)
    a = a + 0.01

    local r = 0.5 + math.sin(a * 2.0) * 0.5
    liana.config_color(rectId, r, 0.5, 0.5 + math.cos(a * 2.0) * 0.5, 1.0)
    
    liana.render(1, 1, 1, 1)
end

local function onResize(event)
    screenWidth = event.width
    screenHeight = event.height

    liana.set_viewport(screenWidth, screenHeight)
end

runtime.addEventListener("enterFrame", onEnterFrame)
runtime.addEventListener("resizeWindow", onResize)