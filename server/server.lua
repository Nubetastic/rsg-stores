local RSGCore = exports['rsg-core']:GetCoreObject()

lib.locale()

local shopsById = {}

for _, shop in pairs(Config.Shops) do
    shopsById[shop.id] = shop
end

-- Per-shop, per-item live price multiplier (1.0 = base price). In-memory
-- only -- resets to 1.0 on resource/server restart.
local priceState = {}

-- Prevents a client from triggering checkout/sellCheckout for a shop it
-- isn't actually near -- without this, the events below could be fired
-- directly (bypassing ox_target/the NUI entirely) to buy or sell from
-- anywhere on the map. A little slack is added on top of the configured
-- interaction distance to allow for latency/movement between the client
-- opening the menu and the checkout request arriving.
local function isPlayerNearShop(src, shop)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end

    local playerCoords = GetEntityCoords(ped)
    local shopCoords = vector3(shop.coords.x, shop.coords.y, shop.coords.z)
    local maxDistance = (Config.MaxInteractDistance or 3.0) + 3.0

    return #(playerCoords - shopCoords) <= maxDistance
end

-- Guards against a player double-submitting checkout/sellCheckout (e.g.
-- spamming the button, or two forged events in quick succession) while a
-- previous request from them is still being processed.
local playersProcessing = {}

local function tryLockPlayer(src)
    if playersProcessing[src] then return false end
    playersProcessing[src] = true
    return true
end

local function unlockPlayer(src)
    playersProcessing[src] = nil
end

AddEventHandler('playerDropped', function()
    unlockPlayer(source)
end)

local function notifyError(src, title, description)
    TriggerClientEvent('ox_lib:notify', src, {
        title = title,
        description = description,
        type = 'error',
    })
end

-- "Firstname Lastname (`citizenid`)", falling back gracefully if charinfo
-- is missing pieces -- used to identify the player in Discord webhook logs.
local function describePlayer(Player)
    local charinfo = Player.PlayerData.charinfo or {}
    local name = (('%s %s'):format(charinfo.firstname or '', charinfo.lastname or '')):match('^%s*(.-)%s*$')
    if name == '' then name = locale('webhook.unknown_player') or 'Unknown' end
    return ('%s (`%s`)'):format(name, Player.PlayerData.citizenid or 'unknown')
end

