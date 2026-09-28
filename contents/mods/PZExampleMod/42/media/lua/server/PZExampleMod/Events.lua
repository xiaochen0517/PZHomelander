PZExampleMod = PZExampleMod or {}
PZExampleMod.Server = PZExampleMod.Server or {}

function PZExampleMod.Server.onGameStart()
    PZExampleMod.Server.players = PZExampleMod.Server.players or {}
    PZExampleMod.Logger.info("%s v%s server ready", PZExampleMod.Config.MOD_NAME, PZExampleMod.Config.VERSION)
end
