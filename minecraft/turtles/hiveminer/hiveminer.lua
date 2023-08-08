function Main(instructions, pos, dir)
    
end

function Init()
    local modem = peripheral.wrap("front")
    modem.open(1)

    modem.transmit(1, 1, "awaiting instructions")
    local event, sender, message, protocol = os.pullEvent("modem_message")

    main(message.instructions, message.pos, message.dir)
end

Init()