local params = {...}

local players = peripheral.find("playerDetector")

local pos1 = {x=tonumber(params[1]), y=tonumber(params[2]), z=tonumber(params[3])}
local pos2 = {x=tonumber(params[4]), y=tonumber(params[5]), z=tonumber(params[6])}

while true do
    os.startTimer(0.05)
    os.pullEvent("timer")

    local result = players.isPlayersInCoords(pos1, pos2)

    redstone.setOutput("back", result)

    print("tick")
end