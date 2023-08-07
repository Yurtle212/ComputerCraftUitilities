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

local directions = {
    ["-z"] = headings["north"],
    ["+z"] = headings["south"],
    ["-x"] = headings["west"],
    ["+x"] = headings["east"],
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
    local retVal = {}

    if way == "forward" then
        retVal[#retVal+1] = turtle.dig
        retVal[#retVal+1] = turtle.forward
        if dir == 1 then
            pos.z = pos.z - 1
        elseif dir == 2 then
            pos.x = pos.x - 1
        elseif dir == 3 then
            pos.z = pos.z + 1
        elseif dir == 4 then
            pos.x = pos.x + 1
        end
    elseif way == "up" then
        retVal[#retVal+1] = turtle.digUp
        retVal = turtle.up
        pos.y = pos.y + 1
    else
        retVal[#retVal+1] = turtle.digDown
        retVal = turtle.down
        pos.y = pos.y - 1
    end

    return pos, retVal
end

function TableConcat(t1,t2)
    for i=1,#t2 do
        t1[#t1+1] = t2[i]
    end
    return t1
end

function RotateTo(dir, dest)
    local instructions = {}

    if type(dest) == "string" then
        dest = headings[dest]
    end

    while dir ~= dest do
        dir, instructions[#instructions + 1] = turnDirection(dir, "left")
    end

    return dir, instructions
end

function MoveTo(pos, dir, dest)
    local instructions = {}
    local tmp

    while not pos:equals(dest) do
        if (pos.y ~= dest.y) then
            if pos.y > dest.y then
                pos, tmp = move(pos, "up", dir)
                instructions = TableConcat(instructions, tmp)
            else
                pos, tmp = move(pos, "down", dir)
                instructions = TableConcat(instructions, tmp)
            end
        elseif (pos.z ~= dest.z) then
            if (pos.z > pos.z) then
                dir, tmp = RotateTo(dir, directions["-z"])
                instructions = TableConcat(instructions, tmp)
                pos, tmp = move(pos, "forward", dir)
                instructions = TableConcat(instructions, tmp)
            else
                dir, tmp = RotateTo(dir, directions["+z"])
                instructions = TableConcat(instructions, tmp)
                pos, tmp = move(pos, "forward", dir)
                instructions = TableConcat(instructions, tmp)
            end
        elseif (pos.x ~= dest.x) then
            if (pos.x > pos.x) then
                dir, tmp = RotateTo(dir, directions["-x"])
                instructions = TableConcat(instructions, tmp)
                pos, tmp = move(pos, "forward", dir)
                instructions = TableConcat(instructions, tmp)
            else
                dir, tmp = RotateTo(dir, directions["+x"])
                instructions = TableConcat(instructions, tmp)
                pos, tmp = move(pos, "forward", dir)
                instructions = TableConcat(instructions, tmp)
            end
        end
    end

    return pos, dir, instructions
end

function CalculateMiningPaths(startPos, subdivisions)
    for key, value in pairs(subdivisions) do
        value.instructions = {}

        local tmpInstructions

        local dir = 1
        local pos = vector.new(0,0,0)

        local distFromStart = value.startPos:sub(startPos)

        local baseStartDir = dir
        local baseStartPos = pos

        -- go to assigned area

        pos, dir, tmpInstructions = MoveTo(pos, dir, value.startPos)
        value.instructions = TableConcat(value.instructions, tmpInstructions)

        dir, tmpInstructions = RotateTo(dir, headings["north"])
        value.instructions = TableConcat(value.instructions, tmpInstructions)

        local turnLeft = true

        -- local blockAmount = (value.endPos.x - value.startPos.x) * (value.endPos.y - value.startPos.y) * (value.endPos.z - value.startPos.z)
        local xDist = (value.endPos.x - value.startPos.x)
        local yDist = (value.endPos.y - value.startPos.y)
        local zDist = (value.endPos.z - value.startPos.z)
        local amount = xDist * yDist * zDist

        local startDir = dir

        -- return to start location

        pos, dir, tmpInstructions = MoveTo(pos, dir, startPos)
        value.instructions = TableConcat(value.instructions, tmpInstructions)

        dir, tmpInstructions = RotateTo(dir, headings["north"])
        value.instructions = TableConcat(value.instructions, tmpInstructions)

        for i = 1, #value.instructions, 1 do
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
