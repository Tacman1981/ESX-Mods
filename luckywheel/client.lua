local wheelSpinning = false
local lastCooldownRequest = 0 -- Timestamp of the last cooldown request
local isNearWheel = false -- Track if the player is near the wheel
local remainingCooldown = 0 -- Store the remaining cooldown time

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

local prizes = Config.Prizes


local fakeWheelModel = "prop_casino_roulette_01" -- Replace with the actual model name of the fake wheel
local fakeWheelCoords = vector4(1111.147217, 229.292313, -49.644653, 180.0) -- Replace with the desired coordinates and heading
local fakeWheelOffset = vector3(0.0, 0.0, 0.0) -- Offset the fake wheel slightly

Citizen.CreateThread(function()
    -- Load the fake wheel model
    RequestModel(fakeWheelModel)
    while not HasModelLoaded(fakeWheelModel) do
        Citizen.Wait(0)
    end

    -- Create the fake wheel entity
    local fakeWheel = CreateObject(fakeWheelModel, fakeWheelCoords.x + fakeWheelOffset.x, fakeWheelCoords.y + fakeWheelOffset.y, fakeWheelCoords.z + fakeWheelOffset.z, false, false, false)
    SetEntityHeading(fakeWheel, fakeWheelCoords.w) -- Set the heading
    FreezeEntityPosition(fakeWheel, true) -- Prevent the fake wheel from moving
end)


-- Listen for the server response to the cooldown request
RegisterNetEvent('luckywheel:receiveCooldown')
AddEventHandler('luckywheel:receiveCooldown', function(remainingTime)
    remainingCooldown = remainingTime
end)

-- Listen for the server response to the spin event
RegisterNetEvent('luckywheel:spinConfirmed')
AddEventHandler('luckywheel:spinConfirmed', function(prizeName, prizeMoney, prizeItem, prizeQuantity)
    -- Check if prize is money or item, and display accordingly
    if prizeName then
        local message = "You won: " .. prizeName
        if prizeMoney and prizeMoney > 0 then
            message = message .. " (" .. prizeMoney .. " cash)"
        elseif prizeItem then
            message = message .. " (" .. prizeQuantity .. "x " .. prizeItem .. ")"
        end

        -- Show a notification or chat message
        TriggerEvent('chat:addMessage', {
            color = {0, 255, 0},
            multiline = true,
            args = {"Lucky Wheel", message}
        })
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0) -- Wait 1 second between checks

        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local wheelCoords = vector3(1111.147217, 229.292313, -49.644653) -- Wheel location

        local distance = #(playerCoords - wheelCoords)
        if distance < 2.0 and not wheelSpinning then
            isNearWheel = true

            -- Throttle cooldown requests to once every 5 seconds
            local currentTime = GetGameTimer()
            if currentTime - lastCooldownRequest >= 1000 then
                print("Requesting cooldown...") -- Debug message
                TriggerServerEvent('luckywheel:getCooldown')
                lastCooldownRequest = currentTime
            end

            -- If the cooldown has passed, allow the player to spin
            if remainingCooldown <= 0 then
                DrawTextOnScreen("Press ~g~E~s~ to spin the Lucky Wheel", 0.5, 0.9)

                if IsControlJustReleased(0, 38) then -- E key
                    print("E key pressed! Attempting to spin the wheel...") -- Debug message
                    TriggerServerEvent('luckywheel:spin') -- Notify the server of the spin
                end
            else
                -- Show the remaining cooldown time
                local secondsLeft = math.ceil(remainingCooldown / 1000)
                DrawTextOnScreen("You can spin the wheel again in: ~y~" .. secondsLeft .. " seconds", 0.5, 0.9)
            end
        else
            isNearWheel = false
            -- Clear the text if the player is not near the wheel
            DrawTextOnScreen("", 0.5, 0.9)
        end
    end
end)

-- Function to draw text on the screen
function DrawTextOnScreen(text, x, y)
    SetTextFont(4) -- Change font if needed
    SetTextProportional(1)
    SetTextScale(0.4, 0.4)
    SetTextColour(255, 255, 255, 255) -- White color
    SetTextJustification(1)
    SetTextCentre(true)
    SetTextOutline() -- Add outline for better visibility

    BeginTextCommandDisplayText("STRING")
    AddTextComponentString(text)
    DrawText(x, y)
end