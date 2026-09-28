PZExampleMod = PZExampleMod or {}
PZExampleMod.Server = PZExampleMod.Server or {}

PZExampleMod.Server.CommandHandlers = {}

PZExampleMod.Server.CommandHandlers.requestInit = function(player, args)
    PZExampleMod.Logger.debug("Init requested by %s", player:getUsername())
    PZExampleMod.Network.sendToPlayer(player, "syncData", {
        message = "Hello from " .. PZExampleMod.Config.MOD_NAME .. " server",
    })
end

PZExampleMod.Server.CommandHandlers.ping = function(player, args)
    PZExampleMod.Network.sendToPlayer(player, "pong", {})
end

function PZExampleMod.Server.onClientCommand(module, command, player, args)
    if not PZExampleMod.Network.isOurModule(module) then
        return
    end
    local handler = PZExampleMod.Server.CommandHandlers[command]
    if handler then
        handler(player, args or {})
    else
        PZExampleMod.Logger.warn("Unhandled client command: %s", tostring(command))
    end
end
