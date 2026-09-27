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

StoreHoursShops = {}
for _, shop in pairs(Config.Shops) do
    StoreHoursShops[shop.id] = shop
end

IgnoreLocation = nil

exports('SetIgnoreLocation', function(locationName)
    IgnoreLocation = locationName
end)

local exitUnlockUntil = {}
local nearClosedStore = {}
local lockedCoordinateDoors = {}

local function getCoordinateDoorEntity(door)
    local configuredModel = door.model < 0 and door.model + 4294967296 or door.model

    for _, object in ipairs(GetGamePool('CObject')) do
        if DoesEntityExist(object) then
            local objectModel = GetEntityModel(object)
            objectModel = objectModel < 0 and objectModel + 4294967296 or objectModel

            if objectModel == configuredModel and #(GetEntityCoords(object) - door.coords) <= 2.0 then
                return object
            end
        end
    end

    return 0
end

CreateThread(function()
    while true do
        local playerCoords = GetEntityCoords(PlayerPedId())
        local now = GetGameTimer()
        for _, shop in pairs(StoreHoursShops) do
            local open = IsStoreOpen(shop)
            local hasDoorHashes = shop.Doors and #shop.Doors > 0
            local hasCoordinateDoors = shop.DoorsCoords and #shop.DoorsCoords > 0
            if hasDoorHashes or hasCoordinateDoors then
                local ignoreLocation = shop.id == IgnoreLocation
                if ignoreLocation then
                    nearClosedStore[shop.id] = nil
                    exitUnlockUntil[shop.id] = nil
                    if hasCoordinateDoors then
                        for _, door in ipairs(shop.DoorsCoords) do
                            local entity = getCoordinateDoorEntity(door)
                            if entity ~= 0 then
                                FreezeEntityPosition(entity, false)
                                lockedCoordinateDoors[entity] = nil
                            end
                        end
                    end
                else
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
                    if hasDoorHashes then
                        for _, doorId in ipairs(shop.Doors) do
                            Citizen.InvokeNative(0xD99229FE93B46286, doorId, 1, 1, 0, 0, 0, 0)
                            if not unlocked then
                                Citizen.InvokeNative(0xB6E6FBA95C7324AC, doorId, 0.0, true)
                            end
                            Citizen.InvokeNative(0x6BAB9442830C7F53, doorId, unlocked and 0 or 3)
                        end
                    end
                    if hasCoordinateDoors then
                        for _, door in ipairs(shop.DoorsCoords) do
                            local entity = getCoordinateDoorEntity(door)
                            if entity ~= 0 then
                                if unlocked then
                                    FreezeEntityPosition(entity, false)
                                    lockedCoordinateDoors[entity] = nil
                                else
                                    SetEntityHeading(entity, door.heading)
                                    FreezeEntityPosition(entity, true)
                                    lockedCoordinateDoors[entity] = true
                                end
                            end
                        end
                    end
                end
            end
        end

        for entity in pairs(lockedCoordinateDoors) do
            if not DoesEntityExist(entity) then
                lockedCoordinateDoors[entity] = nil
            end
        end

        Wait(1000)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    for entity in pairs(lockedCoordinateDoors) do
        if DoesEntityExist(entity) then
            FreezeEntityPosition(entity, false)
        end
    end
end)
