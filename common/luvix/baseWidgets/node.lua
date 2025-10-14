local M = {}

local NodePrototype = {}

function M.createHandle(rawWidget, isContainer)
	rawWidget.isContainer = isContainer or false
	
	local handle = {
		_internal = rawWidget
	}
	
	rawWidget.handle = handle

	local metatable = {
		__index = function(t, k)
			if NodePrototype[k] then
				return NodePrototype[k]
			end
			
			return t._internal[k]
		end,

		__newindex = function(t, k, v)
			if t._internal[k] ~= v then
				t._internal[k] = v
			end
		end
	}

	setmetatable(handle, metatable)
	return handle
end

return M