local params = {...}

local players = peripheral.find("playerDetector")

while true do
    os.startTimer(1)
    os.pullEvent("timer")

    local pos1 = {x=params[0], y=params[1], z=params[2]}
    local pos2 = {x=params[3], y=params[4], z=params[5]}
    local result = players.isPlayersInCoords(pos1, pos2)

    redstone.setOutput("back", result)

    print("tick")
end