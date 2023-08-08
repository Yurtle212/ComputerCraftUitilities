local yurtle = require "yurtle"

local itemValues = {
    ["base"] = 50,
    ["minecraft:diamond"] = 100,
    ["minecraft:raw_iron"] = 75,
    ["minecraft:coal"] = 70,
    ["minecraft:raw_gold"] = 72,
    ["minecraft:emerald"] = 80,
    ["minecraft:lapis_lazuli"] = 71,
    ["minecraft:andesite"] = 55,
    ["minecraft:tuff"] = 20,
    ["minecraft:diorite"] = 20,
    ["minecraft:cobblestone"] = 40,
    ["minecraft:cobbled_deepslate"] = 39,
}

function Main(instructions, pos, dir)
    local flags = {}
    local retryTimes = 0

    print("Deployed, running instructions.")

    for i = 1, #instructions, 1 do
        if (type(instructions[i]) == "function") then
            local successful = instructions[i]()
        else
            flags[#flags+1] = instructions[i]
            print(instructions[i])
        end
        
        if not successful then
            local fuel = turtle.getFuelLevel()
            if (fuel <= 0) then
                yurtle.refuel()
                if (fuel <= 0) then
                    print("Out of fuel X(")
                    return
                end
            elseif (flags[#flags] == "returning") and (retryTimes <= 60) then
                retryTimes = retryTimes + 1
                os.startTimer(1)
                os.pullEvent("timer")
            else
                print("Unknown error")
                return
            end
        else
            retryTimes = 0
        end
    end

    print("Finished, shutting down.")
end

function Init()
    local modem = peripheral.wrap("front")
    modem.open(1)

    modem.transmit(1, 1, "awaiting instructions")
    local event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")

    print(#message.instructions .. "instructions")

    Main(message.instructions, message.pos, message.dir)
end

Init()