PZExampleMod = PZExampleMod or {}
PZExampleMod.Client = PZExampleMod.Client or {}

PZExampleMod.Client.CommandHandlers = {}

PZExampleMod.Client.CommandHandlers.syncData = function(args)
    PZExampleMod.Logger.debug("Server sync: %s", tostring(args.message))
end

PZExampleMod.Client.CommandHandlers.pong = function(args)
    PZExampleMod.Logger.debug("Pong received from server")
end

function PZExampleMod.Client.onServerCommand(module, command, args)
    if not PZExampleMod.Network.isOurModule(module) then
        return
    end
    local handler = PZExampleMod.Client.CommandHandlers[command]
    if handler then
        handler(args or {})
    else
        PZExampleMod.Logger.warn("Unhandled server command: %s", tostring(command))
    end
end
