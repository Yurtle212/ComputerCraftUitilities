os.loadAPI("json")

function UpdateSetup(channel)
    shell.run("delete disk/setup")
    shell.run(
        "wget https://raw.githubusercontent.com/Yurtle212/ComputerCraftUitilities/main/minecraft/turtles/hivemine/setup.lua disk/setup.lua")
end

function Initialize()
    Config = json.decodeFromFile("config.json")

    if (gps.locate()) then
        Position = vector.new(gps.locate())
    else
        Position = vector.new(Config["NOGPS_position"][1], Config["NOGPS_position"][2], Config["NOGPS_position"][3])
    end

    SpawnLoc = Position
    if (Config["heading"] == "north") then
        SpawnLoc.z = SpawnLoc.z - 1
    elseif Config["heading"] == "south" then
        SpawnLoc.z = SpawnLoc.z + 1
    elseif Config["heading"] == "west" then
        SpawnLoc.x = SpawnLoc.x - 1
    else
        SpawnLoc.x = SpawnLoc.x + 1
    end

    print("Controller started")
end

function GetMiningSubdivisions(pos1, pos2, subdivisionsX, subdivisionsZ)
    local wholeSize = pos1:sub(pos2)
    wholeSize = vector.new(math.abs(wholeSize.x), math.abs(wholeSize.y), math.abs(wholeSize.z))
    local subdivisionSize = vector.new(math.floor((wholeSize.x / subdivisionsX) + 0.5), wholeSize.y,
        math.floor((wholeSize.z / subdivisionsZ) + 0.5))
    -- print("Subdivision Edges: (x:" .. subdivisionSize.x .. ", y:" .. subdivisionSize.y  .. ", z:" .. subdivisionSize.z .. ")")

    local subdivisions = {}
    for x = 1, subdivisionsX, 1 do
        for z = 1, subdivisionsZ, 1 do
            local index = (x * (subdivisionsZ - 1)) + z
            subdivisions[index] = {
                startPos = vector.new(subdivisionSize.x * (x - 1), 0, subdivisionSize.z * (z - 1)),
                endPos = vector.new((subdivisionSize.x * (x - 1)) + subdivisionSize.x, subdivisionSize.y,
                    (subdivisionSize.z * (z - 1)) + subdivisionSize.z)
            }

            if (x < subdivisionsX) then
                subdivisions[index].endPos.x = subdivisions[index].endPos.x - 1
            end

            if (z < subdivisionsZ) then
                subdivisions[index].endPos.z = subdivisions[index].endPos.z - 1
            end

            print(json.encode(subdivisions[index]))
        end
    end
    return subdivisions
end

local headings = {
    north = 1,
    west = 2,
    south = 3,
    east = 4,
}

local function turnDirection(dir, turn)
    local retVal
    if (turn == "left") then
        retVal = turtle.turnLeft
        dir = dir - 1
    else
        retVal = turtle.turnRight
        dir = dir + 1
    end

    if (dir <= 0) then
        dir = 4
    elseif (dir >= 5) then
        dir = 1
    end

    return dir, retVal
end

local function move(pos, way, dir)
    local retVal

    if way == "forward" then
        retVal = turtle.forward
        if dir == 1 then
            pos.z = pos.z - 1
        elseif dir == 2 then
            pos.x = pos.x - 1
        elseif dir == 3 then
            pos.z = pos.z + 1
        elseif dir == 3 then
            pos.x = pos.x + 1
        end
    elseif way == "up" then
        retVal = turtle.up
        pos.y = pos.y + 1
    else
        retVal = turtle.down
        pos.y = pos.y - 1
    end

    return pos, retVal
end

