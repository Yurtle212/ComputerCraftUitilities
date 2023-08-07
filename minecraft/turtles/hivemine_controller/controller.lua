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
    south = 2,
    east = 3,
    west = 4,
}

local function logDirection(dir, turn)
    if (turn == "left") then
        dir = dir - 1
    else
        dir = dir + 1
    end

    if (dir <= 0) then
        dir = 4
    elseif (dir >= 5) then
        dir = 1
    end

    return dir
end

function CalculateMiningPaths(startPos, subdivisions)
    for key, value in pairs(subdivisions) do
        value.instructions = {}
        local instructionsIndex = 1

        local dir = 1
        local baseStartDir = dir

        local distFromStart = value.startPos:sub(startPos)

        for x = 1, distFromStart.x, 1 do
            value.instructions[instructionsIndex] = turtle.dig
            instructionsIndex = instructionsIndex + 1
            value.instructions[instructionsIndex] = turtle.forward
            instructionsIndex = instructionsIndex + 1
        end

        value.instructions[instructionsIndex] = turtle.turnLeft
        instructionsIndex = instructionsIndex + 1
        logDirection(dir, "left")

        for z = 1, distFromStart.z, 1 do
            value.instructions[instructionsIndex] = turtle.dig
            instructionsIndex = instructionsIndex + 1
            value.instructions[instructionsIndex] = turtle.forward
            instructionsIndex = instructionsIndex + 1
        end

        local turnLeft = true

        -- local blockAmount = (value.endPos.x - value.startPos.x) * (value.endPos.y - value.startPos.y) * (value.endPos.z - value.startPos.z)
        local xDist = (value.endPos.x - value.startPos.x)
        local yDist = (value.endPos.y - value.startPos.y)
        local zDist = (value.endPos.z - value.startPos.z)
        local amount = xDist * yDist * zDist

        local startDir = dir
        for y = 1, yDist, 1 do
            for z = 1, zDist, 1 do
                for x = 1, xDist, 1 do
                    value.instructions[instructionsIndex] = turtle.dig
                    instructionsIndex = instructionsIndex + 1
                    value.instructions[instructionsIndex] = turtle.forward
                    instructionsIndex = instructionsIndex + 1
                end

                if (turnLeft) then
                    value.instructions[instructionsIndex] = turtle.turnLeft
                    instructionsIndex = instructionsIndex + 1
                    logDirection(dir, "left")
                    value.instructions[instructionsIndex] = turtle.dig
                    instructionsIndex = instructionsIndex + 1
                    value.instructions[instructionsIndex] = turtle.forward
                    instructionsIndex = instructionsIndex + 1
                    value.instructions[instructionsIndex] = turtle.turnLeft
                    instructionsIndex = instructionsIndex + 1
                    logDirection(dir, "left")
                else
                    value.instructions[instructionsIndex] = turtle.turnRight
                    instructionsIndex = instructionsIndex + 1
                    logDirection(dir, "right")
                    value.instructions[instructionsIndex] = turtle.dig
                    instructionsIndex = instructionsIndex + 1
                    value.instructions[instructionsIndex] = turtle.forward
                    instructionsIndex = instructionsIndex + 1
                    value.instructions[instructionsIndex] = turtle.turnRight
                    instructionsIndex = instructionsIndex + 1
                    logDirection(dir, "right")
                end

                turnLeft = not turnLeft
            end

            for x = 1, xDist, 1 do
                value.instructions[instructionsIndex] = turtle.dig
                instructionsIndex = instructionsIndex + 1
                value.instructions[instructionsIndex] = turtle.forward
                instructionsIndex = instructionsIndex + 1
            end

            value.instructions[instructionsIndex] = turtle.digDown
            instructionsIndex = instructionsIndex + 1
            value.instructions[instructionsIndex] = turtle.down
            instructionsIndex = instructionsIndex + 1
            value.instructions[instructionsIndex] = turtle.turnLeft
            instructionsIndex = instructionsIndex + 1
            logDirection(dir, "left")
            value.instructions[instructionsIndex] = turtle.turnLeft
            instructionsIndex = instructionsIndex + 1
            logDirection(dir, "left")
        end

        for y = 1, yDist, 1 do
            value.instructions[instructionsIndex] = turtle.digUp
            instructionsIndex = instructionsIndex + 1
            value.instructions[instructionsIndex] = turtle.up
            instructionsIndex = instructionsIndex + 1
        end

        while startDir ~= dir do
            value.instructions[instructionsIndex] = turtle.turnLeft
            instructionsIndex = instructionsIndex + 1
            logDirection(dir, "left")
        end

        value.instructions[instructionsIndex] = turtle.turnLeft
        instructionsIndex = instructionsIndex + 1
        logDirection(dir, "left")
        value.instructions[instructionsIndex] = turtle.turnLeft
        instructionsIndex = instructionsIndex + 1
        logDirection(dir, "left")

        for z = 1, zDist, 1 do
            value.instructions[instructionsIndex] = turtle.dig
            instructionsIndex = instructionsIndex + 1
            value.instructions[instructionsIndex] = turtle.forward
            instructionsIndex = instructionsIndex + 1
        end

        value.instructions[instructionsIndex] = turtle.turnRight
        instructionsIndex = instructionsIndex + 1
        logDirection(dir, "right")

        for x = 1, xDist, 1 do
            value.instructions[instructionsIndex] = turtle.dig
            instructionsIndex = instructionsIndex + 1
            value.instructions[instructionsIndex] = turtle.forward
            instructionsIndex = instructionsIndex + 1
        end

        while baseStartDir ~= dir do
            value.instructions[instructionsIndex] = turtle.turnLeft
            instructionsIndex = instructionsIndex + 1
            logDirection(dir, "left")
        end

        value.instructions[instructionsIndex] = turtle.turnLeft
        instructionsIndex = instructionsIndex + 1
        logDirection(dir, "left")
        value.instructions[instructionsIndex] = turtle.turnLeft
        instructionsIndex = instructionsIndex + 1
        logDirection(dir, "left")

        for z = 1, distFromStart.z, 1 do
            value.instructions[instructionsIndex] = turtle.dig
            instructionsIndex = instructionsIndex + 1
            value.instructions[instructionsIndex] = turtle.forward
            instructionsIndex = instructionsIndex + 1
        end

        value.instructions[instructionsIndex] = turtle.turnLeft
        instructionsIndex = instructionsIndex + 1
        logDirection(dir, "right")

        for x = 1, distFromStart.x, 1 do
            value.instructions[instructionsIndex] = turtle.dig
            instructionsIndex = instructionsIndex + 1
            value.instructions[instructionsIndex] = turtle.forward
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
