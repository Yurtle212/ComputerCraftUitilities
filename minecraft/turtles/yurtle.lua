local fuelItems = {
    ["minecraft:coal_block"] = 800,
    ["minecraft:dried_kelp_block"] = 200,
    ["minecraft:coal"] = 80,
}

local NUM_SLOTS = 16

local function refuel()

end

local function findItemInInventory(itemName)
    for i = 1, NUM_SLOTS, 1 do
        local item = turtle.getItemDetail(i)
        if (item ~= nil) then
            if (itemName == "fuel") then
                for key, value in pairs(fuelItems) do
                    if key == itemName then
                        return i
                    end
                end
            elseif (item.name) == itemName then
                return i
            end
        end
    end
    return nil
end

return { refuel = refuel, findItemInInventory = findItemInInventory, fuelItems = fuelItems, NUM_SLOTS = 16 }
