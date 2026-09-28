Homelander = Homelander or {}
Homelander.UI = Homelander.UI or {}

local SettingsWindow = ISPanel:derive("Homelander.SettingsWindow")

local ROW_HEIGHT = 32
local TOP_MARGIN = 45
local ROW_X = 10

local MODE_LABEL = { min = "At Least", max = "At Most" }

function SettingsWindow:initialise()
    ISPanel.initialise(self)
end

function SettingsWindow:createChildren()
    ISPanel.createChildren(self)

    local buttonWidth = 80
    local buttonHeight = 25
    self.closeButton = ISButton:new(
        self.width - buttonWidth - 10,
        self.height - buttonHeight - 10,
        buttonWidth,
        buttonHeight,
        "Close",
        self,
        SettingsWindow.onClickClose
    )
    self.closeButton:initialise()
    self:addChild(self.closeButton)

    self.rows = {}
    for index, def in ipairs(Homelander.StatLocks.Definitions) do
        local y = TOP_MARGIN + (index - 1) * ROW_HEIGHT
        local row = {}

        row.enableButton = ISButton:new(ROW_X, y, 70, 24, "", self, SettingsWindow.onClickEnable)
        row.enableButton.def = def
        row.enableButton:initialise()
        self:addChild(row.enableButton)

        row.modeButton = ISButton:new(ROW_X + 170, y, 70, 24, "", self, SettingsWindow.onClickMode)
        row.modeButton.def = def
        row.modeButton:initialise()
        self:addChild(row.modeButton)

        row.minusButton = ISButton:new(ROW_X + 250, y, 24, 24, "-", self, SettingsWindow.onClickStep)
        row.minusButton.def = def
        row.minusButton.delta = -def.step
        row.minusButton:initialise()
        self:addChild(row.minusButton)

        row.plusButton = ISButton:new(ROW_X + 310, y, 24, 24, "+", self, SettingsWindow.onClickStep)
        row.plusButton.def = def
        row.plusButton.delta = def.step
        row.plusButton:initialise()
        self:addChild(row.plusButton)

        self.rows[index] = row
    end

    self:refreshButtons()
end

function SettingsWindow:refreshButtons()
    for _, row in ipairs(self.rows) do
        local setting = Homelander.StatLocks.Settings[row.enableButton.def.key]
        row.enableButton:setTitle(setting.enabled and "ON" or "OFF")
        row.modeButton:setTitle(MODE_LABEL[setting.mode])
    end
end

function SettingsWindow:onClickEnable(button)
    local setting = Homelander.StatLocks.Settings[button.def.key]
    setting.enabled = not setting.enabled
    Homelander.StatLocks.save()
    self:refreshButtons()
end

function SettingsWindow:onClickMode(button)
    local setting = Homelander.StatLocks.Settings[button.def.key]
    setting.mode = (setting.mode == "min") and "max" or "min"
    Homelander.StatLocks.save()
    self:refreshButtons()
end

function SettingsWindow:onClickStep(button)
    local def = button.def
    local setting = Homelander.StatLocks.Settings[def.key]
    local value = setting.value + button.delta
    if value < def.min then value = def.min end
    if value > def.max then value = def.max end
    setting.value = value
    Homelander.StatLocks.save()
end

function SettingsWindow:onClickClose()
    self:close()
end

function SettingsWindow:close()
    self:removeFromUIManager()
    if SettingsWindow.instance == self then
        SettingsWindow.instance = nil
    end
end

function SettingsWindow:render()
    ISPanel.render(self)
    self:drawText(Homelander.Config.MOD_NAME .. " Stat Lock Settings", 10, 10, 1, 1, 1, 1, UIFont.Medium)

    for index, def in ipairs(Homelander.StatLocks.Definitions) do
        local y = TOP_MARGIN + (index - 1) * ROW_HEIGHT
        local setting = Homelander.StatLocks.Settings[def.key]
        self:drawText(def.label, ROW_X + 90, y + 4, 0.9, 0.9, 0.9, 1, UIFont.Small)
        self:drawText(tostring(setting.value), ROW_X + 278, y + 4, 0.9, 0.9, 0.9, 1, UIFont.Small)
    end
end

function SettingsWindow:new(x, y, width, height)
    local o = ISPanel.new(self, x, y, width, height)
    o.backgroundColor = { r = 0.06, g = 0.06, b = 0.08, a = 0.9 }
    o.moveWithMouse = true
    return o
end

function SettingsWindow.toggle()
    if SettingsWindow.instance then
        SettingsWindow.instance:close()
        return
    end
    local width = 370
    local height = 260
    local x = (getCore():getScreenWidth() - width) / 2
    local y = (getCore():getScreenHeight() - height) / 2
    local window = SettingsWindow:new(x, y, width, height)
    window:initialise()
    window:instantiate()
    window:addToUIManager()
    SettingsWindow.instance = window
end

Homelander.UI.SettingsWindow = SettingsWindow
