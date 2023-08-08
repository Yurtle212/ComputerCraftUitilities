local yurtle = require "yurtle"
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
            local index = ((x - 1) * subdivisionsZ) + z

            subdivisions[index] = {
                startPos = vector.new(subdivisionSize.x * (x - 1), 0, subdivisionSize.z * (z - 1)),
                endPos = vector.new((subdivisionSize.x * (x - 1)) + subdivisionSize.x, -subdivisionSize.y,
                    (subdivisionSize.z * (z - 1)) + subdivisionSize.z)
            }

            if pos1.x > pos2.x then
                subdivisions[index].startPos.x = -subdivisions[index].startPos.x
                subdivisions[index].endPos.x = -subdivisions[index].endPos.x
            end

            if pos1.z > pos2.z then
                subdivisions[index].startPos.z = -subdivisions[index].startPos.z
                subdivisions[index].endPos.z = -subdivisions[index].endPos.z
            end

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

            subdivisions[index].startPos = subdivisions[index].startPos:add(pos1)
            subdivisions[index].endPos = subdivisions[index].endPos:add(pos1)

            print(json.encode(subdivisions[index]))
        end
    end
    return subdivisions
end

local headings = {
    north = 1,
    east = 2,
    south = 3,
    west = 4,
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

local function move(pos, way, dir, dig)
    if (dig == nil) then
        dig = true
    end

    local retVal = {}

    if way == "forward" then
        if (dig) then
            retVal[#retVal + 1] = turtle.dig
        end

        retVal[#retVal + 1] = turtle.forward
        if dir == directions["-z"] then
            pos.z = pos.z - 1
        elseif dir == directions["-x"] then
            pos.x = pos.x - 1
        elseif dir == directions["+z"] then
            pos.z = pos.z + 1
        elseif dir == directions["+x"] then
            pos.x = pos.x + 1
        end
    elseif way == "up" then
        if (dig) then
            retVal[#retVal + 1] = turtle.digUp
        end

        retVal[#retVal + 1] = turtle.up
        pos.y = pos.y + 1
    else
        if (dig) then
            retVal[#retVal + 1] = turtle.digDown
        end

        retVal[#retVal + 1] = turtle.down
        pos.y = pos.y - 1
    end

    return pos, retVal
end

function TableConcat(t1, t2)
    for i = 1, #t2 do
        t1[#t1 + 1] = t2[i]
    end
    return t1
end

function RotateTo(dir, dest)
    local instructions = {}

    if type(dest) == "string" then
        dest = headings[dest]
    end

    while dir ~= dest do
        if (dir > dest) then
            if math.abs(dir - dest) > 2 then
                dir, instructions[#instructions + 1] = turnDirection(dir, "right")
            else
                dir, instructions[#instructions + 1] = turnDirection(dir, "left")
            end
        else
            if math.abs(dir - dest) > 2 then
                dir, instructions[#instructions + 1] = turnDirection(dir, "left")
            else
                dir, instructions[#instructions + 1] = turnDirection(dir, "right")
            end
        end
    end

    return dir, instructions
end

function MoveTo(pos, dir, dest, dig)
    if (dig == nil) then
        dig = true
    end

    local instructions = {}
    local tmp

    while not (pos:equals(dest)) do
        if (pos.y ~= dest.y) then
            if pos.y > dest.y then
                pos, tmp = move(pos, "down", dir, dig)
                instructions = TableConcat(instructions, tmp)
            else
                pos, tmp = move(pos, "up", dir, dig)
                instructions = TableConcat(instructions, tmp)
            end
        elseif (pos.z ~= dest.z) then
            if (pos.z > dest.z) then
                dir, tmp = RotateTo(dir, directions["-z"])
                instructions = TableConcat(instructions, tmp)
                pos, tmp = move(pos, "forward", dir, dig)
                instructions = TableConcat(instructions, tmp)
            else
                dir, tmp = RotateTo(dir, directions["+z"])
                instructions = TableConcat(instructions, tmp)
                pos, tmp = move(pos, "forward", dir, dig)
                instructions = TableConcat(instructions, tmp)
            end
        elseif (pos.x ~= dest.x) then
            if (pos.x > dest.x) then
                dir, tmp = RotateTo(dir, directions["-x"])
                instructions = TableConcat(instructions, tmp)
                pos, tmp = move(pos, "forward", dir, dig)
                instructions = TableConcat(instructions, tmp)
            else
                dir, tmp = RotateTo(dir, directions["+x"])
                instructions = TableConcat(instructions, tmp)
                pos, tmp = move(pos, "forward", dir, dig)
                instructions = TableConcat(instructions, tmp)
            end
        end
    end

    return pos, dir, instructions
end

local fuelConsumingFunctions = {
    turtle.forward,
    turtle.up,
    turtle.down,
    turtle.back
}

local function reverse(tab)
    local rev = {}
    for i = #tab, 1, -1 do
        rev[#rev + 1] = tab[i]
    end
    return rev
end

function CalculateTravelPath(spawnPos, destPos, dir, travelHeight, dig)
    local cost = 0
    local instructions = {}
    local tmpInstructions = {}
    local pos = vector.new(spawnPos.x, spawnPos.y, spawnPos.z)

    if pos.y < travelHeight then
        pos, dir, tmpInstructions = MoveTo(pos, dir, vector.new(pos.x, travelHeight, pos.z), dig)
        instructions = TableConcat(instructions, tmpInstructions)
    end

    pos, dir, tmpInstructions = MoveTo(pos, dir, vector.new(destPos.x, travelHeight, destPos.z), dig)
    instructions = TableConcat(instructions, tmpInstructions)

    pos, dir, tmpInstructions = MoveTo(pos, dir, vector.new(destPos.x, destPos.y, destPos.z), dig)
    instructions = TableConcat(instructions, tmpInstructions)

    for i = 1, #instructions, 1 do
        for j = 1, #fuelConsumingFunctions, 1 do
            if instructions[i] == fuelConsumingFunctions[j] then
                cost = cost + 1
            end
        end
    end

    return dir, cost, instructions
end

function CalculateMiningPaths(startPos, subdivisions, sDir)
    for key, value in pairs(subdivisions) do
        value.instructions = {}

        local tmpInstructions

        local dir = sDir
        local pos = vector.new(startPos.x, startPos.y, startPos.z)

        local distFromStart = value.startPos:sub(startPos)

        local baseStartDir = dir
        local baseStartPos = pos

        -- go to assigned area

        pos, dir, tmpInstructions = MoveTo(pos, dir, value.startPos)
        value.instructions = TableConcat(value.instructions, tmpInstructions)

        -- mine

        dir, tmpInstructions = RotateTo(dir, directions["+x"])
        value.instructions = TableConcat(value.instructions, tmpInstructions)

        local positiveX = true
        local positiveZ = true

        local xDist = (value.endPos.x - value.startPos.x)
        local yDist = (value.endPos.y - value.startPos.y)
        local zDist = (value.endPos.z - value.startPos.z)
        local amount = xDist * yDist * zDist

        local startDir = dir

        for y = 1, yDist, 1 do
            for z = 1, zDist, 1 do
                for x = 1, xDist, 1 do
                    pos, tmpInstructions = move(pos, "forward", dir)
                    value.instructions = TableConcat(value.instructions, tmpInstructions)
                end

                if (positiveZ) then
                    dir, tmpInstructions = RotateTo(dir, directions["+z"])
                    value.instructions = TableConcat(value.instructions, tmpInstructions)
                else
                    dir, tmpInstructions = RotateTo(dir, directions["-z"])
                    value.instructions = TableConcat(value.instructions, tmpInstructions)
                end

                pos, tmpInstructions = move(pos, "forward", dir)
                value.instructions = TableConcat(value.instructions, tmpInstructions)

                if (positiveX) then
                    dir, tmpInstructions = RotateTo(dir, directions["-x"])
                    value.instructions = TableConcat(value.instructions, tmpInstructions)
                else
                    dir, tmpInstructions = RotateTo(dir, directions["+x"])
                    value.instructions = TableConcat(value.instructions, tmpInstructions)
                end

                positiveX = not positiveX
            end

            for x = 1, xDist, 1 do
                pos, tmpInstructions = move(pos, "forward", dir)
                value.instructions = TableConcat(value.instructions, tmpInstructions)
            end

            if (y < yDist) then
                pos, tmpInstructions = move(pos, "down", dir)
                value.instructions = TableConcat(value.instructions, tmpInstructions)

                dir, value.instructions[#value.instructions + 1] = turnDirection(dir, "left")
                dir, value.instructions[#value.instructions + 1] = turnDirection(dir, "left")
            end

            positiveZ = not positiveZ
            positiveX = not positiveX
        end

        -- return to start location

        pos, dir, tmpInstructions = MoveTo(pos, dir, startPos)
        value.instructions = TableConcat(value.instructions, tmpInstructions)

        dir, tmpInstructions = RotateTo(dir, sDir)
        value.instructions = TableConcat(value.instructions, tmpInstructions)

        value.cost = 0

        for i = 1, #value.instructions, 1 do
            -- print(value.instructions[i])
            -- os.startTimer(0.5)
            -- os.pullEvent("timer")
            -- value.instructions[i]()
            for j = 1, #fuelConsumingFunctions, 1 do
                if value.instructions[i] == fuelConsumingFunctions[j] then
                    value.cost = value.cost + 1
                end
            end
        end
    end
    return subdivisions
end

function Debug_PerformPath(instructions, single)
    if (single) then
        for i = 1, #instructions, 1 do
            instructions[i]()
        end
        return
    end

    for key, value in pairs(instructions) do
        for i = 1, #value.instructions, 1 do
            value.instructions[i]()
        end
    end
end

function CalculateCosts(travelCost, bots)
    -- local travelDest = pos1

    -- local travelCost = (Config["travelHeight"] - SpawnLoc.y) * 4      -- to and from travel height (both there and back)
    -- travelCost = travelCost + (travelDest:sub(SpawnLoc):length() * 2) -- to and from destination
    travelCost = travelCost * #bots                                   -- times the number of bots

    local miningCosts = 0
    for key, value in pairs(bots) do
        miningCosts = miningCosts + value.cost
    end

    return travelCost + miningCosts
end

function RetrieveItemFromStorage(rsBridge, order, depositDirection)
    local items = rsBridge.listItems()
    if (order.item == "fuel") then
        local fuelGotten = 0
        local itemsForExport = {

        }
        
        for key, value in pairs(yurtle.fuelItems) do
            local item = rsBridge.getItem({name=key})
            if (item.amount > 0) then
                local fuelAmount = 0
                for i = 1, item.amount, 1 do
                    if (fuelGotten + value <= order.amount) then
                        fuelAmount = fuelAmount + 1
                        fuelGotten = fuelGotten + value
                    else
                        break
                    end
                end

                itemsForExport[#itemsForExport+1] = {
                    name = key,
                    count = fuelAmount
                }
            end
        end

        for i = #itemsForExport, 1, -1 do
            if rsBridge.getItem({name = itemsForExport[i].name}).amount > itemsForExport[i].count then
                itemsForExport[i].count = itemsForExport[i].count + 1
                fuelGotten = fuelGotten + yurtle.fuelItems[itemsForExport[i].name]

                if fuelGotten >= order.amount then
                    break
                end
            end
        end

        for i = 1, #itemsForExport, 1 do
            rsBridge.exportItem(itemsForExport[i], depositDirection)
        end
        return true
    else
        rsBridge.exportItem({
            name = order.item,
            count = order.amount
        }, depositDirection)
        return true
    end
end

function DeployMiner(instructions, rsBridge, modem, cost)
    local success = RetrieveItemFromStorage(rsBridge, {
        item = "computercraft:turtle_normal",
        amount = 1
    }, "west")

    local slot = yurtle.findItemInInventory("computercraft:turtle_normal")
    if (slot == nil) then
        return
    end

    turtle.select(slot)
    turtle.place()
    os.pullEvent("peripheral")
    peripheral.wrap("front").turnOn()

    local event, sender, message, protocol = os.pullEvent("modem_message")

    local neededFuel = cost - message

    success = RetrieveItemFromStorage(rsBridge, {
        item = "fuel",
        amount = neededFuel
    }, "west")

    if not success then
        return
    end

    for i = 1, 16, 1 do
        slot = yurtle.findItemInInventory("fuel")
        if (slot == nil) then
            break
        end
        turtle.select(slot)
        turtle.drop()
    end
    
end

function DeployMiners(pos1, pos2, subdivisionsX, subdivisionsZ)
    shell.run("delete disk/startup")
    shell.run("wget https://raw.githubusercontent.com/Yurtle212/ComputerCraftUitilities/main/minecraft/turtles/hiveminer/startup disk/startup")

    local tmp

    local dir = headings[Config["heading"]]
    local pos = vector.new(Position.x, Position.y, Position.z)

    if not Config["debug_executePath"] then
        pos, tmp = move(pos, "forward", dir)
    end

    local travelInstructions
    local travelInstructionsBack

    local travelCost = 0

    dir, tmp, travelInstructions = CalculateTravelPath(Position, pos1, dir, Config["travelHeight"])
    travelCost = travelCost + tmp
    dir, tmp, travelInstructionsBack = CalculateTravelPath(pos1, vector.new(Position.x, Position.y + 1, Position.z), dir,
        Config["travelHeight"], false)
    travelCost = travelCost + tmp

    local subdivisions = GetMiningSubdivisions(pos1, pos2, subdivisionsX, subdivisionsZ)
    local instructions = CalculateMiningPaths(pos1, subdivisions, dir)
    instructions = reverse(instructions)

    local cost = CalculateCosts(travelCost, instructions)
    print("Cost: " .. cost)

    if Config["debug_executePath"] then
        Debug_PerformPath(travelInstructions, true)
        Debug_PerformPath(instructions, false)
        Debug_PerformPath(travelInstructionsBack, true)
    end

    local rsBridge = peripheral.find("rsBridge")
    
    local modem = peripheral.wrap("bottom")
    modem.open(1)

    for key, value in pairs(instructions) do
        local builtInstruction = TableConcat(travelInstructions, value.instructions)
        builtInstruction = TableConcat(builtInstruction, travelInstructionsBack)

        DeployMiner(builtInstruction, rsBridge, modem, value.cost + travelCost)
        break
    end
end

-- Initialize()
-- local testSubs = GetMiningSubdivisions(vector.new(0, 0, 0), vector.new(3, 3, 3), 2, 2)
-- CalculateMiningPaths(vector.new(0, 0, 0), testSubs)

Initialize()
DeployMiners(vector.new(277, 63, -49), vector.new(272, 59, -54), 2, 2)
