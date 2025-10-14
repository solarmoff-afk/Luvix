local M = {}

local renderPass = require("luvix.render.renderPass")

M.gotoScreen = function(path, args)
    -- pcall(function()
        local screen = require(path)

        --
        -- TODO: Если пустой экран (без функции M.build) вывести текст "Здесь ничего нет",
        -- изображение квокки и кнопку перехода на доки
        --

        if not screen.build then
            print("BUNDLE ERROR: JUMP TO SCREEN WITHOUT BUILD FUNCTION")
            return
        end

        local widgetTree = screen.build(args)
        
        renderPass.currentTree = widgetTree
        renderPass.previousTree = {}

        renderPass.update()
    -- end)
end

return M