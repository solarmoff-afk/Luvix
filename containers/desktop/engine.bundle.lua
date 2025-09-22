print("Hello world!")

local id1

id1 = runtime.addEventListener("enterFrame", function(event)
    print(event.time)
    
    if event.time > 2 then
        runtime.removeEventListener("enterFrame", id1)
    end
end)

local id2 = runtime.addEventListener("resizeWindow", function(event)
    print(event.width)
    print(event.height)
end)

print(id1, id2)

print(utf8)