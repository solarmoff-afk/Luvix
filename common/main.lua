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

require("luvix.tableUtils").init(table)

local baseWidgetFactory = require("luvix.baseWidgets.factory")

pcall(function()
    luvix = {}

    luvix.Container = require("luvix.baseWidgets.container")
    luvix.Text = baseWidgetFactory("text")
    luvix.Rect = baseWidgetFactory("rect")

    navigator.gotoScreen("application") 
end)