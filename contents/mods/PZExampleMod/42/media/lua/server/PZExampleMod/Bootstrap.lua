PZExampleMod = PZExampleMod or {}
PZExampleMod.Server = PZExampleMod.Server or {}

Events.OnGameStart.Add(function()
    PZExampleMod.Server.onGameStart()
end)
