Homelander = Homelander or {}
Homelander.UI = Homelander.UI or {}

local SettingsWindow = ISPanel:derive("Homelander.SettingsWindow")

local TITLE_FONT = UIFont.Medium
local LABEL_FONT = UIFont.Small

local TOP_MARGIN = 45
local ROW_HEIGHT = 34
local ROW_X = 15
local COL_GAP = 12
local STEP_BUTTON_WIDTH = 24
local BOTTOM_MARGIN = 15

local MODE_LABEL = { min = "At Least", max = "At Most" }

function SettingsWindow:initialise()
    ISPanel.initialise(self)
end

-- 根据字体实际渲染宽度计算各列位置，避免按钮/文字因窗口过窄而重叠或溢出
function SettingsWindow:computeLayout()
    local textManager = getTextManager()

    local enableWidth = math.max(
        textManager:MeasureStringX(LABEL_FONT, "ON"),
        textManager:MeasureStringX(LABEL_FONT, "OFF")
    ) + 20

    local labelWidth = 0
    for _, def in ipairs(Homelander.StatLocks.Definitions) do
        labelWidth = math.max(labelWidth, textManager:MeasureStringX(LABEL_FONT, def.label))
    end

    local modeWidth = math.max(
        textManager:MeasureStringX(LABEL_FONT, MODE_LABEL.min),
        textManager:MeasureStringX(LABEL_FONT, MODE_LABEL.max)
    ) + 20

    local valueWidth = textManager:MeasureStringX(LABEL_FONT, "-100.00")

    local layout = {}
    local x = ROW_X

    layout.enableX = x
    layout.enableWidth = enableWidth
    x = x + enableWidth + COL_GAP

    layout.labelX = x
    layout.labelWidth = labelWidth
    x = x + labelWidth + COL_GAP

    layout.modeX = x
    layout.modeWidth = modeWidth
    x = x + modeWidth + COL_GAP

    layout.minusX = x
    x = x + STEP_BUTTON_WIDTH + 8

    layout.valueX = x
    layout.valueWidth = valueWidth
    x = x + valueWidth + 8

    layout.plusX = x
    x = x + STEP_BUTTON_WIDTH

    layout.totalWidth = x + ROW_X
    return layout
end

function SettingsWindow:createChildren()
    ISPanel.createChildren(self)

    local layout = self:computeLayout()
    self.layout = layout

    local rowCount = #Homelander.StatLocks.Definitions
    local buttonWidth = 80
    local buttonHeight = 25

    local titleWidth = getTextManager():MeasureStringX(TITLE_FONT, Homelander.Config.MOD_NAME .. " Stat Lock Settings")
    local desiredWidth = math.max(layout.totalWidth, titleWidth + ROW_X * 2, buttonWidth + ROW_X * 2)
    local desiredHeight = TOP_MARGIN + rowCount * ROW_HEIGHT + BOTTOM_MARGIN + buttonHeight + BOTTOM_MARGIN

    if desiredWidth ~= self.width or desiredHeight ~= self.height then
        local centerX = self:getX() + self.width / 2
        local centerY = self:getY() + self.height / 2
        self:setWidth(desiredWidth)
        self:setHeight(desiredHeight)
        self:setX(centerX - desiredWidth / 2)
        self:setY(centerY - desiredHeight / 2)
    end

    self.closeButton = ISButton:new(
        self.width - buttonWidth - ROW_X,
        self.height - buttonHeight - BOTTOM_MARGIN,
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

        row.enableButton = ISButton:new(layout.enableX, y, layout.enableWidth, 24, "", self, SettingsWindow.onClickEnable)
        row.enableButton.def = def
        row.enableButton:initialise()
        self:addChild(row.enableButton)

        row.modeButton = ISButton:new(layout.modeX, y, layout.modeWidth, 24, "", self, SettingsWindow.onClickMode)
        row.modeButton.def = def
        row.modeButton:initialise()
        self:addChild(row.modeButton)

        row.minusButton = ISButton:new(layout.minusX, y, STEP_BUTTON_WIDTH, 24, "-", self, SettingsWindow.onClickStep)
        row.minusButton.def = def
        row.minusButton.delta = -def.step
        row.minusButton:initialise()
        self:addChild(row.minusButton)

        row.plusButton = ISButton:new(layout.plusX, y, STEP_BUTTON_WIDTH, 24, "+", self, SettingsWindow.onClickStep)
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
    self:drawText(Homelander.Config.MOD_NAME .. " Stat Lock Settings", ROW_X, 10, 1, 1, 1, 1, TITLE_FONT)

    local layout = self.layout
    for index, def in ipairs(Homelander.StatLocks.Definitions) do
        local y = TOP_MARGIN + (index - 1) * ROW_HEIGHT
        local setting = Homelander.StatLocks.Settings[def.key]
        self:drawText(def.label, layout.labelX, y + 4, 0.9, 0.9, 0.9, 1, LABEL_FONT)
        self:drawText(string.format("%.2f", setting.value), layout.valueX, y + 4, 0.9, 0.9, 0.9, 1, LABEL_FONT)
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
