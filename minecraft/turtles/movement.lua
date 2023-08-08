local headings = {
    north = 1,
    east = 2,
    south = 3,
    west = 4,
}

local directions = {
    ["-z"] = headings["north"],
    ["+x"] = headings["east"],
    ["+z"] = headings["south"],
    ["-x"] = headings["west"],
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

local function TableConcat(t1, t2)
    local t3 = {}
    for i = 1, #t1, 1 do
        t3[#t3+1] = t1[i]
    end
    for i = 1, #t2 do
        t3[#t3+1] = t2[i]
    end
    return t3
end

local function RotateTo(dir, dest)
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

local function MoveTo(pos, dir, dest, dig)
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

return { headings = headings, directions = directions, turnDirection = turnDirection, move = move, TableConcat = TableConcat, RotateTo = RotateTo, MoveTo = MoveTo }