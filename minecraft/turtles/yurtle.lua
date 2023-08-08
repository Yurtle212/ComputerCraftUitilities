local fuelItems = {
    ["minecraft:coal_block"] = 800,
    ["minecraft:dried_kelp_block"] = 200,
    ["minecraft:coal"] = 80,
}

local NUM_SLOTS = 16

local function refuel(amount)
    if (amount == nil) then
        amount = turtle.getFuelLimit() - turtle.getFuelLevel()
    end
    local fueledAmount = 0

    while fueledAmount < amount do
        local slot = findItemInInventory("fuel")
        if (slot == nil) then
            break
        end

        turtle.select(slot)
        local detail = turtle.getItemDetail(slot)
        if (fuelItems[detail.name] * detail.count) > amount then
            while fueledAmount < amount do
                turtle.refuel(1)
                fueledAmount = fueledAmount + fuelItems[detail.name] * detail.count
            end
        else
            turtle.refuel()
            fueledAmount = fueledAmount + fuelItems[detail.name] * detail.count
        end
    end
end

local function findItemInInventory(itemName)
    for i = 1, NUM_SLOTS, 1 do
        local item = turtle.getItemDetail(i)
        if (item ~= nil) then
            if (itemName == "fuel") then
                for key, value in pairs(fuelItems) do
                    if key == item.name then
                        return i
                    end
                end
            elseif (item.name) == itemName then
                return i
            end
        elseif itemName == "empty" then
            return i
        end
    end
    return nil
end

return { refuel = refuel, findItemInInventory = findItemInInventory, fuelItems = fuelItems, NUM_SLOTS = 16 }
