PZExampleMod = PZExampleMod or {}
PZExampleMod.UI = PZExampleMod.UI or {}

local ExampleWindow = ISPanel:derive("PZExampleMod.ExampleWindow")

function ExampleWindow:initialise()
    ISPanel.initialise(self)
end

function ExampleWindow:createChildren()
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
        ExampleWindow.onClickClose
    )
    self.closeButton:initialise()
    self:addChild(self.closeButton)
end

function ExampleWindow:onClickClose()
    self:close()
end

function ExampleWindow:close()
    self:removeFromUIManager()
    if ExampleWindow.instance == self then
        ExampleWindow.instance = nil
    end
end

function ExampleWindow:render()
    ISPanel.render(self)
    local config = PZExampleMod.Config
    self:drawText(config.MOD_NAME, 15, 15, 1, 1, 1, 1, UIFont.Medium)
    self:drawText("Version " .. config.VERSION, 15, 45, 0.8, 0.8, 0.8, 1, UIFont.Small)
    self:drawText("Click the sidebar icon to toggle this window", 15, 65, 0.6, 0.6, 0.6, 1, UIFont.Small)
end

function ExampleWindow:new(x, y, width, height)
    local o = ISPanel.new(self, x, y, width, height)
    o.backgroundColor = { r = 0.06, g = 0.06, b = 0.08, a = 0.9 }
    o.moveWithMouse = true
    return o
end

function ExampleWindow.toggle()
    if ExampleWindow.instance then
        ExampleWindow.instance:close()
        return
    end
    local width = 300
    local height = 160
    local x = (getCore():getScreenWidth() - width) / 2
    local y = (getCore():getScreenHeight() - height) / 2
    local window = ExampleWindow:new(x, y, width, height)
    window:initialise()
    window:instantiate()
    window:addToUIManager()
    ExampleWindow.instance = window
end

PZExampleMod.UI.ExampleWindow = ExampleWindow
