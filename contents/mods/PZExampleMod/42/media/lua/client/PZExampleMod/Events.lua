PZExampleMod = PZExampleMod or {}
PZExampleMod.Client = PZExampleMod.Client or {}

function PZExampleMod.Client.onGameStart()
    PZExampleMod.Logger.info("%s v%s client ready", PZExampleMod.Config.MOD_NAME, PZExampleMod.Config.VERSION)
end
