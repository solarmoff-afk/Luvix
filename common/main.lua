-- Тестовый код просто

local ducker = require("luvix.render.ducker")

local loader = runtime.getProcAddress()

ducker.SetupGlad(loader)

local initialWidth = 800
local initialHeight = 600

ducker.Initialize(initialWidth, initialHeight)

local rectWidth = 250
local rectHeight = 150
local rectColor = {
    x = 1.0,
    y = 0.2,
    z = 0.2,
    w = 1.0
}

local function onEnterFrame(event)
    ducker.Clear()

    local rectX = 0
    local rectY = 0
    local rectBounds = {
        x = rectX,
        y = rectY + event.time * 20,
        w = 6000,
        h = event.height
    }

    local id = ducker.AddRect(
        rectBounds,
        rectColor,
        0
    )

    ducker.Render(1.0, 1.0, 1.0)
end

local function onResize(event)
    print(event.width, event.height)
    ducker.SetScreenSize(event.width, event.height)
end

runtime.addEventListener("enterFrame", onEnterFrame)
runtime.addEventListener("resizeWindow", onResize)