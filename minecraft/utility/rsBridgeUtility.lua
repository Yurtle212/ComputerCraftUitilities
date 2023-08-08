local yurtle = require "yurtle"

local function RetrieveItemFromStorage(rsBridge, order, depositDirection)
    local items = rsBridge.listItems()
    if (order.item == "fuel") then
        local fuelGotten = 0
        local itemsForExport = {

        }

        for key, value in pairs(yurtle.fuelItems) do
            local item = rsBridge.getItem({ name = key })
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

                itemsForExport[#itemsForExport + 1] = {
                    name = key,
                    count = fuelAmount
                }
            end
        end

        for i = #itemsForExport, 1, -1 do
            if rsBridge.getItem({ name = itemsForExport[i].name }).amount > itemsForExport[i].count then
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

local function PutItemInStorage(rsBridge, slot, extractDirection, amount)
    if (amount == nil) then
        amount = 9999
    end

    local detail = turtle.getItemDetail(slot)
    if detail ~= nil then
        rsBridge.importItem({
            name = detail.name,
            count = math.min(detail.count, amount)
        }, extractDirection)
        return true
    end
    return false
end

local function getFuelInStorage(rsBridge)
    local storedFuel = 0
    for key, value in pairs(yurtle.fuelItems) do
        local item = rsBridge.getItem({ name = key })
        storedFuel = storedFuel + (value * item.amount)
    end
    return storedFuel
end

return { RetrieveItemFromStorage = RetrieveItemFromStorage, PutItemInStorage = PutItemInStorage, getFuelInStorage = getFuelInStorage }