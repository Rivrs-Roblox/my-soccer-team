return function(table: {})
    if not table then return 0 end
    local count = 0
    for _ in pairs(table) do
        count = count + 1
    end
    return count
end