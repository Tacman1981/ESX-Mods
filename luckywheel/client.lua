local wheelSpinning = false
local lastSpinTime = 0 -- Timestamp of the last spin
local cooldown = 1800000
local lastCooldownRequest = 0 -- Timestamp of the last cooldown request
local isNearWheel = false -- Track if the player is near the wheel

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
    {name = "Bagged Cocaine", money = 0, item = "coke_pooch", minQuantity = 1, maxQuantity = 10},  -- Random quantity range
    {name = "Amfetamine Pooch", money = 0, item = "amfe_pooch", minQuantity = 1, maxQuantity = 10},  -- Random quantity range
    {name = "Marijuana", money = 0, item = "marijuana", minQuantity = 1, maxQuantity = 10},  -- Random quantity range
    {name = "Mystery Prize", money = 0},  -- Set initial money to 0, dynamically set later
    {name = "Nothing", money = 0}
}

-- Listen for the server response to the cooldown request
RegisterNetEvent('luckywheel:receiveCooldown')
AddEventHandler('luckywheel:receiveCooldown', function(remainingTime)
    if remainingTime <= 0 then
        -- No cooldown left, the player can spin
        lastSpinTime = 0
    else
        -- Set the last spin time and calculate the remaining cooldown
        lastSpinTime = GetGameTimer() + remainingTime
    end
end)

-- Listen for the server response to the spin event
RegisterNetEvent('luckywheel:spinConfirmed')
AddEventHandler('luckywheel:spinConfirmed', function(prizeName, prizeMoney, prizeItem)
    -- Check if prize is money or item, and display accordingly
    if prizeName then
        local message = "You won: " .. prizeName
        if prizeMoney and prizeMoney > 0 then
            message = message .. " (" .. prizeMoney .. " cash)"
        elseif prizeItem then
            message = message .. " (" .. prizeItem .. ")"
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
            if currentTime - lastCooldownRequest >= 5000 then
                print("Requesting cooldown...") -- Debug message
                TriggerServerEvent('luckywheel:getCooldown')
                lastCooldownRequest = currentTime
            end

            -- If the cooldown has passed, allow the player to spin
            if lastSpinTime == 0 or GetGameTimer() - lastSpinTime >= cooldown then
                DrawTextOnScreen("Press ~g~E~s~ to spin the Lucky Wheel", 0.5, 0.9)

                if IsControlJustReleased(0, 38) then -- E key
                    print("E key pressed! Attempting to spin the wheel...") -- Debug message
                    TriggerServerEvent('luckywheel:spin') -- Notify the server of the spin
                end
            else
                -- Show the remaining cooldown time
                local remainingTime = cooldown - (GetGameTimer() - lastSpinTime)
                local secondsLeft = math.ceil(remainingTime / 1000)
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