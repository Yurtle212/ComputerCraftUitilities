os.loadAPI("json")

local params = { ... }

if next(params) == nil then
    WS = assert(http.websocket("wss://yurtle.net/cc/default"))
else
    WS = assert(http.websocket("wss://yurtle.net/cc/" .. params[1]))
end

while true do
    local raw = WS.receive()
    print(raw)
    if (raw ~= nil) then
        local signal = json.decode(raw)
        if (signal.type == "signal") then
            for key, value in pairs(signal.data.signal) do
                print("Running: " .. value)
                if (fs.exists(value[1])) then
                    shell.run(table.concat(value, " "));
                end
            end
        else
            print(signal.type)
        end
    end
end
