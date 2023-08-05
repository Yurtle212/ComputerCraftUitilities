os.loadAPI("json")

local params = {...}

print(params)

local ws

if next(params) == nil then
    ws = http.websocket("wss://yurtle.net/cc/default")
else
    ws = http.websocket("wss://yurtle.net/cc/" .. params[1])
end

while true do
    local signal = json.decode(ws.receive())
    if (signal.type == "signal") then
        for key, value in pairs(signal.data.signal) do
            print(value)
        end
    end
end