local yurtle = require("yurtle")

local params = {...}

local data = {
    position = vector.new(0,0,0)
}

-- Main Functions

function Main()
    print("Main")
end

function PlanRoute()
    return 100
end

function Setup()
    print("Setup")
    
    data.position.x, data.position.y, data.position.z = gps.locate()
    

    Main()
end

Setup()