local yurtle = require "yurtle"
local movement = require "movement"

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
            flags[#flags + 1] = instructions[i]
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

    local fullInstructions = {}
    local pos
    local dir

    local i = 0

    while true do
        modem.transmit(1, 1, "awaiting instructions")
        local event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")

        -- for key, value in pairs(message) do
        --     print("\n")
        --     print(key)
        --     print(value)
        --     if (type(value) == "table") then
        --         print(#value)
        --     end
        -- end

        fullInstructions = movement.TableConcat(fullInstructions, message.moveInstructions)

        if not message.more then
            pos = message.pos
            dir = message.dir
        end

        i = i + 1
        print("packet " .. i)
    end

    print(#message.moveInstructions .. " instructions")

    Main(fullInstructions, message.position, message.direction)
end

Init()
