local RSGCore = exports['rsg-core']:GetCoreObject()

lib.locale()

-- All player-facing NUI text, built once from locales/en.json (or whatever
-- ox_lib resolves to for this client) and sent to the NUI alongside every
-- shop payload so script.js never has to hardcode English strings itself.
local UiLocale = {
    subtitle = locale('ui.subtitle'),
    tabBuy = locale('ui.tab_buy'),
    tabSell = locale('ui.tab_sell'),
    basketHintPrefix = locale('ui.basket_hint_prefix'),
    basketHintSuffix = locale('ui.basket_hint_suffix'),
    clear = locale('ui.clear'),
    checkout = locale('ui.checkout'),
    sellItems = locale('ui.sell_items'),
    headingBuy = locale('ui.heading_buy'),
    headingSell = locale('ui.heading_sell'),
    totalLabelBuy = locale('ui.total_label_buy'),
    totalLabelSell = locale('ui.total_label_sell'),
    emptyBuy = locale('ui.empty_buy'),
    emptySell = locale('ui.empty_sell'),
    addToBasket = locale('ui.add_to_basket'),
    sellButton = locale('ui.sell_button'),
    ownedPrefix = locale('ui.owned_prefix'),
    unitSuffix = locale('ui.unit_suffix'),
    toastNoItemTitle = locale('ui.toast_no_item_title'),
    toastNoItem = locale('ui.toast_no_item'),
    toastCapSellTitle = locale('ui.toast_cap_sell_title'),
    toastCapBuyTitle = locale('ui.toast_cap_buy_title'),
    toastCapSell = locale('ui.toast_cap_sell'),
    toastCapBuy = locale('ui.toast_cap_buy'),
    toastBasketFullTitle = locale('ui.toast_basket_full_title'),
    toastBasketFull = locale('ui.toast_basket_full'),
    close = locale('ui.close'),
}

local shopsById = {}
local currentShop = nil
local spawnedPeds = {}
local shopZones = {}

for _, shop in pairs(Config.Shops) do
    shopsById[shop.id] = shop
end

local function buildCategoryPayload(groups, direction, shop, priceOverrides)
    local out = {}
    local priceField = direction .. 'Price'

    for _, group in ipairs(groups) do
        local category = Config.ItemGroups[group[1]]
        local regionalAdjustment = group[2]
        local items = {}

        for _, entry in ipairs(category.items) do
            local itemData = RSGCore.Shared.Items[entry.name]

            if itemData and entry[priceField] ~= nil then
                local price = math.max(0.01, entry[priceField] + regionalAdjustment)
                items[#items + 1] = {
                    name = entry.name,
                    label = itemData.label or entry.name,
                    price = (priceOverrides and priceOverrides[entry.name]) or price,
                    image = 'nui://' .. Config.Img .. (itemData.image or (entry.name .. '.png')),
                }
            elseif not itemData and entry[priceField] ~= nil then
                print(('[rsg-stores] WARNING: item "%s" (shop "%s") does not exist in RSGCore.Shared.Items and was skipped'):format(entry.name, shop.id))
            end
        end

        out[#out + 1] = {
            id = category.id,
            label = category.label,
            icon = category.icon,
            items = items,
        }
    end

    return out
end

local function buildShopPayload(shop, state)
    local payload = {
        id = shop.id,
        label = shop.label,
        categories = buildCategoryPayload(shop.buy, 'buy', shop, state and state.buyPrices),
        maxUniqueItems = Config.MaxUniqueBasketItems,
        maxItemQuantity = Config.MaxItemQuantity,
        locale = UiLocale,
    }

    if shop.sell then
        payload.sell = {
            categories = buildCategoryPayload(shop.sell, 'sell', shop, state and state.sellPrices),
            owned = (state and state.owned) or {},
            maxUniqueItems = Config.MaxUniqueSellItems,
            maxItemQuantity = Config.MaxSellQuantity,
        }
    end

    return payload
end

local function OpenShop(shopId)
    local shop = shopsById[shopId]
    if not shop then return end

    currentShop = shop

    RSGCore.Functions.TriggerCallback('rsg-stores:server:getShopState', function(state)
        if currentShop ~= shop then return end

        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'open',
            shop = buildShopPayload(shop, state),
        })
    end, shop.id)
end

local function CloseShop()
    if not currentShop then return end
    currentShop = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

