return { init = function(object)
    function object.copy(source, seen_copies)
        if type(source) ~= "table" then
            return source
        end
        
        seen_copies = seen_copies or {}
        
        if seen_copies[source] then
            return seen_copies[source]
        end
        
        local copy = {}
        seen_copies[source] = copy
        
        for key, value in pairs(source) do
            copy[object.copy(key, seen_copies)] = object.copy(value, seen_copies)
        end
        
        local mt = getmetatable(source)
        if mt then
            setmetatable(copy, object.copy(mt, seen_copies))
        end
        
        return copy
    end    

    function object.findMutations(oldTree, newTree)
        if oldTree == newTree then
            return {}
        end
        
        local mutations = {}
        local stack = {}
        local stackSize = 0
        
        stackSize = stackSize + 1
        stack[stackSize] = {oldNode = oldTree, newNode = newTree, path = "1"}
        
        while stackSize > 0 do
            local current = stack[stackSize]
            stackSize = stackSize - 1
            
            local oldWidget = current.oldNode and (current.oldNode._internal or current.oldNode)
            local newWidget = current.newNode and (current.newNode._internal or current.newNode)
            
            local oldIsWidget = oldWidget and oldWidget.type ~= nil
            local newIsWidget = newWidget and newWidget.type ~= nil
            
            if not oldIsWidget and newIsWidget then
                mutations[#mutations + 1] = {
                    action = "add", 
                    widget = newWidget, 
                    path = current.path
                }
                
                if newWidget.children then
                    for i = #newWidget.children, 1, -1 do
                        local childPath = current.path .. "." .. tostring(i)
                        stackSize = stackSize + 1
                        stack[stackSize] = { oldNode = nil, newNode = newWidget.children[i], path = childPath }
                    end
                end
            elseif oldIsWidget and not newIsWidget then
                mutations[#mutations + 1] = {
                    action = "remove", 
                    widget = oldWidget, 
                    path = current.path
                }
            elseif oldIsWidget and newIsWidget then
                local propertyChanges = {}
                
                for k, v in pairs(oldWidget) do
                    if k ~= "handle" and k ~= "_internal" and k ~= "children" and k ~= "key" then
                        if newWidget[k] ~= v then
                            propertyChanges[k] = {old = v, new = newWidget[k]}
                        end
                    end
                end

                for k, v in pairs(newWidget) do
                    if k ~= "handle" and k ~= "_internal" and k ~= "children" and k ~= "key" then
                        if oldWidget[k] ~= v and not propertyChanges[k] then
                            propertyChanges[k] = {old = oldWidget[k], new = v}
                        end
                    end
                end
                
                if next(propertyChanges) then
                    mutations[#mutations + 1] = {
                        action = "edit", 
                        widget = newWidget, 
                        path = current.path,
                        propertyChanges = propertyChanges
                    }
                end
                
                local oldChildren = oldWidget.children
                local newChildren = newWidget.children
                
                if oldChildren or newChildren then
                    local oldChildrenMap = {}
                    
                    if oldChildren then
                        for i, child in ipairs(oldChildren) do
                            local childWidget = child._internal or child
                            local key = childWidget.key or tostring(i)
                            
                            oldChildrenMap[key] = {node = child, index = i}
                        end
                    end
    
                    local newKeys = {}
                    if newChildren then
                        for i, newChild in ipairs(newChildren) do
                            local newChildWidget = newChild._internal or newChild
                            local key = newChildWidget.key or tostring(i)
                            
                            newKeys[key] = true
                        end
                    end
    
                    for key, oldChildData in pairs(oldChildrenMap) do
                        if not newKeys[key] then
                            mutations[#mutations + 1] = { 
                                action = "remove",
                                widget = oldChildData.node._internal or oldChildData.node,
                                path = current.path .. "." .. tostring(oldChildData.index)
                            }
                        end
                    end
    
                    local lastPlacedIndex = 0
                    if newChildren then
                        for i, newChild in ipairs(newChildren) do
                            local newChildWidget = newChild._internal or newChild
                            local key = newChildWidget.key or tostring(i)
                            local oldChildData = oldChildrenMap[key]
                            local childPath = current.path .. "." .. tostring(i)
    
                            if oldChildData then
                                if oldChildData.index < lastPlacedIndex then
                                    mutations[#mutations + 1] = {
                                        action = "move",
                                        widget = newChildWidget,
                                        path = childPath,
                                        key = key
                                    }
                                end
                                lastPlacedIndex = math.max(lastPlacedIndex, oldChildData.index)
    
                                stackSize = stackSize + 1
                                stack[stackSize] = { oldNode = oldChildData.node, newNode = newChild, path = childPath }
                            else
                                mutations[#mutations + 1] = {
                                    action = "add",
                                    widget = newChildWidget,
                                    path = childPath
                                }
                                
                                stackSize = stackSize + 1
                                stack[stackSize] = { oldNode = nil, newNode = newChild, path = childPath }
                            end
                        end
                    end
                end
            end
        end
        
        return mutations
    end

    function object.valueToString(widget)
        local parts = {}
        
        for k, v in pairs(widget) do
            if k ~= "handle" and k ~= "_internal" and k ~= "children" then
                if type(v) == "string" then
                    parts[#parts + 1] = k .. ' = "' .. v .. '"'
                else
                    parts[#parts + 1] = k .. " = " .. tostring(v)
                end
            end
        end
        
        if widget.children then
            parts[#parts + 1] = "children:"
        end
        
        return table.concat(parts, " ")
    end

    function object.printMutations(mutations)
        for i = 1, #mutations do
            local mutation = mutations[i]
            local pathParts = {}
            
            for part in mutation.path:gmatch("[^.]+") do
                pathParts[#pathParts + 1] = part
            end
            
            local indent = string.rep("  ", #pathParts - 1)
            
            if mutation.action == "add" then
                print(indent .. "ADD " .. object.valueToString(mutation.widget))
            elseif mutation.action == "remove" then
                print(indent .. "REMOVE " .. object.valueToString(mutation.widget))
            elseif mutation.action == "edit" then
                print(indent .. "EDIT " .. object.valueToString(mutation.widget))
            end
        end
    end
end }