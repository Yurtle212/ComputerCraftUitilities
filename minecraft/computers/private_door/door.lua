local params = {...}

local players = peripheral.find("playerDetector")

local pos1 = {x=tonumber(params[0]), y=tonumber(params[1]), z=tonumber(params[2])}
local pos2 = {x=tonumber(params[3]), y=tonumber(params[4]), z=tonumber(params[5])}

while true do
    os.startTimer(1)
    os.pullEvent("timer")

    local result = players.isPlayersInCoords(pos1, pos2)

    redstone.setOutput("back", result)

    print("tick")
end