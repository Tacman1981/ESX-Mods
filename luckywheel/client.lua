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

    -- Reset the wheel spinning state
    wheelSpinning = false
end)

RegisterNetEvent('luckywheel:playSound')
AddEventHandler('luckywheel:playSound', function()
    local soundId = GetSoundId()
    print("Playing sound with ID: " .. soundId) -- Debug message
    PlaySoundFromEntity(soundId, "Spin_Start", _wheel, 'dlc_vw_casino_lucky_wheel_sounds', 1, 1)
    
    -- Stop the spinning sound after a delay
    Citizen.Wait(5000) -- Adjust the delay as needed
    StopSound(soundId)
    ReleaseSoundId(soundId)
end)

-- filepath: /E:/repos/ESX-Mods/luckywheel/client.lua
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
                --print("Requesting cooldown...")
                TriggerServerEvent('luckywheel:getCooldown')
                lastCooldownRequest = currentTime
            end

            -- If the cooldown has passed, allow the player to spin
            if remainingCooldown <= 0 then
                DrawTextOnScreen("Press ~g~E~s~ to spin the Lucky Wheel", 0.5, 0.9)

                if IsControlJustReleased(0, 38) then -- E key
                    print("E key pressed! Attempting to spin the wheel...") -- Debug message
                    wheelSpinning = true

                    -- Trigger the client event to play the sound
                    TriggerEvent('luckywheel:playSound')

                    -- Delay before notifying the server
                    Citizen.Wait(5000) -- 2 seconds delay for spinning effect

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