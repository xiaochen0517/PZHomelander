PZExampleMod = PZExampleMod or {}
PZExampleMod.Client = PZExampleMod.Client or {}

Events.OnGameStart.Add(function()
    PZExampleMod.Client.onGameStart()
end)
