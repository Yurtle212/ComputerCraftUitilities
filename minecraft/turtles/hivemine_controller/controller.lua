local yurtle = require "yurtle"
local rsBridgeUtility = require "rsBridgeUtility"
local movement = require "movement"

os.loadAPI("json")

local params = { ... }

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

    if next(params) == nil then
        WS = assert(http.websocket("wss://yurtle.net/cc/default"))
    else
        WS = assert(http.websocket("wss://yurtle.net/cc/" .. params[1]))
    end

    UUID = "ccHiveminerController"

    while true do
        local raw = WS.receive()
        if (raw == nil) then
            print("re-init")
            os.startTimer(2)
            os.pullEvent("timer")

            if next(params) == nil then
                WS = assert(http.websocket("wss://yurtle.net/cc/default"))
            else
                WS = assert(http.websocket("wss://yurtle.net/cc/" .. params[1]))
            end
        end

        if (raw ~= nil) then
            local signal = json.decode(raw)
            if (signal.type == "hiveminer") then
                print("Attempting to hivemine")
                if (signal.data.pos1 ~= nil and signal.data.pos2 ~= nil) then
                    local pos1 = vector.new(signal.data.pos1.x, signal.data.pos1.y, signal.data.pos1.z)
                    local pos2 = vector.new(signal.data.pos2.x, signal.data.pos2.y, signal.data.pos2.z)

                    local ack = {
                        type = "ack",
                        data = {
                            UUID = UUID,
                            message = "Deploying bots..."
                        },
                        timestamp = os.time()
                    }

                    WS.send(json.encode(ack))

                    WS.close()
                    DeployMiners(pos1, pos2, signal.data.subdivisions.x, signal.data.subdivisions.z)

                    if next(params) == nil then
                        WS = assert(http.websocket("wss://yurtle.net/cc/default"))
                    else
                        WS = assert(http.websocket("wss://yurtle.net/cc/" .. params[1]))
                    end

                    local ack = {
                        type = "ack",
                        data = {
                            UUID = UUID,
                            message = "Bots Retrieved"
                        },
                        timestamp = os.time()
                    }
                    WS.send(json.encode(ack))
                else
                    local ack = {
                        type = "ack",
                        data = {
                            UUID = UUID,
                            success = false
                        },
                        timestamp = os.time()
                    }
                    WS.send(json.encode(ack))
                end
            elseif signal.type == "init" then
                UUID = signal.data.UUID
            end
        end
    end
end

