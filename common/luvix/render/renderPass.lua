local M = {}

M.currentTree = {}
M.previousTree = {}

function M.update()
    local mutations = table.findMutations(M.previousTree, M.currentTree)
    table.printMutations(mutations)
end

return M