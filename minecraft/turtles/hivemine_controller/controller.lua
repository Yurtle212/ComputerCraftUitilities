local params = {...}

if (params[1] ~= nil) then
    rednet.CHANNEL_BROADCAST = params[1]
end

print("Controller starting on channel" .. rednet.CHANNEL_BROADCAST .. "...")