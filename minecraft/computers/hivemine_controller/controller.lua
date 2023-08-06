local params = {...}

if (params[1] ~= nil) then
    rednet.CHANNEL_BROADCAST = params[1]
end