-- Builds the "• 3x Bread" style item list shared by both webhook embeds.
local function formatItemLines(entries)
    local lines = {}
    for _, entry in ipairs(entries) do
        lines[#lines + 1] = ('• %dx %s'):format(entry.amount, entry.label or entry.name)
    end
    return #lines > 0 and table.concat(lines, '\n') or (locale('webhook.no_items') or 'n/a')
end

-- true for any real, finite Lua number -- rejects NaN and +-inf, which a
-- crafted/forged event could otherwise sneak past the amount < 1/> max
-- range check below (comparisons against NaN are always false in Lua).
local function isFiniteNumber(n)
    return type(n) == 'number' and n == n and n ~= math.huge and n ~= -math.huge
end

local function copyShopData(data)
    if type(data) ~= 'table' then return data end
    local copy = {}
    for key, value in pairs(data) do
        copy[key] = copyShopData(value)
    end
    return copy
end

local function publishCustomShop(shop, changedItems, reason)
    shop.revision = shop.revision + 1
    TriggerClientEvent('rsg-stores:client:updateCustomShop', -1, shop.id, shop.itemGroups, shop.revision)
    if shop.custom and next(changedItems) then
        TriggerEvent('rsg-stores:server:CustomShopStockChanged', shop.id, copyShopData(changedItems), reason)
    end
end

for _, shop in pairs(Config.Shops) do
    shop.revision = 1
    shop.processing = false
    shop.itemGroups = {}
    shop.items = {}
    assert(shop.restockTime == nil or (isFiniteNumber(shop.restockTime) and shop.restockTime >= 0), 'Invalid restockTime for shop ' .. shop.id)
    for _, direction in ipairs({'buy', 'sell'}) do
        for _, reference in ipairs(shop[direction] or {}) do
            local groupName = reference[1]
            if not shop.itemGroups[groupName] then
                shop.itemGroups[groupName] = copyShopData(Config.ItemGroups[groupName])
                for _, item in ipairs(shop.itemGroups[groupName].items) do
                    assert(not shop.items[item.name], 'Duplicate item in shop ' .. shop.id .. ': ' .. item.name)
                    if item.amount ~= nil then
                        assert(isFiniteNumber(item.amount) and item.amount >= 0 and item.amount % 1 == 0
                            and isFiniteNumber(item.maxStock) and item.maxStock >= 0 and item.maxStock % 1 == 0,
                            'Finite items require nonnegative whole amount and maxStock: ' .. shop.id .. '/' .. item.name)
                        item.targetStock = item.amount
                    end
                    assert(item.restock == nil or (isFiniteNumber(item.restock) and item.restock >= 0 and item.restock % 1 == 0),
                        'Invalid restock quantity: ' .. shop.id .. '/' .. item.name)
                    shop.items[item.name] = item
                end
            end
        end
    end
    if shop.restockTime and shop.restockTime > 0 then shop.nextRestock = os.time() + shop.restockTime * 60 end
end

local function customShopPayload(shop)
    return {
        id = shop.id, label = shop.label, coords = shop.coords,
        npc = shop.npc, npcmodel = shop.npcmodel, blip = shop.blip,
        Hours = shop.Hours, Doors = shop.Doors,
        buy = shop.buy, sell = shop.sell, custom = true,
        itemGroups = shop.itemGroups, revision = shop.revision,
    }
end

exports('RegisterCustomShop', function(data, itemGroups)
    local owner = GetInvokingResource()
    if not owner or type(data) ~= 'table' or type(itemGroups) ~= 'table' then
        return false, 'Shop and itemGroups must be tables supplied by a server resource.'
    end
    if type(data.id) ~= 'string' or data.id == '' then
        return false, 'Shop ID is empty.'
    end
    local existing = shopsById[data.id]
    if existing then
        if not existing.custom or existing.owner ~= owner then return false, 'Shop ID is already registered by another resource.' end
        if existing.processing then return false, 'Shop is processing a transaction; retry the registration.' end
    end
    if type(data.label) ~= 'string' or data.label == '' then return false, 'Shop label is required.' end
    if type(data.coords) ~= 'vector4' and type(data.coords) ~= 'table' then return false, 'Shop coords must contain x, y, z, w.' end
    for _, field in ipairs({'x', 'y', 'z', 'w'}) do
        if not isFiniteNumber(data.coords[field]) then return false, 'Invalid shop coordinates.' end
    end
    if data.money ~= nil and data.money ~= 'cash' and data.money ~= 'bank' and data.money ~= 'gold' and data.money ~= 'bloodmoney' then
        return false, 'Invalid currency.'
    end
    if data.npc ~= nil and type(data.npc) ~= 'boolean' then return false, 'npc must be a boolean.' end
    if data.npc == true and type(data.npcmodel) ~= 'string' then return false, 'npcmodel is required when npc is true.' end
    if data.blip ~= nil then
        if type(data.blip) ~= 'table' or type(data.blip.show) ~= 'boolean' then return false, 'Invalid blip settings.' end
        if data.blip.show and (type(data.blip.sprite) ~= 'string' or not isFiniteNumber(data.blip.scale) or data.blip.scale <= 0 or type(data.blip.label) ~= 'string') then
            return false, 'Visible blips require sprite, positive scale, and label.'
        end
    end
    if data.dynamicPricing ~= nil then
        if type(data.dynamicPricing) ~= 'table' then return false, 'dynamicPricing must be a table.' end
        if data.dynamicPricing.enabled ~= nil and type(data.dynamicPricing.enabled) ~= 'boolean' then
            return false, 'dynamicPricing.enabled must be a boolean.'
        end
        for _, field in ipairs({'increasePerUnit', 'decreasePerUnit', 'minMultiplier', 'maxMultiplier'}) do
            local value = data.dynamicPricing[field]
            if value ~= nil and (not isFiniteNumber(value) or value < 0) then
                return false, 'Dynamic pricing rates and multipliers must be nonnegative finite numbers.'
            end
        end
        local minMultiplier = data.dynamicPricing.minMultiplier or Config.DynamicPricing.minMultiplier
        local maxMultiplier = data.dynamicPricing.maxMultiplier or Config.DynamicPricing.maxMultiplier
        if minMultiplier <= 0 or maxMultiplier < minMultiplier then
            return false, 'Dynamic pricing multipliers require a positive minimum and maximum at least equal to it.'
        end
    end
    if data.Hours ~= nil then
        if type(data.Hours) ~= 'table' then return false, 'Hours must be a table.' end
        if data.Hours.alwaysOpen ~= nil and type(data.Hours.alwaysOpen) ~= 'boolean' then
            return false, 'Hours.alwaysOpen must be a boolean.'
        end
        if not data.Hours.alwaysOpen then
            for _, field in ipairs({'open', 'close'}) do
                local hour = data.Hours[field]
                if not isFiniteNumber(hour) or hour % 1 ~= 0 or hour < 0 or hour > 23 then
                    return false, 'Hours.open and Hours.close must be whole hours from 0 to 23.'
                end
            end
        end
    end
    if data.Doors ~= nil then
        if type(data.Doors) ~= 'table' then return false, 'Doors must be a list of door IDs.' end
        local count = 0
        for key, doorId in pairs(data.Doors) do
            if not isFiniteNumber(key) or key % 1 ~= 0 or key < 1 or not isFiniteNumber(doorId) or doorId % 1 ~= 0 then
                return false, 'Doors must be a list of whole-number door IDs.'
            end
            count = count + 1
        end
        for index = 1, count do
            if data.Doors[index] == nil then return false, 'Doors must be a sequential list of door IDs.' end
        end
    end
    if data.restockTime ~= nil and (not isFiniteNumber(data.restockTime) or data.restockTime < 0) then
        return false, 'restockTime must be zero or positive minutes.'
    end

    local shop = copyShopData(data)
    shop.custom = true
    shop.owner = owner
    shop.revision = 1
    shop.processing = false
    shop.itemGroups = {}
    shop.items = {}
    shop.npc = data.npc == true
    local categoryIds = { buy = {}, sell = {} }
    local directionalItems = { buy = {}, sell = {} }
    for _, direction in ipairs({'buy', 'sell'}) do
        if type(shop[direction]) ~= 'table' then return false, 'buy and sell must be lists (empty lists are allowed).' end
        for _, reference in ipairs(shop[direction]) do
            if type(reference) ~= 'table' or type(reference[1]) ~= 'string' or not isFiniteNumber(reference[2]) then
                return false, 'Custom group entries must be {groupName, adjustment} with a finite numeric adjustment.'
            end
            local groupName = reference[1]
            local group = itemGroups[groupName]
            if type(group) ~= 'table' or type(group.id) ~= 'string' or group.id == '' or type(group.label) ~= 'string' or type(group.icon) ~= 'string' or type(group.items) ~= 'table' then
                return false, 'Invalid item group: ' .. groupName
            end
            if categoryIds[direction][group.id] then return false, 'Duplicate category ID in ' .. direction end
            categoryIds[direction][group.id] = true
            if not shop.itemGroups[groupName] then
                local copied = copyShopData(group)
                shop.itemGroups[groupName] = copied
                for _, item in ipairs(copied.items) do
                    if type(item) ~= 'table' or type(item.name) ~= 'string' or not RSGCore.Shared.Items[item.name] or shop.items[item.name] then
                        return false, 'Invalid or duplicate custom item.'
                    end
                    for _, field in ipairs({'buyPrice', 'sellPrice'}) do
                        if item[field] ~= nil and (not isFiniteNumber(item[field]) or item[field] < 0.01) then return false, 'Prices must be finite numbers of at least 0.01.' end
                    end
                    if item.buyPrice == nil and item.sellPrice == nil then return false, 'Item needs a buy or sell price.' end
                    if item.amount ~= nil then
                        if not isFiniteNumber(item.amount) or item.amount < 0 or item.amount % 1 ~= 0 or not isFiniteNumber(item.maxStock) or item.maxStock < 0 or item.maxStock % 1 ~= 0 then
                            return false, 'Finite items require nonnegative whole amount and maxStock.'
                        end
                        item.targetStock = item.amount
                    end
                    if item.restock ~= nil and (not isFiniteNumber(item.restock) or item.restock < 0 or item.restock % 1 ~= 0) then return false, 'restock must be a nonnegative whole quantity.' end
                    shop.items[item.name] = item
                end
            end
            for _, item in ipairs(shop.itemGroups[groupName].items) do
                if item[direction .. 'Price'] ~= nil then
                    if directionalItems[direction][item.name] then return false, 'Duplicate item in ' .. direction end
                    directionalItems[direction][item.name] = true
                end
            end
        end
    end
    if existing then
        for name, item in pairs(shop.items) do
            local current = existing.items[name]
            if not current then return false, 'Re-registration cannot change the item list.' end
            if (current.amount == nil) ~= (item.amount == nil) then
                return false, 'Re-registration cannot change finite stock mode.'
            end
        end
        for name in pairs(existing.items) do
            if not shop.items[name] then return false, 'Re-registration cannot change the item list.' end
        end
        local changedItems = {}
        for name, item in pairs(shop.items) do
            local current = existing.items[name]
            if current.amount ~= item.amount then changedItems[name] = { amount = item.amount } end
            current.buyPrice = item.buyPrice
            current.sellPrice = item.sellPrice
            current.amount = item.amount
        end
        existing.revision = existing.revision + 1
        TriggerClientEvent('rsg-stores:client:registerCustomShop', -1, customShopPayload(existing))
        if next(changedItems) then
            TriggerEvent('rsg-stores:server:CustomShopStockChanged', existing.id, copyShopData(changedItems), 'update')
        end
        return true
    end
    if shop.restockTime and shop.restockTime > 0 then shop.nextRestock = os.time() + shop.restockTime * 60 end
    shopsById[shop.id] = shop
    TriggerClientEvent('rsg-stores:client:registerCustomShop', -1, customShopPayload(shop))
    return true
end)

exports('UpdateCustomShopItems', function(shopId, updates)
    local shop = shopsById[shopId]
    if not shop or not shop.custom or shop.owner ~= GetInvokingResource() then return false, 'Shop is not owned by this resource.' end
    if shop.processing then return false, 'Shop is processing a transaction; retry the update.' end
    if type(updates) ~= 'table' then return false, 'Updates must be keyed by item name.' end
    for name, fields in pairs(updates) do
        local item = shop.items[name]
        if not item or type(fields) ~= 'table' then return false, 'Unknown item or invalid update.' end
        for field, value in pairs(fields) do
            if field == 'amount' then
                if item.amount == nil or not isFiniteNumber(value) or value < 0 or value % 1 ~= 0 then return false, 'Invalid finite stock update.' end
            elseif field == 'buyPrice' or field == 'sellPrice' then
                if value ~= false and (not isFiniteNumber(value) or value < 0.01) then return false, 'Prices must be false or finite numbers of at least 0.01.' end
            else
                return false, 'Only amount, buyPrice, and sellPrice may be updated.'
            end
        end
    end
    local changedItems = {}
    local changed = false
    for name, fields in pairs(updates) do
        for field, value in pairs(fields) do
            if value == false then value = nil end
            if shop.items[name][field] ~= value then
                shop.items[name][field] = value
                changed = true
                if field == 'amount' then changedItems[name] = { amount = value } end
            end
        end
    end
    if changed then publishCustomShop(shop, changedItems, 'update') end
    return true
end)

exports('GetCustomShopItems', function(shopId)
    local shop = shopsById[shopId]
    if not shop or not shop.custom or shop.owner ~= GetInvokingResource() then return nil, 'Shop is not owned by this resource.' end
    return copyShopData(shop.items)
end)

RSGCore.Functions.CreateCallback('rsg-stores:server:getCustomShops', function(_, cb)
    local shops = {}
    for _, shop in pairs(shopsById) do
        if shop.custom then
            shops[#shops + 1] = customShopPayload(shop)
        end
    end
    cb(shops)
end)

CreateThread(function()
    while true do
        Wait(1000)
        for _, shop in pairs(shopsById) do
            if shop.nextRestock and os.time() >= shop.nextRestock and not shop.processing then
                local changedItems = {}
                for name, item in pairs(shop.items) do
                    if item.amount ~= nil and item.restock and item.restock > 0 then
                        local amount
                        if item.amount > item.maxStock then
                            local overstockRatio = (item.amount - item.maxStock) / item.restock
                            for _, tier in ipairs(Config.OverstockReduction) do
                                if overstockRatio <= tier.maxRatio then
                                    local reduction = math.floor(item.restock * tier.multiplier + 0.5)
                                    amount = math.max(item.maxStock, item.amount - reduction)
                                    break
                                end
                            end
                        elseif Config.TargetStock and item.amount >= item.targetStock then
                            if math.random(2) == 1 then
                                amount = math.min(item.maxStock, item.amount + item.restock)
                            else
                                amount = math.max(0, item.amount - item.restock)
                            end
                        else
                            amount = math.min(item.maxStock, item.amount + item.restock)
                        end
                        if amount ~= item.amount then
                            item.amount = amount
                            changedItems[name] = { amount = amount }
                        end
                    end
                end
                shop.nextRestock = os.time() + shop.restockTime * 60
                if next(changedItems) then publishCustomShop(shop, changedItems, 'restock') end
            end
        end
    end
end)

-- Flattens a shop's buy groups into name -> price, so the client's
-- reported prices are never trusted.
local function buildPriceLookup(shop)
    local lookup = {}
    for _, group in ipairs(shop.buy) do
        local groupName = group[1]
        local regionalAdjustment = group[2]
        for _, entry in ipairs(shop.itemGroups[groupName].items) do
            if entry.buyPrice ~= nil then
                lookup[entry.name] = math.max(0.01, entry.buyPrice + regionalAdjustment)
            end
        end
    end
    return lookup
end

-- Same as above but for the items a shop is willing to buy back.
local function buildSellPriceLookup(shop)
    local lookup = {}
    if not shop.sell then return lookup end
    for _, group in ipairs(shop.sell) do
        local groupName = group[1]
        local regionalAdjustment = group[2]
        for _, entry in ipairs(shop.itemGroups[groupName].items) do
            if entry.sellPrice ~= nil then
                lookup[entry.name] = math.max(0.01, entry.sellPrice + regionalAdjustment)
            end
        end
    end
    return lookup
end

local function validateShopStock(shop, lines, direction, revision)
    if revision ~= shop.revision then return false, locale('error.shop_changed') end
    for _, line in ipairs(lines) do
        local item = shop.items[line.name]
        if direction == 'buy' and item.amount ~= nil then
            if line.amount > item.amount then return false, locale('error.shop_stock') end
        end
    end
    return true
end
-- Validates and normalizes a basket sent up by the NUI against a given
-- price lookup. Each line must be {name, amount}, amount must be a whole,
-- finite number within range, the item must exist in the lookup and in
-- RSGCore's shared items, and no item may repeat. Returns the cleaned
-- lines ({name, amount, basePrice, label}), or nil plus a player-facing
-- error message.
local function validateBasket(basket, priceLookup, maxUniqueItems, maxQuantity)
    if type(basket) ~= 'table' or #basket == 0 or #basket > maxUniqueItems then
        return nil, locale('error.basket_invalid')
    end

    local seen = {}
    local lines = {}

    for _, line in ipairs(basket) do
        if type(line) ~= 'table' or type(line.name) ~= 'string' or not isFiniteNumber(line.amount) or line.amount % 1 ~= 0 then
            return nil, locale('error.basket_bad_data')
        end

        local amount = math.floor(line.amount)
        local basePrice = priceLookup[line.name]
        local itemData = RSGCore.Shared.Items[line.name]

        if seen[line.name] or not basePrice or not itemData or amount < 1 or amount > maxQuantity then
            return nil, locale('error.items_unavailable')
        end

        seen[line.name] = true
        lines[#lines + 1] = { name = line.name, amount = amount, basePrice = basePrice, label = itemData.label }
    end

    return lines
end

-- Sums how much of one item a player is carrying across every inventory slot.
local function getOwnedAmount(Player, itemName)
    local total = 0
    for _, item in pairs(Player.PlayerData.items or {}) do
        if item and item.name == itemName then
            total = total + (item.amount or 0)
        end
    end
    return total
end

local function pick(overrideValue, baseValue, default)
    if overrideValue ~= nil then return overrideValue end
    if baseValue ~= nil then return baseValue end
    return default
end

local function getDynamicConfig(shop)
    local base = Config.DynamicPricing or {}
    local override = shop.dynamicPricing or {}
    return {
        enabled = pick(override.enabled, base.enabled, false),
        increasePerUnit = pick(override.increasePerUnit, base.increasePerUnit, 0),
        decreasePerUnit = pick(override.decreasePerUnit, base.decreasePerUnit, 0),
        minMultiplier = pick(override.minMultiplier, base.minMultiplier, 0.5),
        maxMultiplier = pick(override.maxMultiplier, base.maxMultiplier, 3.0),
    }
end

local function clamp(value, min, max)
    if value < min then return min end
    if value > max then return max end
    return value
end

local function getMultiplier(shopId, itemName)
    local shopState = priceState[shopId]
    if not shopState then return 1.0 end
    return shopState[itemName] or 1.0
end

local function setMultiplier(shopId, itemName, value)
    priceState[shopId] = priceState[shopId] or {}
    priceState[shopId][itemName] = value
end

local function roundToCents(value)
    return math.floor((value * 100) + 0.5) / 100
end

-- Current per-unit price for display (grid/basket previews), rounded to
-- the nearest cent.
local function getLivePrice(shop, itemName, basePrice)
    local dyn = getDynamicConfig(shop)
    if not dyn.enabled then return basePrice end
    local price = basePrice * getMultiplier(shop.id, itemName)
    return math.max(0.01, roundToCents(price))
end

-- Walks the price up (direction 'buy') or down (direction 'sell') one unit
-- at a time so a multi-unit purchase/sale in a single order is charged
-- progressively, same as buying/selling one at a time would be. Returns the
-- (unrounded) total and the resulting multiplier -- the multiplier is only
-- actually persisted by the caller once the whole transaction succeeds.
local function calcProgressive(shop, itemName, basePrice, amount, direction)
    local dyn = getDynamicConfig(shop)

    if not dyn.enabled then
        return basePrice * amount, nil
    end

    local multiplier = getMultiplier(shop.id, itemName)
    local percent = direction == 'sell' and -dyn.decreasePerUnit or dyn.increasePerUnit
    local rate = 1 + (percent / 100)
    local total = 0

    for _ = 1, amount do
        total = total + (basePrice * multiplier)
        multiplier = clamp(multiplier * rate, dyn.minMultiplier, dyn.maxMultiplier)
    end

    return total, multiplier
end

RegisterNetEvent('rsg-stores:server:checkout', function(shopId, basket, revision)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local shop = shopsById[shopId]
    if not shop then
        notifyError(src, locale('title.store_unavailable'), locale('error.store_unavailable_buy'))
        TriggerClientEvent('rsg-stores:client:checkoutResult', src, false)
        return
    end

    if not isPlayerNearShop(src, shop) then
        notifyError(src, locale('title.too_far'), locale('error.too_far'))
        TriggerClientEvent('rsg-stores:client:checkoutResult', src, false)
        return
    end

    if not tryLockPlayer(src) then
        notifyError(src, locale('title.purchase_failed'), locale('error.purchase_processing'))
        TriggerClientEvent('rsg-stores:client:checkoutResult', src, false)
        return
    end

    -- Wrapped so a stray error (bad config, framework hiccup, etc) can never
    -- leave this player permanently locked out of buying/selling.
    if shop.processing then
        notifyError(src, locale('title.purchase_failed'), locale('error.shop_busy'))
        TriggerClientEvent('rsg-stores:client:checkoutResult', src, false)
        unlockPlayer(src)
        return
    end
    shop.processing = true
    local changedItems = {}

    local ok, err = pcall(function()
        local priceLookup = buildPriceLookup(shop)
        local lines, validationError = validateBasket(basket, priceLookup, Config.MaxUniqueBasketItems, Config.MaxItemQuantity)

        if not lines then
            notifyError(src, locale('title.purchase_failed'), validationError)
            TriggerClientEvent('rsg-stores:client:checkoutResult', src, false)
            return
        end

        local stockValid, stockError = validateShopStock(shop, lines, 'buy', revision)
        if not stockValid then
            notifyError(src, locale('title.purchase_failed'), stockError)
            TriggerClientEvent('rsg-stores:client:checkoutResult', src, false)
            TriggerClientEvent('rsg-stores:client:refreshCustomShop', src, shop.id)
            return
        end

        local purchases = {}
        local totalCost = 0

        for _, line in ipairs(lines) do
            local lineCost, newMultiplier = calcProgressive(shop, line.name, line.basePrice, line.amount, 'buy')
            totalCost = totalCost + lineCost
            purchases[#purchases + 1] = { name = line.name, amount = line.amount, cost = lineCost, multiplier = newMultiplier, label = line.label }
        end

        totalCost = math.max(0.01, roundToCents(totalCost))

        local moneyType = shop.money or Config.Money
        local money = Player.PlayerData.money[moneyType] or 0

        if money < totalCost then
            notifyError(src, locale('title.purchase_failed'), locale('error.insufficient_funds', moneyType))
            TriggerClientEvent('rsg-stores:client:checkoutResult', src, false)
            return
        end

        if not Player.Functions.RemoveMoney(moneyType, totalCost, 'rsg-stores-purchase') then
            notifyError(src, locale('title.purchase_failed'), locale('error.payment_failed'))
            TriggerClientEvent('rsg-stores:client:checkoutResult', src, false)
            return
        end

        local added = {}
        local refund = 0

        for _, purchase in ipairs(purchases) do
            if Player.Functions.AddItem(purchase.name, purchase.amount) then
                added[#added + 1] = purchase
                if shop.items[purchase.name].amount ~= nil then
                    shop.items[purchase.name].amount = shop.items[purchase.name].amount - purchase.amount
                    changedItems[purchase.name] = { amount = shop.items[purchase.name].amount }
                end
                TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[purchase.name], 'add', purchase.amount)
                -- Only advance this item's dynamic price if the player
                -- actually received it.
                if purchase.multiplier then
                    setMultiplier(shop.id, purchase.name, purchase.multiplier)
                end
            else
                -- Item didn't fit (inventory full/overweight) -- refund
                -- the exact amount charged for it rather than charging for
                -- nothing.
                refund = refund + purchase.cost
            end
        end

        refund = roundToCents(refund)

        if refund > 0 then
            Player.Functions.AddMoney(moneyType, refund, 'rsg-stores-purchase-refund')
        end

        if #added == 0 then
            notifyError(src, locale('title.purchase_failed'), locale('error.inventory_full'))
            TriggerClientEvent('rsg-stores:client:checkoutResult', src, false)
            return
        end

        local description = locale('success.purchase', #added, totalCost - refund)
        if refund > 0 then
            description = description .. locale('success.purchase_refund_suffix', #purchases - #added)
        end

        TriggerClientEvent('ox_lib:notify', src, {
            title = shop.label,
            description = description,
            type = 'success',
        })
        TriggerClientEvent('rsg-stores:client:checkoutResult', src, true)

        SendStoreWebhook({
            title = locale('webhook.purchase_title', shop.label),
            color = (Config.Webhooks and Config.Webhooks.purchaseColor) or 3066993,
            fields = {
                { name = locale('webhook.field_player'), value = describePlayer(Player), inline = true },
                { name = locale('webhook.field_total_paid'), value = ('$%.2f'):format(totalCost - refund), inline = true },
                { name = locale('webhook.field_items'), value = formatItemLines(added) },
            },
            footer = { text = locale('webhook.footer') },
            timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
        })
    end)

    if not ok then
        print(('[rsg-stores] ERROR processing checkout for %s at shop "%s": %s'):format(src, tostring(shopId), tostring(err)))
        notifyError(src, locale('title.purchase_failed'), locale('error.checkout_error'))
        TriggerClientEvent('rsg-stores:client:checkoutResult', src, false)
    end

    shop.processing = false
    unlockPlayer(src)
    if next(changedItems) then publishCustomShop(shop, changedItems, 'buy') end
end)

RSGCore.Functions.CreateCallback('rsg-stores:server:getShopState', function(source, cb, shopId)
    local Player = RSGCore.Functions.GetPlayer(source)
    local shop = shopsById[shopId]

    if not Player or not shop or not isPlayerNearShop(source, shop) then
        cb({ buyPrices = {}, sellPrices = {}, owned = {} })
        return
    end

    local buyPrices = {}
    for itemName, basePrice in pairs(buildPriceLookup(shop)) do
        buyPrices[itemName] = getLivePrice(shop, itemName, basePrice)
    end

    local sellPrices = {}
    local owned = {}
    if shop.sell then
        for itemName, basePrice in pairs(buildSellPriceLookup(shop)) do
            sellPrices[itemName] = getLivePrice(shop, itemName, basePrice)
            owned[itemName] = getOwnedAmount(Player, itemName)
        end
    end
    local stock = {}
    for name, item in pairs(shop.items) do
        if item.amount ~= nil then
            stock[name] = item.amount
        end
    end
    cb({ buyPrices = buyPrices, sellPrices = sellPrices, owned = owned,
        stock = stock, revision = shop.revision,
        itemGroups = shop.itemGroups })
end)

RegisterNetEvent('rsg-stores:server:sellCheckout', function(shopId, basket, revision)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local shop = shopsById[shopId]
    if not shop or not shop.sell then
        notifyError(src, locale('title.store_unavailable'), locale('error.store_unavailable_sell'))
        TriggerClientEvent('rsg-stores:client:sellResult', src, false)
        return
    end

    if not isPlayerNearShop(src, shop) then
        notifyError(src, locale('title.too_far'), locale('error.too_far'))
        TriggerClientEvent('rsg-stores:client:sellResult', src, false)
        return
    end

    if not tryLockPlayer(src) then
        notifyError(src, locale('title.sale_failed'), locale('error.sale_processing'))
        TriggerClientEvent('rsg-stores:client:sellResult', src, false)
        return
    end

    if shop.processing then
        notifyError(src, locale('title.sale_failed'), locale('error.shop_busy'))
        TriggerClientEvent('rsg-stores:client:sellResult', src, false)
        unlockPlayer(src)
        return
    end
    shop.processing = true
    local changedItems = {}

    local ok, err = pcall(function()
        local priceLookup = buildSellPriceLookup(shop)
        local lines, validationError = validateBasket(basket, priceLookup, Config.MaxUniqueSellItems, Config.MaxSellQuantity)

        if not lines then
            notifyError(src, locale('title.sale_failed'), validationError)
            TriggerClientEvent('rsg-stores:client:sellResult', src, false)
            return
        end

        local stockValid, stockError = validateShopStock(shop, lines, 'sell', revision)
        if not stockValid then
            notifyError(src, locale('title.sale_failed'), stockError)
            TriggerClientEvent('rsg-stores:client:sellResult', src, false)
            TriggerClientEvent('rsg-stores:client:refreshCustomShop', src, shop.id)
            return
        end

        for _, line in ipairs(lines) do
            if getOwnedAmount(Player, line.name) < line.amount then
                notifyError(src, locale('title.sale_failed'), locale('error.not_enough_to_sell', line.amount, line.label or line.name))
                TriggerClientEvent('rsg-stores:client:sellResult', src, false)
                return
            end
        end

        local removed = {}
        for _, line in ipairs(lines) do
            if Player.Functions.RemoveItem(line.name, line.amount) then
                removed[#removed + 1] = line
                TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[line.name], 'remove', line.amount)
            else
                for _, done in ipairs(removed) do
                    Player.Functions.AddItem(done.name, done.amount)
                end
                notifyError(src, locale('title.sale_failed'), locale('error.remove_item_failed'))
                TriggerClientEvent('rsg-stores:client:sellResult', src, false)
                return
            end
        end

        local totalPaid = 0
        local pendingMultipliers = {}

        for _, line in ipairs(lines) do
            local lineTotal, newMultiplier = calcProgressive(shop, line.name, line.basePrice, line.amount, 'sell')
            totalPaid = totalPaid + lineTotal
            if newMultiplier then pendingMultipliers[line.name] = newMultiplier end
        end

        totalPaid = math.max(0, roundToCents(totalPaid))

        local moneyType = shop.money or Config.Money
        if not Player.Functions.AddMoney(moneyType, totalPaid, 'rsg-stores-sale') then
            for _, line in ipairs(removed) do
                Player.Functions.AddItem(line.name, line.amount)
            end
            notifyError(src, locale('title.sale_failed'), locale('error.payment_failed'))
            TriggerClientEvent('rsg-stores:client:sellResult', src, false)
            return
        end

        for itemName, newMultiplier in pairs(pendingMultipliers) do
            setMultiplier(shop.id, itemName, newMultiplier)
        end
        for _, line in ipairs(lines) do
            if shop.items[line.name].amount ~= nil then
                shop.items[line.name].amount = shop.items[line.name].amount + line.amount
                changedItems[line.name] = { amount = shop.items[line.name].amount }
            end
        end

        TriggerClientEvent('ox_lib:notify', src, {
            title = shop.label,
            description = locale('success.sale', #lines, totalPaid),
            type = 'success',
        })
        TriggerClientEvent('rsg-stores:client:sellResult', src, true)

        SendStoreWebhook({
            title = locale('webhook.sale_title', shop.label),
            color = (Config.Webhooks and Config.Webhooks.saleColor) or 15105570,
            fields = {
                { name = locale('webhook.field_player'), value = describePlayer(Player), inline = true },
                { name = locale('webhook.field_total_received'), value = ('$%.2f'):format(totalPaid), inline = true },
                { name = locale('webhook.field_items'), value = formatItemLines(lines) },
            },
            footer = { text = locale('webhook.footer') },
            timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
        })
    end)

    if not ok then
        print(('[rsg-stores] ERROR processing sale for %s at shop "%s": %s'):format(src, tostring(shopId), tostring(err)))
        notifyError(src, locale('title.sale_failed'), locale('error.sale_error'))
        TriggerClientEvent('rsg-stores:client:sellResult', src, false)
    end

    shop.processing = false
    unlockPlayer(src)
    if next(changedItems) then publishCustomShop(shop, changedItems, 'sell') end
end)
