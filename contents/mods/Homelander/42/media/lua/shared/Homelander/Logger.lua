Homelander = Homelander or {}

Homelander.Logger = {}

local function getModId()
    local config = Homelander.Config
    if config and config.MOD_ID then
        return config.MOD_ID
    end
    return "Homelander"
end

local function formatMessage(message, ...)
    if select("#", ...) > 0 then
        return string.format(tostring(message), ...)
    end
    return tostring(message)
end

function Homelander.Logger.raw(prefix, message, ...)
    print("[" .. prefix .. "] " .. formatMessage(message, ...))
end

function Homelander.Logger.debug(message, ...)
    local config = Homelander.Config
    if config and config.DEBUG then
        Homelander.Logger.raw(getModId() .. ":DEBUG", message, ...)
    end
end

function Homelander.Logger.info(message, ...)
    Homelander.Logger.raw(getModId() .. ":INFO", message, ...)
end

function Homelander.Logger.warn(message, ...)
    Homelander.Logger.raw(getModId() .. ":WARN", message, ...)
end

function Homelander.Logger.error(message, ...)
    Homelander.Logger.raw(getModId() .. ":ERROR", message, ...)
end
