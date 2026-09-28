Homelander = Homelander or {}
Homelander.Client = Homelander.Client or {}

Events.OnGameStart.Add(function()
    Homelander.StatLocks.load()
    Homelander.Logger.info("%s v%s client ready", Homelander.Config.MOD_NAME, Homelander.Config.VERSION)
end)

Events.OnPlayerUpdate.Add(function(player)
    Homelander.StatLocks.applyTo(player)
end)
