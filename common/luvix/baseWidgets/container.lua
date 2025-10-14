local node = require("luvix.baseWidgets.node")

return function(props)
	local rawNode = {
        type = "container", children = {}
    }

	props = props or {}
	props.layout = props.layout or {}

	for key, value in pairs(props) do
		rawNode[key] = value
	end

	return node.createHandle(rawNode, true)
end