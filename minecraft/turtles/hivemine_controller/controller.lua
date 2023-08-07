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
    -- local powerTable = { 1, 16, 64 }
    -- local closest = powerTable[1]

    -- for i, currentNum in pairs(powerTable) do
    --     if (currentNum > subdivisions) then
    --         break
    --     end

    --     local diff = math.abs(currentNum - subdivisions)

    --     if diff < closest then
    --         closest = currentNum
    --     end
    -- end

    -- local wholeSize = pos1.sub(pos2)
    -- wholeSize = vector.new(math.abs(wholeSize.x), math.abs(wholeSize.y), math.abs(wholeSize.z))
    -- local subdivisionSize = vector.new(math.floor((wholeSize.x / closest) + 0.5), wholeSize.y, math.floor((wholeSize.z / closest) + 0.5))
    -- print("Subdivision Edges: " .. subdivisionSize)

    local wholeSize = pos1:sub(pos2)
    wholeSize = vector.new(math.abs(wholeSize.x), math.abs(wholeSize.y), math.abs(wholeSize.z))
    local subdivisionSize = vector.new(math.floor((wholeSize.x / subdivisionsX) + 0.5), wholeSize.y, math.floor((wholeSize.z / subdivisionsZ) + 0.5))
    -- print("Subdivision Edges: (x:" .. subdivisionSize.x .. ", y:" .. subdivisionSize.y  .. ", z:" .. subdivisionSize.z .. ")")
    local subdivisions = {}
    for x = 1, subdivisionsX, 1 do
        for z = 1, subdivisionsZ, 1 do
            local index = (x * (subdivisionsZ-1)) + z
            subdivisions[index] = {
                startPos = vector.new(subdivisionSize.x * (x-1), 0, subdivisionSize.z * (z-1)),
                endPos = vector.new((subdivisionSize.x * (x-1)) + subdivisionSize.x, subdivisionSize.y, (subdivisionSize.z * (z-1)) + subdivisionSize.z)
            }

            if (x <= subdivisionsX) then
                subdivisions[index].endPos.x = subdivisions[index].endPos.x - 1
            end

            if (z <= subdivisionsZ) then
                subdivisions[index].endPos.z = subdivisions[index].endPos.z - 1
            end

            print(json.encode(subdivisions[index]))
        end
    end
end

function CalculateMiningCost(spawn, startPos, endPos)

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

function DeloyMiners(pos1, pos2, subdivisions)
    local cost = CalculateCosts(pos1, pos2)
end

-- Initialize()
GetMiningSubdivisions(vector.new(0,0,0), vector.new(10,10,10), 2, 2)