local players = peripheral.find("playerDetector")

while true do
    os.startTimer(1)
    os.pullEvent("timer")

    local pos1 = {x=705, y=62, z=-1511}
    local pos2 = {x=702, y=66, z=-1507}
    local result = players.isPlayersInCoords(pos1, pos2)
    print(result)
end