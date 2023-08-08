local yurtle = require "yurtle"

local modem = peripheral.wrap("front")
modem.open(1)

modem.transmit(1, 1, turtle.getFuelLevel())

os.pullEvent("modem_message")

yurtle.refuel()

modem.transmit(1, 1, "refueled")

local event, sender, message, protocol = os.pullEvent("modem_message")

if (message.equipLeft ~= nil) then
    local slot = yurtle.findItemInInventory(message.equipLeft)
    if (slot ~= nil) then
        turtle.select(slot)
        turtle.equipLeft()
    end
end

if (message.equipRight ~= nil) then
    local slot = yurtle.findItemInInventory(message.equipRight)
    if (slot ~= nil) then
        turtle.select(slot)
        turtle.equipRight()
    end
end

modem.transmit(1, 1, "equipped")