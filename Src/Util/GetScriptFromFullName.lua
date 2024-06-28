return function(source: string)
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