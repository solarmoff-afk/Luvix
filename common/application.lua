return {
    build = function(args)
        return luvix.Container {
            children = {
                luvix.Text { text = "Hello world" }
            }
        }
    end
}