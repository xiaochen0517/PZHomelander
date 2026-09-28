-- B42 左侧边栏按钮：hook ISEquippedItem.initialise，在原生侧栏按钮（搬运/健康/搜寻等）末尾追加本 Mod 图标按钮
-- 点击切换 ExampleWindow；窗口开启时按钮切换为 On 图标（原生 Sidebar 纹理）

PZExampleMod = PZExampleMod or {}
PZExampleMod.UI = PZExampleMod.UI or {}

local ICON_NAME = "Client_Icon" -- 复用原版 media/ui/Sidebar/<size>/Client_Icon_On/Off_<size>.png

local function getIcon(size, suffix)
    return getTexture("media/ui/Sidebar/" .. size .. "/" .. ICON_NAME .. "_" .. suffix .. "_" .. size .. ".png")
end

local function onSidebarClick(target, button, x, y)
    PZExampleMod.UI.ExampleWindow.toggle()
end

local function appendSidebarButton(equipped)
    if equipped.PZExampleModBtn then return end
    -- 原生仅在 player 0（键鼠）时创建侧栏按钮，无 invBtn 说明是非键鼠玩家，跳过
    if not equipped.invBtn then return end

    -- 跟随玩家设置的侧栏图标尺寸（48/64/80/96/128），高度与原生按钮一致（宽 x 0.75）
    local size = equipped.invBtn.width
    local height = size * 0.75

    -- 取当前所有按钮的最大底边，追加在最后一个按钮下方（间距与原生一致：10 + 5）
    local y = 0
    for _, child in pairs(equipped:getChildren()) do
        if child.Type == "ISButton" then
            y = math.max(y, child:getBottom())
        end
    end
    if y <= 0 then return end

    local btn = ISButton:new(0, y + 15, size, height, "", equipped, onSidebarClick)
    btn:setImage(getIcon(size, "Off"))
    btn:initialise()
    btn:instantiate()
    btn:setDisplayBackground(false)
    btn:ignoreWidthChange()
    btn:ignoreHeightChange()
    equipped:addChild(btn)
    equipped:addMouseOverToolTipItem(btn, PZExampleMod.Config.MOD_NAME)
    equipped.PZExampleModBtn = btn

    -- 重算容器宽高，把新按钮纳入布局
    equipped:shrinkWrap()
end

local originalInitialise = ISEquippedItem.initialise
ISEquippedItem.initialise = function(self)
    originalInitialise(self)
    appendSidebarButton(self)
end

-- 根据窗口开闭切换 On/Off 图标（侧栏尺寸变更时对象会被销毁重建，hook initialise 会重新追加按钮）
local originalPrerender = ISEquippedItem.prerender
ISEquippedItem.prerender = function(self)
    originalPrerender(self)
    local btn = self.PZExampleModBtn
    if not btn then return end
    local window = PZExampleMod.UI.ExampleWindow
    btn:setImage(getIcon(btn.width, window.instance and "On" or "Off"))
end
