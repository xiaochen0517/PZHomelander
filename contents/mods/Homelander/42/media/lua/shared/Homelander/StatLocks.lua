Homelander = Homelander or {}
Homelander.StatLocks = Homelander.StatLocks or {}

local StatLocks = Homelander.StatLocks

-- 状态定义：每项包含取值范围、默认方向/数值、单步调整量，以及 get/set 访问器
-- min 方向 = 不低于（当前值 < 设定值才纠正），max 方向 = 不高于（当前值 > 设定值才纠正）
-- overallBodyHealth 每 tick 由各 BodyPart.health 重新汇总计算得出，只锁总值会被下一次汇总覆盖，
-- 所以锁定它时必须同步把各部位血量也钳制到同一下限（见 属性锁定与免死方案分析.md 一/二节）
StatLocks.Definitions = {
    {
        key = "health", label = "Health",
        min = 0, max = 1, step = 0.1,
        defaultMode = "min", defaultValue = 0.3,
        get = function(player) return player:getHealth() end,
        set = function(player, value) player:setHealth(value) end,
    },
    {
        key = "overallBodyHealth", label = "Overall Health",
        min = 0, max = 100, step = 10,
        defaultMode = "min", defaultValue = 30,
        get = function(player) return player:getBodyDamage():getOverallBodyHealth() end,
        set = function(player, value)
            local bodyDamage = player:getBodyDamage()
            bodyDamage:setOverallBodyHealth(value)
            local parts = bodyDamage:getBodyParts()
            for i = 0, parts:size() - 1 do
                local part = parts:get(i)
                if part:getHealth() < value then
                    part:SetHealth(value)
                end
            end
        end,
    },
    {
        key = "hunger", label = "Hunger",
        min = 0, max = 1, step = 0.1,
        defaultMode = "max", defaultValue = 0.8,
        get = function(player) return player:getStats():get(CharacterStat.HUNGER) end,
        set = function(player, value) player:getStats():set(CharacterStat.HUNGER, value) end,
    },
    {
        key = "thirst", label = "Thirst",
        min = 0, max = 1, step = 0.1,
        defaultMode = "max", defaultValue = 0.8,
        get = function(player) return player:getStats():get(CharacterStat.THIRST) end,
        set = function(player, value) player:getStats():set(CharacterStat.THIRST, value) end,
    },
    {
        key = "fatigue", label = "Fatigue",
        min = 0, max = 1, step = 0.1,
        defaultMode = "max", defaultValue = 0.8,
        get = function(player) return player:getStats():get(CharacterStat.FATIGUE) end,
        set = function(player, value) player:getStats():set(CharacterStat.FATIGUE, value) end,
    },
}

-- 当前设置：Settings[key] = { enabled = bool, mode = "min"/"max", value = number }
StatLocks.Settings = {}

function StatLocks.resetToDefaults()
    StatLocks.Settings = {}
    for _, def in ipairs(StatLocks.Definitions) do
        StatLocks.Settings[def.key] = {
            enabled = false,
            mode = def.defaultMode,
            value = def.defaultValue,
        }
    end
end

function StatLocks.load()
    StatLocks.resetToDefaults()

    local fileName = Homelander.Config.SETTINGS_FILE
    local ok, reader = pcall(getFileReader, fileName, false)
    if not ok or not reader then
        return
    end

    while true do
        local okLine, line = pcall(function() return reader:readLine() end)
        if not okLine or not line then
            break
        end
        local key, field, rawValue = line:match("^(%a+)%.(%a+)=(.+)$")
        if key and StatLocks.Settings[key] then
            if field == "enabled" then
                StatLocks.Settings[key].enabled = (rawValue == "1")
            elseif field == "mode" then
                StatLocks.Settings[key].mode = rawValue
            elseif field == "value" then
                StatLocks.Settings[key].value = tonumber(rawValue) or StatLocks.Settings[key].value
            end
        end
    end
    pcall(function() reader:close() end)
end

function StatLocks.save()
    local fileName = Homelander.Config.SETTINGS_FILE
    local ok, writer = pcall(getFileWriter, fileName, true, false)
    if not ok or not writer then
        Homelander.Logger.warn("Failed to write settings file %s", fileName)
        return
    end

    for _, def in ipairs(StatLocks.Definitions) do
        local setting = StatLocks.Settings[def.key]
        writer:writeln(def.key .. ".enabled=" .. (setting.enabled and "1" or "0"))
        writer:writeln(def.key .. ".mode=" .. setting.mode)
        writer:writeln(def.key .. ".value=" .. tostring(setting.value))
    end
    writer:close()
end

-- 每 tick 对目标玩家做越界纠正；只在超出阈值时写回，阈值内的正常波动不受影响
function StatLocks.applyTo(player)
    if not player then
        return
    end
    for _, def in ipairs(StatLocks.Definitions) do
        local setting = StatLocks.Settings[def.key]
        if setting and setting.enabled then
            local current = def.get(player)
            if setting.mode == "min" and current < setting.value then
                def.set(player, setting.value)
            elseif setting.mode == "max" and current > setting.value then
                def.set(player, setting.value)
            end
        end
    end
end
