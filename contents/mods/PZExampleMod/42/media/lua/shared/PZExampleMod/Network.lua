PZExampleMod = PZExampleMod or {}

PZExampleMod.Network = {}

local function getModule()
    local config = PZExampleMod.Config
    if config and config.NETWORK_MODULE then
        return config.NETWORK_MODULE
    end
    return "PZExampleMod"
end

function PZExampleMod.Network.isOurModule(module)
    return module == getModule()
end

function PZExampleMod.Network.sendToServer(command, args)
    local player = getSpecificPlayer(0)
    if not player then
        return
    end
    sendClientCommand(player, getModule(), command, args or {})
end

function PZExampleMod.Network.sendToPlayer(player, command, args)
    sendServerCommand(player, getModule(), command, args or {})
end

function PZExampleMod.Network.sendToAll(command, args)
    sendServerCommand(getModule(), command, args or {})
end
