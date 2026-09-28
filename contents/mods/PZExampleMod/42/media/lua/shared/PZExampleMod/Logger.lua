PZExampleMod = PZExampleMod or {}

PZExampleMod.Logger = {}

local function getModId()
    local config = PZExampleMod.Config
    if config and config.MOD_ID then
        return config.MOD_ID
    end
    return "PZExampleMod"
end

local function formatMessage(message, ...)
    if select("#", ...) > 0 then
        return string.format(tostring(message), ...)
    end
    return tostring(message)
end

function PZExampleMod.Logger.raw(prefix, message, ...)
    print("[" .. prefix .. "] " .. formatMessage(message, ...))
end

function PZExampleMod.Logger.debug(message, ...)
    local config = PZExampleMod.Config
    if config and config.DEBUG then
        PZExampleMod.Logger.raw(getModId() .. ":DEBUG", message, ...)
    end
end

function PZExampleMod.Logger.info(message, ...)
    PZExampleMod.Logger.raw(getModId() .. ":INFO", message, ...)
end

function PZExampleMod.Logger.warn(message, ...)
    PZExampleMod.Logger.raw(getModId() .. ":WARN", message, ...)
end

function PZExampleMod.Logger.error(message, ...)
    PZExampleMod.Logger.raw(getModId() .. ":ERROR", message, ...)
end
