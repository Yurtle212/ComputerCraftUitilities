local yurtle = require "yurtle"

function Main(instructions, pos, dir)
    local flags = {}
    local retryTimes = 0

    for i = 1, #instructions, 1 do
        if (type(instructions[i]) == "function") then
            local successful = instructions[i]()
        else
            flags[#flags+1] = instructions[i]
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
end

function Init()
    local modem = peripheral.wrap("front")
    modem.open(1)

    modem.transmit(1, 1, "awaiting instructions")
    local event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")

    Main(message.instructions, message.pos, message.dir)
end

Init()