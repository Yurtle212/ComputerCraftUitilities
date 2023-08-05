local params = {...}

print(params)

local ws

if next(params) == nil then
    ws = http.websocket("wss://yurtle.net/cc/default")
else
    ws = http.websocket("wss://yurtle.net/cc/" .. params[1])
end