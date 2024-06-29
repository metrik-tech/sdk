return function(source: string)
    if not source then
        return nil
    end

    local base = game
    local parts = string.split(source, ".")

    for _, part in parts do
        base = base:FindFirstChild(part)

        if not base then
            return nil
        end
    end

    return base
end