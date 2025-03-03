local ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) 
    ESX = obj 
end)

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

local playerCooldowns = {}
local cooldown = Config.Cooldown or 3600000

local prizes = Config.Prizes

local totalWeight = 0
for _, prize in ipairs(prizes) do
    totalWeight = totalWeight + prize.weight
end

RegisterServerEvent('luckywheel:getCooldown')
AddEventHandler('luckywheel:getCooldown', function()
    local src = source
    local identifier = GetPlayerIdentifier(src, 0)

    local lastSpin = playerCooldowns[identifier] or 0
    local currentTime = os.time() * 1000
    local remainingTime = math.max(0, lastSpin + cooldown - currentTime)

    TriggerClientEvent('luckywheel:receiveCooldown', src, remainingTime)
end)

RegisterServerEvent('luckywheel:spin')
AddEventHandler('luckywheel:spin', function()
    local src = source
    local identifier = GetPlayerIdentifier(src, 0)

    local lastSpin = playerCooldowns[identifier] or 0
    local currentTime = os.time() * 1000

    if currentTime >= lastSpin + cooldown then
        playerCooldowns[identifier] = currentTime

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

        if prize.name == "Mystery Cash Prize" then
            prize.money = math.random(prize.minMoney, prize.maxMoney)
        end

        if prize.item and prize.minQuantity and prize.maxQuantity then
            prize.quantity = math.random(prize.minQuantity, prize.maxQuantity)
        end

        print("Prize awarded: " .. prize.name .. " - Money: " .. (prize.money or 0) .. " - Quantity: " .. (prize.quantity or 0))

        TriggerClientEvent('luckywheel:spinConfirmed', src, prize.name, prize.money, prize.item, prize.quantity)

        if prize.money and prize.money > 0 then
            local xPlayer = ESX.GetPlayerFromId(src)
            if xPlayer then
                xPlayer.addMoney(prize.money)

                print("Giving " .. prize.money .. " money to player " .. identifier)
            else
                print("Error: Player not found for ID " .. src)
            end
        end

        if prize.item then
            local xPlayer = ESX.GetPlayerFromId(src)
            if xPlayer then
                xPlayer.addInventoryItem(prize.item, prize.quantity)

                print("Giving " .. prize.quantity .. " of " .. prize.item .. " to player " .. identifier)
            else
                print("Error: Player not found for ID " .. src)
            end
        end

        TriggerClientEvent('luckywheel:receiveCooldown', src, cooldown)
    else
        TriggerClientEvent('chat:addMessage', src, {
            color = {255, 0, 0},
            multiline = true,
            args = {"Casino", "You cannot spin the wheel yet!"}
        })
    end
end)
