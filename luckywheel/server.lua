local ESX = nil

-- Wait for ESX to initialize
TriggerEvent('esx:getSharedObject', function(obj) 
    ESX = obj 
end)

local playerCooldowns = {} -- Store player cooldowns by their identifier
local cooldown = 1800000

local prizes = {
    {name = "$50,000", money = 50000},
    {name = "$20,000", money = 20000},
    {name = "$15,000", money = 15000},
    {name = "$10,000", money = 10000},
    {name = "$7,500", money = 7500},
    {name = "$5,000", money = 5000},
    {name = "$5,000", money = 5000}, -- Duplicate for more chances
    {name = "$3,000", money = 3000},
    {name = "$3,000", money = 3000}, -- Duplicate for more chances
    {name = "$2,000", money = 2000},
    {name = "$1,000", money = 1000},
    {name = "$1,000", money = 1000}, -- Duplicate for more chances
    {name = "Bagged Cocaine", money = 0, item = "coke_pooch", minQuantity = 50, maxQuantity = 1000},  -- Random quantity range
    {name = "Amfetamine Pooch", money = 0, item = "amfe_pooch", minQuantity = 50, maxQuantity = 1000},  -- Random quantity range
    {name = "Marijuana", money = 0, item = "marijuana", minQuantity = 50, maxQuantity = 1000},  -- Random quantity range
    {name = "Mystery Prize", money = 0},  -- Set initial money to 0, dynamically set later
    {name = "Nothing", money = 0}
}

-- Event to get the player's cooldown status
RegisterServerEvent('luckywheel:getCooldown')
AddEventHandler('luckywheel:getCooldown', function()
    local src = source
    local identifier = GetPlayerIdentifier(src, 0) -- Get the player's identifier

    local lastSpin = playerCooldowns[identifier] or 0
    local currentTime = os.time() * 1000
    local remainingTime = math.max(0, lastSpin + cooldown - currentTime)

    -- Send the remaining cooldown time to the client
    TriggerClientEvent('luckywheel:receiveCooldown', src, remainingTime)
end)

RegisterServerEvent('luckywheel:spin')
AddEventHandler('luckywheel:spin', function()
    local src = source
    local identifier = GetPlayerIdentifier(src, 0) -- Get the player's identifier

    local lastSpin = playerCooldowns[identifier] or 0
    local currentTime = os.time() * 1000

    if currentTime >= lastSpin + cooldown then
        -- Update the player's last spin time
        playerCooldowns[identifier] = currentTime

        -- Generate a random prize
        local prizeIndex = math.random(1, #prizes)

        -- Make sure "Nothing" doesn't get selected as often
        while prizes[prizeIndex].name == "Nothing" do
            prizeIndex = math.random(1, #prizes)
        end

        local prize = prizes[prizeIndex]

        -- If the prize is a "Mystery Prize", generate the money dynamically
        if prize.name == "Mystery Prize" then
            prize.money = math.random(1000, 50000)
        end

        -- Handle the case for random quantities of items
        if prize.item and prize.minQuantity and prize.maxQuantity then
            -- Generate a random quantity between min and max
            prize.quantity = math.random(prize.minQuantity, prize.maxQuantity)
        end

        -- Debugging: Print the prize to check it
        print("Prize awarded: " .. prize.name .. " - Money: " .. (prize.money or 0) .. " - Quantity: " .. (prize.quantity or 0))

        -- Notify the player of their prize (send prize details to client)
        TriggerClientEvent('luckywheel:spinConfirmed', src, prize.name, prize.money, prize.item, prize.quantity)

        -- If the prize includes money (and it's greater than 0)
        if prize.money and prize.money > 0 then
            -- Add money to player's inventory using player.addMoney
            local xPlayer = ESX.GetPlayerFromId(src)
            xPlayer.addMoney(prize.money)  -- Correct method to add money

            -- Debug message to confirm the action
            print("Giving " .. prize.money .. " money to player " .. identifier)
        end

        -- If the prize is an item, give the item to the player with the random quantity
        if prize.item then
            local xPlayer = ESX.GetPlayerFromId(src)
            xPlayer.addInventoryItem(prize.item, prize.quantity)  -- Add the random quantity of the item

            -- Debug message to confirm the action
            print("Giving " .. prize.quantity .. " of " .. prize.item .. " to player " .. identifier)
        end

        -- Send the updated cooldown to the client
        TriggerClientEvent('luckywheel:receiveCooldown', src, cooldown)
    else
        -- Notify the player they are on cooldown
        TriggerClientEvent('chat:addMessage', src, {
            color = {255, 0, 0},
            multiline = true,
            args = {"Casino", "You cannot spin the wheel yet!"}
        })
    end
end)