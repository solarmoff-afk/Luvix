print("Hello world!")

-- runtime.addEventListener("enterFrame", function(event)
--     print(123)
-- end)

runtime.addEventListener("resizeWindow", function(event)
    print(event.width)
    print(event.height)
end)

print(1)