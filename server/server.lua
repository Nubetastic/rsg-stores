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

-- Flattens a shop's buy groups into name -> price, so the client's
-- reported prices are never trusted.
local function buildPriceLookup(shop)
    local lookup = {}
    for _, group in ipairs(shop.buy) do
        local groupName = group[1]
        local regionalAdjustment = group[2]
        for _, entry in ipairs(Config.ItemGroups[groupName].items) do
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
        for _, entry in ipairs(Config.ItemGroups[groupName].items) do
            if entry.sellPrice ~= nil then
                lookup[entry.name] = math.max(0.01, entry.sellPrice + regionalAdjustment)
            end
        end
    end
    return lookup
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
        if type(line) ~= 'table' or type(line.name) ~= 'string' or not isFiniteNumber(line.amount) then
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

RegisterNetEvent('rsg-stores:server:checkout', function(shopId, basket)
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
    local ok, err = pcall(function()
        local priceLookup = buildPriceLookup(shop)
        local lines, validationError = validateBasket(basket, priceLookup, Config.MaxUniqueBasketItems, Config.MaxItemQuantity)

        if not lines then
            notifyError(src, locale('title.purchase_failed'), validationError)
            TriggerClientEvent('rsg-stores:client:checkoutResult', src, false)
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

    unlockPlayer(src)
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
    cb({ buyPrices = buyPrices, sellPrices = sellPrices, owned = owned })
end)

RegisterNetEvent('rsg-stores:server:sellCheckout', function(shopId, basket)
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

    local ok, err = pcall(function()
        local priceLookup = buildSellPriceLookup(shop)
        local lines, validationError = validateBasket(basket, priceLookup, Config.MaxUniqueSellItems, Config.MaxSellQuantity)

        if not lines then
            notifyError(src, locale('title.sale_failed'), validationError)
            TriggerClientEvent('rsg-stores:client:sellResult', src, false)
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

        for itemName, newMultiplier in pairs(pendingMultipliers) do
            setMultiplier(shop.id, itemName, newMultiplier)
        end

        local moneyType = shop.money or Config.Money
        Player.Functions.AddMoney(moneyType, totalPaid, 'rsg-stores-sale')

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

    unlockPlayer(src)
end)
