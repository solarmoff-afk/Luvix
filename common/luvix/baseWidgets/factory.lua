local node = require("luvix.baseWidgets.node")

return function(widgetType)
    return function(props)
        local rawText = { type = widgetType }
        props = props or {}

        for key, value in pairs(props) do
            rawText[key] = value
        end
        
        return node.createHandle(rawText, false)
    end
end