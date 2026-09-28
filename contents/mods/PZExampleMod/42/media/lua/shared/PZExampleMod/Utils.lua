PZExampleMod = PZExampleMod or {}

PZExampleMod.Utils = {}

function PZExampleMod.Utils.shallowcopy(source)
    local copy = {}
    for key, value in pairs(source) do
        copy[key] = value
    end
    return copy
end

function PZExampleMod.Utils.deepcopy(source)
    local copy = {}
    for key, value in pairs(source) do
        if type(value) == "table" then
            copy[key] = PZExampleMod.Utils.deepcopy(value)
        else
            copy[key] = value
        end
    end
    return copy
end

function PZExampleMod.Utils.count(t)
    local total = 0
    for _ in pairs(t) do
        total = total + 1
    end
    return total
end

function PZExampleMod.Utils.round(value, decimals)
    local multiplier = 10 ^ (decimals or 0)
    return math.floor(value * multiplier + 0.5) / multiplier
end
