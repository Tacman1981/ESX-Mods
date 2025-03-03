local wheelSpinning = false
local lastCooldownRequest = 0
local isNearWheel = false
local remainingCooldown = 0

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

RegisterNetEvent('luckywheel:receiveCooldown')
AddEventHandler('luckywheel:receiveCooldown', function(remainingTime)
    remainingCooldown = remainingTime
end)

RegisterNetEvent('luckywheel:spinConfirmed')
AddEventHandler('luckywheel:spinConfirmed', function(prizeName, prizeMoney, prizeItem, prizeQuantity)
    if prizeName then
        local message = "You won: " .. prizeName
        if prizeMoney and prizeMoney > 0 then
            message = message .. " (" .. prizeMoney .. " cash)"
        elseif prizeItem then
            message = message .. " (" .. prizeQuantity .. "x " .. prizeItem .. ")"
        end

        TriggerEvent('chat:addMessage', {
            color = {0, 255, 0},
            multiline = true,
            args = {"Lucky Wheel", message}
        })
    end

    wheelSpinning = false
end)

RegisterNetEvent('luckywheel:playSound')
AddEventHandler('luckywheel:playSound', function()
    local soundId = GetSoundId()
    if soundId ~= -1 then
        --print("Playing sound with ID: " .. soundId)

        -- Play the sound
        PlaySoundFromEntity(soundId, "Spin_Start", PlayerPedId(), 'dlc_vw_casino_lucky_wheel_sounds', 1, 1)

        Citizen.CreateThread(function()
            Citizen.Wait(10000)
            StopSound(soundId)
            ReleaseSoundId(soundId)
            --print("Sound stopped and sound ID released.")
        end)
    else
        --print("Failed to get a valid sound ID.")
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0) -- Wait 1 second between checks

        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local wheelCoords = vector3(1111.147217, 229.292313, -49.644653)

        local distance = #(playerCoords - wheelCoords)
        if distance < 2.0 and not wheelSpinning then
            isNearWheel = true

            local currentTime = GetGameTimer()
            if currentTime - lastCooldownRequest >= 1000 then
                --print("Requesting cooldown...")
                TriggerServerEvent('luckywheel:getCooldown')
                lastCooldownRequest = currentTime
            end

            if remainingCooldown <= 0 then
                DrawTextOnScreen("Press ~g~E~s~ to spin the Lucky Wheel", 0.5, 0.9)

                if IsControlJustReleased(0, 38) then -- E key
                    --print("E key pressed! Attempting to spin the wheel...") -- Debug message
                    wheelSpinning = true

                    TriggerEvent('luckywheel:playSound')

                    Citizen.Wait(10000)

                    TriggerServerEvent('luckywheel:spin')
                end
            else
                -- Show the remaining cooldown time
                local secondsLeft = math.ceil(remainingCooldown / 1000)
                DrawTextOnScreen("You can spin the wheel again in: ~y~" .. secondsLeft .. " seconds", 0.5, 0.9)
            end
        else
            isNearWheel = false
            DrawTextOnScreen("", 0.5, 0.9)
        end
    end
end)

function DrawTextOnScreen(text, x, y)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextScale(0.4, 0.4)
    SetTextColour(255, 255, 255, 255)
    SetTextJustification(1)
    SetTextCentre(true)
    SetTextOutline()

    BeginTextCommandDisplayText("STRING")
    AddTextComponentString(text)
    DrawText(x, y)
end

Citizen.CreateThread(function()
    local blip = AddBlipForCoord(1111.147217, 229.292313, -49.644653) -- Wheel location

    SetBlipSprite(blip, 681) -- Set the blip icon (679 is the casino icon, change if needed)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 1.0)
    SetBlipColour(blip, 5)
    SetBlipAsShortRange(blip, true)

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Lucky Wheel")
    EndTextCommandSetBlipName(blip)
end)