local liana = require("luvix.render.liana")
local navigator = require("luvix.navigator")

local loader = runtime.getProcAddress()
liana.setup(loader)

local function onResize(event)
    screenWidth = event.width
    screenHeight = event.height

    liana.set_viewport(screenWidth, screenHeight)
end

-- runtime.addEventListener("enterFrame", onEnterFrame)
runtime.addEventListener("resizeWindow", onResize)

pcall(function()
    navigator.gotoScreen("application") 
end)