local function reverse(tab)
    local rev = {}
    for i = #tab, 1, -1 do
        rev[#rev + 1] = tab[i]
    end
    return rev
end

local fuelConsumingFunctions = {
    turtle.forward,
    turtle.up,
    turtle.down,
    turtle.back
}

local function signum(number) -- counts 0 as positive
    if number < 0 then
        return -1
    else
        return 1
    end
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

            subdivisions[index].endPos.x = subdivisions[index].endPos.x - signum(subdivisions[index].endPos.x)

            subdivisions[index].endPos.z = subdivisions[index].endPos.z - signum(subdivisions[index].endPos.z)

            subdivisions[index].startPos = subdivisions[index].startPos:add(pos1)
            subdivisions[index].endPos = subdivisions[index].endPos:add(pos1)

            if subdivisions[index].startPos.x > math.max(pos1.x, pos2.x) then
                subdivisions[index].startPos.x = math.max(pos1.x, pos2.x)
            end

            if subdivisions[index].startPos.x < math.min(pos1.x, pos2.x) then
                subdivisions[index].startPos.x = math.min(pos1.x, pos2.x)
            end

            if subdivisions[index].startPos.z > math.max(pos1.z, pos2.z) then
                subdivisions[index].startPos.z = math.max(pos1.z, pos2.z)
            end

            if subdivisions[index].startPos.z < math.min(pos1.z, pos2.z) then
                subdivisions[index].startPos.z = math.min(pos1.z, pos2.z)
            end

            if subdivisions[index].endPos.x > math.max(pos1.x, pos2.x) then
                subdivisions[index].endPos.x = math.max(pos1.x, pos2.x)
            end

            if subdivisions[index].endPos.x < math.min(pos1.x, pos2.x) then
                subdivisions[index].endPos.x = math.min(pos1.x, pos2.x)
            end

            if subdivisions[index].endPos.z > math.max(pos1.z, pos2.z) then
                subdivisions[index].endPos.z = math.max(pos1.z, pos2.z)
            end

            if subdivisions[index].endPos.z < math.min(pos1.z, pos2.z) then
                subdivisions[index].endPos.z = math.min(pos1.z, pos2.z)
            end

            print(json.encode(subdivisions[index]))
        end
    end
    return subdivisions
end

function CalculateTravelPath(spawnPos, destPos, dir, travelHeight, dig)
    local cost = 0
    local instructions = {}
    local tmpInstructions = {}
    local pos = vector.new(spawnPos.x, spawnPos.y, spawnPos.z)

    if pos.y < travelHeight then
        pos, dir, tmpInstructions = movement.MoveTo(pos, dir, vector.new(pos.x, travelHeight, pos.z), dig)
        instructions = movement.TableConcat(instructions, tmpInstructions)
    end

    pos, dir, tmpInstructions = movement.MoveTo(pos, dir, vector.new(destPos.x, travelHeight, destPos.z), dig)
    instructions = movement.TableConcat(instructions, tmpInstructions)

    pos, dir, tmpInstructions = movement.MoveTo(pos, dir, vector.new(destPos.x, destPos.y, destPos.z), dig)
    instructions = movement.TableConcat(instructions, tmpInstructions)

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

        value.instructions[#value.instructions + 1] = "digsite"

        local tmpInstructions

        local dir = sDir
        local pos = vector.new(startPos.x, startPos.y, startPos.z)

        -- go to assigned area

        pos, dir, tmpInstructions = movement.MoveTo(pos, dir, value.startPos)
        value.instructions = movement.TableConcat(value.instructions, tmpInstructions)

        if (value.startPos.x > value.endPos.x) then
            dir, tmpInstructions = movement.RotateTo(dir, movement.directions["-x"])
            value.instructions = movement.TableConcat(value.instructions, tmpInstructions)
        else
            dir, tmpInstructions = movement.RotateTo(dir, movement.directions["-x"])
            value.instructions = movement.TableConcat(value.instructions, tmpInstructions)
        end

        -- mine

        value.instructions[#value.instructions + 1] = "digplot"

        local xDist = math.abs(value.endPos.x - value.startPos.x)
        local yDist = math.abs(value.endPos.y - value.startPos.y)
        local zDist = math.abs(value.endPos.z - value.startPos.z)
        local amount = xDist * yDist * zDist

        local lastZWall = value.startPos.z

        for y = 1, yDist + 1, 1 do
            for z = 1, zDist, 1 do
                for x = 1, xDist, 1 do
                    pos, tmpInstructions = movement.move(pos, "forward", dir)
                    value.instructions = movement.TableConcat(value.instructions, tmpInstructions)
                end

                local tmpDir = dir

                if lastZWall == value.startPos.z then
                    if value.startPos.z > value.endPos.z then
                        dir, tmpInstructions = movement.RotateTo(dir, movement.directions["-z"])
                        value.instructions = movement.TableConcat(value.instructions, tmpInstructions)
                    else
                        dir, tmpInstructions = movement.RotateTo(dir, movement.directions["+z"])
                        value.instructions = movement.TableConcat(value.instructions, tmpInstructions)
                    end
                else
                    if value.startPos.z > value.endPos.z then
                        dir, tmpInstructions = movement.RotateTo(dir, movement.directions["+z"])
                        value.instructions = movement.TableConcat(value.instructions, tmpInstructions)
                    else
                        dir, tmpInstructions = movement.RotateTo(dir, movement.directions["-z"])
                        value.instructions = movement.TableConcat(value.instructions, tmpInstructions)
                    end
                end

                pos, tmpInstructions = movement.move(pos, "forward", dir)
                value.instructions = movement.TableConcat(value.instructions, tmpInstructions)

                if tmpDir == movement.directions["+x"] then
                    dir, tmpInstructions = movement.RotateTo(dir, movement.directions["-x"])
                    value.instructions = movement.TableConcat(value.instructions, tmpInstructions)
                else
                    dir, tmpInstructions = movement.RotateTo(dir, movement.directions["+x"])
                    value.instructions = movement.TableConcat(value.instructions, tmpInstructions)
                end
            end

            if lastZWall == value.startPos.z then
                lastZWall = value.endPos.z
            else
                lastZWall = value.startPos.z
            end

            for x = 1, xDist, 1 do
                pos, tmpInstructions = movement.move(pos, "forward", dir)
                value.instructions = movement.TableConcat(value.instructions, tmpInstructions)
            end

            if (y <= yDist) then
                pos, tmpInstructions = movement.move(pos, "down", dir)
                value.instructions = movement.TableConcat(value.instructions, tmpInstructions)

                dir, value.instructions[#value.instructions + 1] = movement.turnDirection(dir, "left")
                dir, value.instructions[#value.instructions + 1] = movement.turnDirection(dir, "left")
            end
        end

        -- return to start location

        pos, dir, tmpInstructions = movement.MoveTo(pos, dir, startPos)
        value.instructions = movement.TableConcat(value.instructions, tmpInstructions)

        dir, tmpInstructions = movement.RotateTo(dir, sDir)
        value.instructions = movement.TableConcat(value.instructions, tmpInstructions)

        value.instructions[#value.instructions + 1] = "returning"

        value.cost = 0

        for i = 1, #value.instructions, 1 do
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
            if (type(instructions[i]) == "function") then
                instructions[i]()
            else
                print(instructions[i])
            end
        end
        return
    end

    for key, value in pairs(instructions) do
        for i = 1, #value.instructions, 1 do
            if (type(value.instructions[i]) == "function") then
                value.instructions[i]()
            else
                print(value.instructions[i])
            end
        end
    end
end

function CalculateCosts(travelCost, bots)
    travelCost = travelCost * #bots -- times the number of bots

    local miningCosts = 0
    for key, value in pairs(bots) do
        miningCosts = miningCosts + value.cost
    end

    return travelCost + miningCosts + (#bots * 15) -- a little extra buffer
end

function DeployMiner(instructions, rsBridge, modem, cost, pos, dir)
    local success = rsBridgeUtility.RetrieveItemFromStorage(rsBridge, {
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

    local event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")

    local neededFuel = cost - message

    success = rsBridgeUtility.RetrieveItemFromStorage(rsBridge, {
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

    modem.transmit(1, 1, "refuel")

    os.pullEvent("modem_message")

    local equipMessage = {
        equipLeft = nil,
        equipRight = nil,
    }

    if (Config["miner_left"] ~= nil) then
        rsBridgeUtility.RetrieveItemFromStorage(rsBridge, {
            item = Config["miner_left"],
            amount = 1
        }, "west")

        slot = yurtle.findItemInInventory(Config["miner_left"])
        if (slot == nil) then
            print("No " .. Config["miner_left"])
        else
            turtle.select(slot)
            turtle.drop()
            equipMessage.equipLeft = Config["miner_left"]
        end
    end

    if (Config["miner_right"] ~= nil) then
        rsBridgeUtility.RetrieveItemFromStorage(rsBridge, {
            item = Config["miner_right"],
            amount = 1
        }, "west")

        slot = yurtle.findItemInInventory(Config["miner_right"])
        if (slot == nil) then
            print("No " .. Config["miner_right"])
        else
            turtle.select(slot)
            turtle.drop()
            equipMessage.equipRight = Config["miner_right"]
        end
    end

    local instructionCount = #instructions
    local maxInstructionsPerMessage = 50
    local instructionIndex = 0

    local functiontable = {
        ["forward"] = turtle.forward,
        ["back"] = turtle.back,
        ["up"] = turtle.up,
        ["down"] = turtle.down,
        ["turnLeft"] = turtle.turnLeft,
        ["turnRight"] = turtle.turnRight,
        ["dig"] = turtle.dig,
        ["digUp"] = turtle.digUp,
        ["digDown"] = turtle.digDown,
    }

    modem.transmit(1, 1, equipMessage)
    while instructionIndex < instructionCount do
        os.pullEvent("modem_message")
        local subInstructions = {}

        for i = instructionIndex, instructionIndex + maxInstructionsPerMessage, 1 do
            -- subInstructions[#subInstructions+1] = instructions[instructionIndex]
            if (type(instructions[instructionIndex]) == "function") then
                for key, value in pairs(functiontable) do
                    if value == instructions[instructionIndex] then
                        subInstructions[#subInstructions + 1] = key
                        break
                    end
                end
            else
                subInstructions[#subInstructions + 1] = instructions[instructionIndex]
            end


            instructionIndex = instructionIndex + 1

            if (instructionIndex > instructionCount) then
                break
            end
        end

        local instructionMessage

        if instructionIndex >= instructionCount then
            instructionMessage = {
                moveInstructions = subInstructions,
                position = pos,
                direction = dir,
                more = false
            }
        else
            instructionMessage = {
                moveInstructions = subInstructions,
                more = true
            }
        end

        modem.transmit(1, 1, instructionMessage)
    end

    -- print("sent " .. instructionIndex .. " instructions")

    os.pullEvent("peripheral_detach")
    -- print("deployed successfully")
end

function PrepareDeploy(rsBridge)
    local slot = yurtle.findItemInInventory("empty")
    if (slot == nil) then
        print("No empty space in inventory")
        return false
    end
    turtle.select(slot)
    local unequipped = turtle.equipRight()
    if unequipped then
        rsBridgeUtility.PutItemInStorage(rsBridge, slot, "west", 64)
    end

    rsBridgeUtility.RetrieveItemFromStorage(rsBridge, {
        item = "computercraft:wireless_modem_advanced",
        amount = 1
    }, "west")

    slot = yurtle.findItemInInventory("computercraft:wireless_modem_advanced")
    if (slot == nil) then
        print("No GPS")
    else
        turtle.select(slot)
        turtle.equipRight()
        Position = vector.new(gps.locate())

        turtle.equipRight()
        rsBridgeUtility.PutItemInStorage(rsBridge, slot, "west", 64)
    end

    -- get pickaxe

    rsBridgeUtility.RetrieveItemFromStorage(rsBridge, {
        item = "minecraft:diamond_pickaxe",
        amount = 1
    }, "west")

    slot = yurtle.findItemInInventory("minecraft:diamond_pickaxe")
    if (slot == nil) then
        print("No Pickaxe")
        return false
    end
    turtle.select(slot)
    turtle.equipRight()
    return true
end

function DeployMiners(pos1, pos2, subdivisionsX, subdivisionsZ)
    shell.run("delete disk/startup")
    shell.run(
        "wget https://raw.githubusercontent.com/Yurtle212/ComputerCraftUitilities/main/minecraft/turtles/hiveminer/startup disk/startup")

    print("\n")

    local tmp
    local rsBridge = peripheral.find("rsBridge")

    local modem = peripheral.wrap("bottom")
    modem.open(1)

    -- get GPS location and then get pickaxe
    if not PrepareDeploy(rsBridge) then
        return
    end

    -- plot paths

    local dir = movement.headings[Config["heading"]]
    local pos = vector.new(Position.x, Position.y, Position.z)

    print("Position: " .. pos.x .. ", " .. pos.y .. ", " .. pos.z)
    print("Direction: " .. Config["heading"])

    if not Config["debug_executePath"] then
        pos, tmp = movement.move(pos, "forward", dir)
    end

    local startDir = dir
    local startPos = vector.new(pos.x, pos.y, pos.z)

    local travelInstructions
    local travelInstructionsBack

    local travelCost = 0

    local subdivisions = GetMiningSubdivisions(pos1, pos2, subdivisionsX, subdivisionsZ)
    print(#subdivisions .. " bots")

    dir, tmp, travelInstructions = CalculateTravelPath(pos, pos1, dir, Config["travelHeight"])
    travelCost = travelCost + tmp

    local instructions = CalculateMiningPaths(pos1, subdivisions, dir)
    instructions = reverse(instructions)

    dir, tmp, travelInstructionsBack = CalculateTravelPath(pos1, vector.new(Position.x, Position.y, Position.z), dir,
        Config["travelHeight"], true)
    travelCost = travelCost + tmp

    local cost = CalculateCosts(travelCost, instructions)
    print("Cost: " .. cost)

    if Config["debug_executePath"] then
        Debug_PerformPath(travelInstructions, true)
        Debug_PerformPath(instructions, false)
        Debug_PerformPath(travelInstructionsBack, true)
        return
    end

    -- check if enough items for everyone
    local picks = rsBridge.getItem({ "minecraft:diamond_pickaxe" })
    if picks.amount < #instructions then
        print("not enough pickaxes")
        return
    end

    local storedFuel = rsBridgeUtility.getFuelInStorage(rsBridge)
    print("Stored fuel: " .. storedFuel)
    if (storedFuel < cost) then
        print("not enough fuel")
        return
    end

    for key, value in pairs(instructions) do
        local builtInstruction = movement.TableConcat(travelInstructions, value.instructions)
        builtInstruction = movement.TableConcat(builtInstruction, travelInstructionsBack)

        DeployMiner(builtInstruction, rsBridge, modem, value.cost + travelCost + 15, startPos, startDir)
    end

    for key, value in pairs(instructions) do
        while true do
            local event, side = os.pullEvent("peripheral")
            if side == "top" then
                local has_block, inspection = turtle.inspectUp()
                if string.match(inspection.name, "turtle") then
                    break
                end
            end
        end

        local empty = yurtle.findItemInInventory("empty")
        if (empty == nil) then
            print("no empty slot to suck into")
            return
        end
        while turtle.suckUp() do
            rsBridgeUtility.PutItemInStorage(rsBridge, empty, "west")
        end

        redstone.setOutput("top", true)
        os.pullEvent("redstone")
        redstone.setOutput("top", false)

        while turtle.suckUp() do
            rsBridgeUtility.PutItemInStorage(rsBridge, empty, "west")
        end

        turtle.digUp()
        rsBridgeUtility.PutItemInStorage(rsBridge, empty, "west")
    end
end

Initialize()
