function IsStoreOpen(shop)
    if not Config.Hours.enable then return true end
    if shop.Hours and shop.Hours.alwaysOpen then return true end

    local hours = shop.Hours or Config.Hours
    local hour = GetClockHours()

    if hours.open > hours.close then
        return hour >= hours.open or hour < hours.close
    end

    return hour >= hours.open and hour < hours.close
end

local exitUnlockUntil = {}
local nearClosedStore = {}

CreateThread(function()
    while true do
        local playerCoords = GetEntityCoords(PlayerPedId())
        local now = GetGameTimer()
        for _, shop in pairs(Config.Shops) do
            local open = IsStoreOpen(shop)
            if shop.Doors and #shop.Doors > 0 then
                local nearby = #(playerCoords - vector3(shop.coords.x, shop.coords.y, shop.coords.z)) <= Config.MaxInteractDistance
                if not open and nearby then
                    if not nearClosedStore[shop.id] and not exitUnlockUntil[shop.id] then
                        exitUnlockUntil[shop.id] = now + Config.Hours.unlockDuration
                        lib.notify({
                            title = 'Store Closed',
                            description = 'Doors unlocked, please leave.',
                            type = 'inform',
                            duration = 10000,
                        })
                    end
                    nearClosedStore[shop.id] = true
                else
                    nearClosedStore[shop.id] = nil
                end

                if open or (exitUnlockUntil[shop.id] and now >= exitUnlockUntil[shop.id]) then
                    exitUnlockUntil[shop.id] = nil
                end
                local unlocked = open or exitUnlockUntil[shop.id] ~= nil
                for _, doorId in ipairs(shop.Doors) do
                    Citizen.InvokeNative(0xD99229FE93B46286, doorId, 1, 1, 0, 0, 0, 0)
                    if not unlocked then
                        Citizen.InvokeNative(0xB6E6FBA95C7324AC, doorId, 0.0, true)
                    end
                    Citizen.InvokeNative(0x6BAB9442830C7F53, doorId, unlocked and 0 or 3)
                end
            end
        end
        Wait(1000)
    end
end)
