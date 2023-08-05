os.loadAPI("json")

local params = { ... }

if next(params) == nil then
    WS = assert(http.websocket("wss://yurtle.net/cc/default"))
else
    WS = assert(http.websocket("wss://yurtle.net/cc/" .. params[1]))
end

while true do
    local raw = WS.receive()
    UUID = "ccDefault"

    if (raw ~= nil) then
        local signal = json.decode(raw)
        if (signal.type == "signal") then
            for key, value in pairs(signal.data.signal) do
                print("Attempting to run: " .. table.concat(value, " "))
                if (fs.exists(value[1])) then
                    local ran = shell.run(table.concat(value, " "));
                    local ack = {
                        type = "ack",
                        data = {
                            UUID = UUID,
                            success = ran
                        },
                        timestamp = os.time()
                    }
                    WS.send(json.encode(ack))
                else
                    local ack = {
                        type = "ack",
                        data = {
                            UUID = UUID,
                            success = false
                        },
                        timestamp = os.time()
                    }
                    WS.send(json.encode(ack))
                end
            end
        elseif signal.type == "init" then
            UUID = signal.data.UUID
        end
    end
end
