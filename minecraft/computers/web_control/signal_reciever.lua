os.loadAPI("json")

local params = {...}

print(params)

if next(params) == nil then
    WS = assert(http.websocket("wss://yurtle.net/cc/default"))
else
    WS = assert(http.websocket("wss://yurtle.net/cc/" .. params[1]))
end

while true do
    local signal = json.decode(WS.receive())
    if (signal.type == "signal") then
        for key, value in pairs(signal.data.signal) do
            print(value)
        end
    end
end