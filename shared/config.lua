Config = {}

Config.Hours = {
    open = 8,
    close = 20,
    enable = true,
    unlockDuration = 30 * 1000,
}

-- Account type charged on checkout. Must be one of the accounts on
-- Player.PlayerData.money ('cash', 'bank', 'bloodmoney', 'gold').
-- Can be overridden per-shop in configShops.lua with shop.money.
Config.Money = 'cash'

-- Item icons are loaded straight from rsg-inventory's image folder, e.g.
-- nui://rsg-inventory/html/images/bread.png -- change this if your image
-- folder lives in a different resource.
Config.Img = 'rsg-inventory/html/images/'

-- Maximum number of *unique* items a player can hold in their basket at
-- once. Quantity per item is unlimited (still capped per-line below).
Config.MaxUniqueBasketItems = 10

-- Highest quantity of a single item allowed in one basket line.
Config.MaxItemQuantity = 99

-- Same two caps as above, but for the Sell tab's basket. A shop only shows
-- a Sell tab at all if it has a `sell` list defined in configShops.lua.
Config.MaxUniqueSellItems = 10
Config.MaxSellQuantity = 99

-- Max distance (in game units) a player may be from a shop's coords when
-- the server actually processes getShopState/checkout/sellCheckout. Keeps
-- this in sync with the ox_target interaction distance below so players
-- can't open a shop, walk away, and keep buying/selling remotely.
Config.MaxInteractDistance = 2.5

-- Global toggle for limited-stock items in configured and custom shops.
-- When enabled, each item's starting amount is saved as its target stock.
-- Purchases, sales, and exported stock updates do not change that target.
-- On each scheduled restock tick:
--   Below target: add the item's restock quantity, up to maxStock.
--   At/above target through maxStock: 50/50 chance to add or remove restock.
--   Above maxStock: only reduce stock, using OverstockReduction tiers below.
-- Random increases stop at maxStock; decreases stop at zero and may fall
-- below target, causing the next tick to increase stock. At maxStock, a
-- randomly selected increase leaves stock unchanged.
-- Example: amount = 10, maxStock = 50, restock = 5.
-- Stock 5 becomes 10; stock 20 becomes 15 or 25; stock 50 becomes 45 or 50.
-- When disabled, stock at/below maxStock always increases toward maxStock.
-- Above-max reductions apply in either mode. Omitted/zero restock skips
-- the item; omitted/zero shop restockTime disables scheduled restocking.
Config.TargetStock = true

-- Compare excess stock / restock against these tiers, in ascending order.
-- Reduction is restock * multiplier, rounded to whole items, stopping at maxStock.
Config.OverstockReduction = {
    { maxRatio = 2, multiplier = 1.5 },
    { maxRatio = 4, multiplier = 2 },
    { maxRatio = math.huge, multiplier = 3 }, -- all higher ratios
}

-- ---------------------------------------------------------------------------
-- Dynamic pricing: every unit a player buys nudges that item's price UP at
-- that shop, and every unit sold back nudges it back DOWN -- the same
-- price moves both ways, so buying and selling the same item pull against
-- each other. This is tracked as an in-memory multiplier per shop+item
-- (starting at 1.0x) and is NOT saved to a database -- it resets to 1.0x
-- whenever the resource or server restarts.
--
-- All percent fields are percentage POINTS, not fractions:
-- 0.02 = 0.02%, 5 = 5%.
--
-- This is a global default. Override any of it per-shop with a
-- `dynamicPricing = { ... }` table on that shop (see Config.Shops in configShops.lua) --
-- any field left out there falls back to the value here.
-- ---------------------------------------------------------------------------
Config.DynamicPricing = {
    enabled = false,        -- off unless a shop turns it on
    increasePerUnit = 0.02, -- % price increase per unit bought
    decreasePerUnit = 0.02, -- % price decrease per unit sold back
    minMultiplier = 0.5,    -- price can never fall below 50% of its configured base price
    maxMultiplier = 3.0,    -- price can never exceed 300% of its configured base price
}

-- ---------------------------------------------------------------------------
-- Discord webhook logging. Every completed purchase and sale is posted to
-- this webhook URL as an embed (player name/citizenid, items, and total).
-- Leave `url` empty to disable logging entirely -- nothing is sent and no
-- HTTP requests are made. Messages are queued and sent one at a time so a
-- burst of transactions can never trip Discord's per-webhook rate limit.
-- ---------------------------------------------------------------------------
Config.Webhooks = {
    url = '', -- e.g. 'https://discord.com/api/webhooks/XXXXXXXX/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
    botName = 'RSG Stores',
    botAvatar = '', -- optional image URL used as the webhook's avatar
    purchaseColor = 3066993,  -- green
    saleColor = 15105570,     -- orange
}
