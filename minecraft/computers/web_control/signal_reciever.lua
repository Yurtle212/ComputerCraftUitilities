os.loadAPI("json")

local params = {...}

if next(params) == nil then
    WS = assert(http.websocket("wss://yurtle.net/cc/default"))
else
    WS = assert(http.websocket("wss://yurtle.net/cc/" .. params[1]))
end

while true do
    local raw = WS.receive()
    print(raw[1])
    local signal = json.decode(raw[1])
    if (signal.type == "signal") then
        for key, value in pairs(signal.data.signal) do
            print(value)
        end
    end
end