CreateThread(function()
    while true do
        Wait(1000)
        if currentShop then
            local shop = currentShop
            local playerCoords = GetEntityCoords(PlayerPedId())
            local dist = #(playerCoords - vector3(shop.coords.x, shop.coords.y, shop.coords.z))
            if dist > Config.MaxInteractDistance + 2.0 then
                CloseShop()
            end
        end
    end
end)

RegisterNUICallback('close', function(_, cb)
    CloseShop()
    cb({})
end)

RegisterNUICallback('checkout', function(data, cb)
    cb({})

    if not currentShop then return end
    if type(data) ~= 'table' or type(data.basket) ~= 'table' then return end

    TriggerServerEvent('rsg-stores:server:checkout', currentShop.id, data.basket)
end)

RegisterNUICallback('sellCheckout', function(data, cb)
    cb({})

    if not currentShop then return end
    if type(data) ~= 'table' or type(data.basket) ~= 'table' then return end

    TriggerServerEvent('rsg-stores:server:sellCheckout', currentShop.id, data.basket)
end)

RegisterNetEvent('rsg-stores:client:checkoutResult', function(success)
    SendNUIMessage({
        action = 'checkoutResult',
        success = success,
    })

    if success then
        CloseShop()
    end
end)

RegisterNetEvent('rsg-stores:client:sellResult', function(success)
    SendNUIMessage({
        action = 'sellResult',
        success = success,
    })

    if success then
        CloseShop()
    end
end)

-- Shop zones are independent of the optional NPC.
local function registerShopInteraction(shop)
    local zone = exports.ox_target:addBoxZone({
        name = 'rsg_stores_' .. shop.id,
        coords = vector3(shop.coords.x, shop.coords.y, shop.coords.z + 1.0),
        size = vector3(1.5, 1.5, 2.0),
        rotation = shop.coords.w,
        options = {
            {
                name = 'rsg_stores_' .. shop.id,
                icon = 'fa-solid fa-cart-shopping',
                label = locale('ui.browse', shop.label),
                distance = Config.MaxInteractDistance,
                onSelect = function()
                    OpenShop(shop.id)
                end,
            },
        },
    })
    shopZones[#shopZones + 1] = zone

    if shop.npc == false then return end

    if not shop.npcmodel then
        print(('[rsg-stores] WARNING: shop "%s" has no npcmodel set -- NPC will not be spawned.'):format(shop.id))
        return
    end
    local model = joaat(shop.npcmodel)
    RequestModel(model)
    local attempts = 0
    while not HasModelLoaded(model) and attempts < 100 do
        Wait(10)
        attempts = attempts + 1
    end

    if not HasModelLoaded(model) then
        print(('[rsg-stores] WARNING: ped model "%s" for shop "%s" failed to load -- NPC will not be spawned.'):format(shop.npcmodel, shop.id))
        return
    end

    local ped = CreatePed(model, shop.coords.x, shop.coords.y, shop.coords.z, shop.coords.w, false, false)
    SetModelAsNoLongerNeeded(model)
    SetRandomOutfitVariation(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    SetEntityAsMissionEntity(ped, true, true)
    spawnedPeds[#spawnedPeds + 1] = ped
end

CreateThread(function()
    if GetResourceState('ox_target') ~= 'started' then
        print('[rsg-stores] WARNING: ox_target is not running -- shop interactions will not be registered until it starts.')
        return
    end

    for _, shop in pairs(Config.Shops) do
        local ok, err = pcall(registerShopInteraction, shop)
        if not ok then
            print(('[rsg-stores] ERROR registering interaction for shop "%s": %s'):format(shop.id, err))
        end

        if shop.blip and shop.blip.show then
            local blip = BlipAddForCoords(1664425300, shop.coords.x, shop.coords.y, shop.coords.z)
            SetBlipSprite(blip, joaat(shop.blip.sprite))
            SetBlipScale(blip, shop.blip.scale)
            SetBlipName(blip, shop.blip.label)
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if GetCurrentResourceName() ~= resource then return end

    if currentShop then
        currentShop = nil
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'close' })
    end

    if GetResourceState('ox_target') == 'started' then
        for _, zone in ipairs(shopZones) do
            exports.ox_target:removeZone(zone)
        end
    end
    for _, ped in ipairs(spawnedPeds) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end
end)