function CalculateMiningPaths(startPos, subdivisions)
    for key, value in pairs(subdivisions) do
        value.instructions = {}
        local instructionsIndex = 1

        local dir = 1
        local pos = vector.new(0,0,0)

        local distFromStart = value.startPos:sub(startPos)

        while dir ~= 1 do
            dir, value.instructions[instructionsIndex] = turnDirection(dir, "left")
            instructionsIndex = instructionsIndex + 1
        end

        local baseStartDir = dir
        local baseStartPos = pos

        -- go to assigned area

        if distFromStart.z < 0 then
            dir, value.instructions[instructionsIndex] = turnDirection(dir, "left")
            instructionsIndex = instructionsIndex + 1
            dir, value.instructions[instructionsIndex] = turnDirection(dir, "left")
            instructionsIndex = instructionsIndex + 1
        end

        for z = 1, math.abs(distFromStart.z), 1 do
            pos, value.instructions[instructionsIndex] = move(pos, "forward", dir)
            instructionsIndex = instructionsIndex + 1
        end

        if distFromStart.x < 0 then
            dir, value.instructions[instructionsIndex] = turnDirection(dir, "left")
            instructionsIndex = instructionsIndex + 1
        else
            dir, value.instructions[instructionsIndex] = turnDirection(dir, "right")
            instructionsIndex = instructionsIndex + 1
        end

        for x = 1, math.abs(distFromStart.x), 1 do
            pos, value.instructions[instructionsIndex] = move(pos, "forward", dir)
            instructionsIndex = instructionsIndex + 1
        end

        while dir ~= 1 do
            dir, value.instructions[instructionsIndex] = turnDirection(dir, "left")
            instructionsIndex = instructionsIndex + 1
        end

        local turnLeft = true

        -- local blockAmount = (value.endPos.x - value.startPos.x) * (value.endPos.y - value.startPos.y) * (value.endPos.z - value.startPos.z)
        local xDist = (value.endPos.x - value.startPos.x)
        local yDist = (value.endPos.y - value.startPos.y)
        local zDist = (value.endPos.z - value.startPos.z)
        local amount = xDist * yDist * zDist

        local startDir = dir

        -- return to start location

        local dirToBaseStart = pos:sub(baseStartPos)

        while dir ~= 1 do
            dir, value.instructions[instructionsIndex] = turnDirection(dir, "left")
            instructionsIndex = instructionsIndex + 1
        end

        if dirToBaseStart.z < 0 then
            dir, value.instructions[instructionsIndex] = turnDirection(dir, "left")
            instructionsIndex = instructionsIndex + 1
            dir, value.instructions[instructionsIndex] = turnDirection(dir, "left")
            instructionsIndex = instructionsIndex + 1
        end

        for z = 1, math.abs(dirToBaseStart.z), 1 do
            pos, value.instructions[instructionsIndex] = move(pos, "forward", dir)
            instructionsIndex = instructionsIndex + 1
        end

        if dirToBaseStart.x < 0 then
            dir, value.instructions[instructionsIndex] = turnDirection(dir, "left")
            instructionsIndex = instructionsIndex + 1
        else
            dir, value.instructions[instructionsIndex] = turnDirection(dir, "right")
            instructionsIndex = instructionsIndex + 1
        end

        for x = 1, math.abs(dirToBaseStart.x), 1 do
            pos, value.instructions[instructionsIndex] = move(pos, "forward", dir)
            instructionsIndex = instructionsIndex + 1
        end

        while dir ~= 1 do
            dir, value.instructions[instructionsIndex] = turnDirection(dir, "left")
            instructionsIndex = instructionsIndex + 1
        end

        for i = 1, amount, 1 do
            -- print(value.instructions[i])
            -- os.startTimer(0.5)
            -- os.pullEvent("timer")
            value.instructions[i]()
        end
    end
end

function CalculateCosts(pos1, pos2, subdivisions)
    local travelDest = pos1
    -- if (pos1.sub(SpawnLoc).length() > pos2.sub(SpawnLoc).length()) then
    --     travelDest = pos2
    -- end

    local travelCost = (Config["travelHeight"] - SpawnLoc.y) * 4      -- to and from travel height (both there and back)
    travelCost = travelCost + (travelDest:sub(SpawnLoc).length() * 2) -- to and from destination
    travelCost = travelCost * subdivisions                            -- times the number of bots

    local miningCosts = 0
end

function DeployMiners(pos1, pos2, subdivisions)
    local cost = CalculateCosts(pos1, pos2)
end

-- Initialize()
local testSubs = GetMiningSubdivisions(vector.new(0, 0, 0), vector.new(10, 10, 10), 2, 2)
CalculateMiningPaths(vector.new(0, 0, 0), testSubs)
