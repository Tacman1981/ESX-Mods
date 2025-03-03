local ESX = nil

-- Wait for ESX to initialize
TriggerEvent('esx:getSharedObject', function(obj) 
    ESX = obj 
end)

-- Load the configuration file
Config = {}
Config.Prizes = {}

local configFile = LoadResourceFile(GetCurrentResourceName(), "config.lua")
if configFile then
    local configFunc = load(configFile)
    if configFunc then
        configFunc()
        Config = _G.Config
    end
end

local playerCooldowns = {} -- Store player cooldowns by their identifier
local cooldown = Config.Cooldown or 3600000 -- Default to 60 minutes if not set

local prizes = Config.Prizes

-- Calculate the total weight of all prizes
local totalWeight = 0
for _, prize in ipairs(prizes) do
    totalWeight = totalWeight + prize.weight
end

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

        -- Generate a random prize based on weights
        local randomWeight = math.random() * totalWeight
        local cumulativeWeight = 0
        local prize

        for _, p in ipairs(prizes) do
            cumulativeWeight = cumulativeWeight + p.weight
            if randomWeight <= cumulativeWeight then
                prize = p
                break
            end
        end

        -- If the prize is a "Mystery Cash Prize", generate the money dynamically
        if prize.name == "Mystery Cash Prize" then
            prize.money = math.random(prize.minMoney, prize.maxMoney)
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
            local xPlayer = ESX.GetPlayerFromId(src)
            if xPlayer then
                xPlayer.addMoney(prize.money)  -- Correct method to add money

                -- Debug message to confirm the action
                print("Giving " .. prize.money .. " money to player " .. identifier)
            else
                print("Error: Player not found for ID " .. src)
            end
        end

        -- If the prize is an item, give the item to the player with the random quantity
        if prize.item then
            local xPlayer = ESX.GetPlayerFromId(src)
            if xPlayer then
                xPlayer.addInventoryItem(prize.item, prize.quantity)  -- Add the random quantity of the item

                -- Debug message to confirm the action
                print("Giving " .. prize.quantity .. " of " .. prize.item .. " to player " .. identifier)
            else
                print("Error: Player not found for ID " .. src)
            end
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