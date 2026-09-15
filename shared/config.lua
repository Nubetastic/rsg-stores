Config = {}

-- Account type charged on checkout. Must be one of the accounts on
-- Player.PlayerData.money ('cash', 'bank', 'bloodmoney', 'gold').
-- Can be overridden per-shop below with shop.money.
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
-- a Sell tab at all if it has a `sell` block defined below.
Config.MaxUniqueSellItems = 10
Config.MaxSellQuantity = 99

-- Max distance (in game units) a player may be from a shop's coords when
-- the server actually processes getShopState/checkout/sellCheckout. Keeps
-- this in sync with the ox_target interaction distance below so players
-- can't open a shop, walk away, and keep buying/selling remotely.
Config.MaxInteractDistance = 3.0

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
-- `dynamicPricing = { ... }` table on that shop (see Config.Shops below) --
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

-- ---------------------------------------------------------------------------
-- IMPORTANT: every item `name` below must exactly match a key in your
-- rsg-core/shared/items.lua on this server. The label, weight and icon
-- shown in the shop are pulled live from RSGCore.Shared.Items[name] -- only
-- the price and category grouping live here. Rename/add/remove freely.
--
-- Every shop below MUST set `npcmodel` -- shops are interacted with via a
-- ped only; there is no box-zone fallback.
-- ---------------------------------------------------------------------------

Config.Shops = {
    ---------------------------------
    -- Valentine General Store
    ---------------------------------
    {
        id = 'val_general_store',
        label = 'Valentine General Store',
        coords = vector4(-324.14, 803.51, 116.88, 280.98),
        npcmodel = 'u_m_m_valgenstoreowner_01',
        blip = {
            show = true,
            sprite = 'blip_shop_store',
            scale = 0.2,
            label = 'Valentine General Store',
        },
        money = 'cash',
        dynamicPricing = {
            enabled = true,
        },
        categories = {
            {
                id = 'food',
                label = 'Food & Drink',
                icon = 'fa-solid fa-drumstick-bite',
                items = {
                    { name = 'bread', price = 0.50 },
                    { name = 'water', price = 0.50 },
                },
            },
            {
                id = 'medicine',
                label = 'Medicine',
                icon = 'fa-solid fa-briefcase-medical',
                items = {
                    { name = 'bandage',    price = 0.25 },
                },
            },
            {
                id = 'tools',
                label = 'Tools',
                icon = 'fa-solid fa-toolbox',
                items = {
                    { name = 'canteen0', price = 5 },
                    { name = 'axe',      price = 5 },
                    { name = 'pickaxe',  price = 5 },
                    { name = 'shovel',   price = 5 },
                },
            },
        },
        ---------------------------------
        -- sell items
        ---------------------------------
        sell = {
            categories = {
                {
                    id = 'sell_herbs',
                    label = 'Herbs & Plants',
                    icon = 'fa-solid fa-leaf',
                    items = {
                        { name = 'herb_agarita',               price = 0.10 },
                        { name = 'herb_alaskan_ginseng',       price = 0.10 },
                        { name = 'herb_american_ginseng',      price = 0.10 },
                        { name = 'herb_bay_boletus',           price = 0.10 },
                        { name = 'herb_bitterweed',            price = 0.10 },
                        { name = 'herb_black_berry',           price = 0.10 },
                        { name = 'herb_black_current',         price = 0.10 },
                        { name = 'herb_bloodflower',           price = 0.10 },
                        { name = 'herb_burdock_root',          price = 0.10 },
                        { name = 'herb_cardinal_flower',       price = 0.10 },
                        { name = 'herb_chanterelles',          price = 0.10 },
                        { name = 'herb_choc_daisy',            price = 0.10 },
                        { name = 'herb_common_bullrush',       price = 0.10 },
                        { name = 'herb_creek_plum',            price = 0.10 },
                        { name = 'herb_creeping_thyme',        price = 0.10 },
                        { name = 'herb_crows_garlic',          price = 0.10 },
                        { name = 'herb_desert_sage',           price = 0.10 },
                        { name = 'herb_english_mace',          price = 0.10 },
                        { name = 'herb_evergreen_huckleberry', price = 0.10 },
                        { name = 'herb_golden_currant',        price = 0.10 },
                        { name = 'herb_harrietum_officinalis', price = 0.10 },
                        { name = 'herb_hummingbird_sage',      price = 0.10 },
                        { name = 'herb_indian_tobacco',        price = 0.10 },
                        { name = 'herb_lady_slipper',          price = 0.10 },
                        { name = 'herb_milkweed',              price = 0.10 },
                        { name = 'herb_oleander_sage',         price = 0.10 },
                        { name = 'herb_oregano',               price = 0.10 },
                        { name = 'herb_parasol_mushroom',      price = 0.10 },
                        { name = 'herb_prairie_poppy',         price = 0.10 },
                        { name = 'herb_rams_head',             price = 0.10 },
                        { name = 'herb_red_raspberry',         price = 0.10 },
                        { name = 'herb_red_sage',              price = 0.10 },
                        { name = 'herb_saltbush',              price = 0.10 },
                        { name = 'herb_texas_blue_bonnet',     price = 0.10 },
                        { name = 'herb_violet_snowdrop',       price = 0.10 },
                        { name = 'herb_wild_carrot',           price = 0.10 },
                        { name = 'herb_wild_feverfew',         price = 0.10 },
                        { name = 'herb_wild_mint',             price = 0.10 },
                        { name = 'herb_wild_rhubarb',          price = 0.10 },
                        { name = 'herb_wintergreen_berry',     price = 0.10 },
                        { name = 'herb_wisteria',              price = 0.10 },
                        { name = 'herb_yarrow',                price = 0.10 },
                    },
                },
                {
                    id = 'sell_misc',
                    label = 'General Goods',
                    icon = 'fa-solid fa-leaf',
                    items = {
                        { name = 'bread', price = 0.10 },
                        { name = 'water',   price = 0.10 },
                    },
                },
            },
        },
    },
    ---------------------------------
    -- Rhodes General Store
    ---------------------------------
    {
        id = 'rho_general_store',
        label = 'Rhodes General Store',
        coords = vector4(1329.80, -1294.37, 76.02, 60.72),
        npcmodel = 'u_m_m_rhdgenstoreowner_01',
        blip = {
            show = true,
            sprite = 'blip_shop_store',
            scale = 0.2,
            label = 'Rhodes General Store',
        },
        money = 'cash',
        dynamicPricing = {
            enabled = true,
        },
        categories = {
            {
                id = 'food',
                label = 'Food & Drink',
                icon = 'fa-solid fa-drumstick-bite',
                items = {
                    { name = 'bread', price = 0.50 },
                    { name = 'water', price = 0.50 },
                },
            },
            {
                id = 'medicine',
                label = 'Medicine',
                icon = 'fa-solid fa-briefcase-medical',
                items = {
                    { name = 'bandage',    price = 0.25 },
                },
            },
            {
                id = 'tools',
                label = 'Tools',
                icon = 'fa-solid fa-toolbox',
                items = {
                    { name = 'canteen0', price = 5 },
                    { name = 'axe',      price = 5 },
                    { name = 'pickaxe',  price = 5 },
                    { name = 'shovel',   price = 5 },
                },
            },
        },
        ---------------------------------
        -- sell items
        ---------------------------------
        sell = {
            categories = {
                {
                    id = 'sell_herbs',
                    label = 'Herbs & Plants',
                    icon = 'fa-solid fa-leaf',
                    items = {
                        { name = 'herb_agarita',               price = 0.10 },
                        { name = 'herb_alaskan_ginseng',       price = 0.10 },
                        { name = 'herb_american_ginseng',      price = 0.10 },
                        { name = 'herb_bay_boletus',           price = 0.10 },
                        { name = 'herb_bitterweed',            price = 0.10 },
                        { name = 'herb_black_berry',           price = 0.10 },
                        { name = 'herb_black_current',         price = 0.10 },
                        { name = 'herb_bloodflower',           price = 0.10 },
                        { name = 'herb_burdock_root',          price = 0.10 },
                        { name = 'herb_cardinal_flower',       price = 0.10 },
                        { name = 'herb_chanterelles',          price = 0.10 },
                        { name = 'herb_choc_daisy',            price = 0.10 },
                        { name = 'herb_common_bullrush',       price = 0.10 },
                        { name = 'herb_creek_plum',            price = 0.10 },
                        { name = 'herb_creeping_thyme',        price = 0.10 },
                        { name = 'herb_crows_garlic',          price = 0.10 },
                        { name = 'herb_desert_sage',           price = 0.10 },
                        { name = 'herb_english_mace',          price = 0.10 },
                        { name = 'herb_evergreen_huckleberry', price = 0.10 },
                        { name = 'herb_golden_currant',        price = 0.10 },
                        { name = 'herb_harrietum_officinalis', price = 0.10 },
                        { name = 'herb_hummingbird_sage',      price = 0.10 },
                        { name = 'herb_indian_tobacco',        price = 0.10 },
                        { name = 'herb_lady_slipper',          price = 0.10 },
                        { name = 'herb_milkweed',              price = 0.10 },
                        { name = 'herb_oleander_sage',         price = 0.10 },
                        { name = 'herb_oregano',               price = 0.10 },
                        { name = 'herb_parasol_mushroom',      price = 0.10 },
                        { name = 'herb_prairie_poppy',         price = 0.10 },
                        { name = 'herb_rams_head',             price = 0.10 },
                        { name = 'herb_red_raspberry',         price = 0.10 },
                        { name = 'herb_red_sage',              price = 0.10 },
                        { name = 'herb_saltbush',              price = 0.10 },
                        { name = 'herb_texas_blue_bonnet',     price = 0.10 },
                        { name = 'herb_violet_snowdrop',       price = 0.10 },
                        { name = 'herb_wild_carrot',           price = 0.10 },
                        { name = 'herb_wild_feverfew',         price = 0.10 },
                        { name = 'herb_wild_mint',             price = 0.10 },
                        { name = 'herb_wild_rhubarb',          price = 0.10 },
                        { name = 'herb_wintergreen_berry',     price = 0.10 },
                        { name = 'herb_wisteria',              price = 0.10 },
                        { name = 'herb_yarrow',                price = 0.10 },
                    },
                },
                {
                    id = 'sell_misc',
                    label = 'General Goods',
                    icon = 'fa-solid fa-leaf',
                    items = {
                        { name = 'bread', price = 0.10 },
                        { name = 'water',   price = 0.10 },
                    },
                },
            },
        },
    },
    ---------------------------------
    -- Strawberry General Store
    ---------------------------------
    {
        id = 'str_general_store',
        label = 'Strawberry General Store',
        coords = vector4(-1789.78, -388.15, 159.33, 65.43),
        npcmodel = 'u_m_m_strgenstoreowner_01',
        blip = {
            show = true,
            sprite = 'blip_shop_store',
            scale = 0.2,
            label = 'Strawberry General Store',
        },
        money = 'cash',
        dynamicPricing = {
            enabled = true,
        },
        categories = {
            {
                id = 'food',
                label = 'Food & Drink',
                icon = 'fa-solid fa-drumstick-bite',
                items = {
                    { name = 'bread', price = 0.50 },
                    { name = 'water', price = 0.50 },
                },
            },
            {
                id = 'medicine',
                label = 'Medicine',
                icon = 'fa-solid fa-briefcase-medical',
                items = {
                    { name = 'bandage',    price = 0.25 },
                },
            },
            {
                id = 'tools',
                label = 'Tools',
                icon = 'fa-solid fa-toolbox',
                items = {
                    { name = 'canteen0', price = 5 },
                    { name = 'axe',      price = 5 },
                    { name = 'pickaxe',  price = 5 },
                    { name = 'shovel',   price = 5 },
                },
            },
        },
        ---------------------------------
        -- sell items
        ---------------------------------
        sell = {
            categories = {
                {
                    id = 'sell_herbs',
                    label = 'Herbs & Plants',
                    icon = 'fa-solid fa-leaf',
                    items = {
                        { name = 'herb_agarita',               price = 0.10 },
                        { name = 'herb_alaskan_ginseng',       price = 0.10 },
                        { name = 'herb_american_ginseng',      price = 0.10 },
                        { name = 'herb_bay_boletus',           price = 0.10 },
                        { name = 'herb_bitterweed',            price = 0.10 },
                        { name = 'herb_black_berry',           price = 0.10 },
                        { name = 'herb_black_current',         price = 0.10 },
                        { name = 'herb_bloodflower',           price = 0.10 },
                        { name = 'herb_burdock_root',          price = 0.10 },
                        { name = 'herb_cardinal_flower',       price = 0.10 },
                        { name = 'herb_chanterelles',          price = 0.10 },
                        { name = 'herb_choc_daisy',            price = 0.10 },
                        { name = 'herb_common_bullrush',       price = 0.10 },
                        { name = 'herb_creek_plum',            price = 0.10 },
                        { name = 'herb_creeping_thyme',        price = 0.10 },
                        { name = 'herb_crows_garlic',          price = 0.10 },
                        { name = 'herb_desert_sage',           price = 0.10 },
                        { name = 'herb_english_mace',          price = 0.10 },
                        { name = 'herb_evergreen_huckleberry', price = 0.10 },
                        { name = 'herb_golden_currant',        price = 0.10 },
                        { name = 'herb_harrietum_officinalis', price = 0.10 },
                        { name = 'herb_hummingbird_sage',      price = 0.10 },
                        { name = 'herb_indian_tobacco',        price = 0.10 },
                        { name = 'herb_lady_slipper',          price = 0.10 },
                        { name = 'herb_milkweed',              price = 0.10 },
                        { name = 'herb_oleander_sage',         price = 0.10 },
                        { name = 'herb_oregano',               price = 0.10 },
                        { name = 'herb_parasol_mushroom',      price = 0.10 },
                        { name = 'herb_prairie_poppy',         price = 0.10 },
                        { name = 'herb_rams_head',             price = 0.10 },
                        { name = 'herb_red_raspberry',         price = 0.10 },
                        { name = 'herb_red_sage',              price = 0.10 },
                        { name = 'herb_saltbush',              price = 0.10 },
                        { name = 'herb_texas_blue_bonnet',     price = 0.10 },
                        { name = 'herb_violet_snowdrop',       price = 0.10 },
                        { name = 'herb_wild_carrot',           price = 0.10 },
                        { name = 'herb_wild_feverfew',         price = 0.10 },
                        { name = 'herb_wild_mint',             price = 0.10 },
                        { name = 'herb_wild_rhubarb',          price = 0.10 },
                        { name = 'herb_wintergreen_berry',     price = 0.10 },
                        { name = 'herb_wisteria',              price = 0.10 },
                        { name = 'herb_yarrow',                price = 0.10 },
                    },
                },
                {
                    id = 'sell_misc',
                    label = 'General Goods',
                    icon = 'fa-solid fa-leaf',
                    items = {
                        { name = 'bread', price = 0.10 },
                        { name = 'water',   price = 0.10 },
                    },
                },
            },
        },
    },
    ---------------------------------
    -- Annesburg General Store
    ---------------------------------
    {
        id = 'ann_general_store',
        label = 'Annesburg General Store',
        coords = vector4(2930.97, 1365.38, 44.20, 252.02),
        npcmodel = 'u_m_m_rhdgenstoreowner_02',
        blip = {
            show = true,
            sprite = 'blip_shop_store',
            scale = 0.2,
            label = 'Annesburg General Store',
        },
        money = 'cash',
        dynamicPricing = {
            enabled = true,
        },
        categories = {
            {
                id = 'food',
                label = 'Food & Drink',
                icon = 'fa-solid fa-drumstick-bite',
                items = {
                    { name = 'bread', price = 0.50 },
                    { name = 'water', price = 0.50 },
                },
            },
            {
                id = 'medicine',
                label = 'Medicine',
                icon = 'fa-solid fa-briefcase-medical',
                items = {
                    { name = 'bandage',    price = 0.25 },
                },
            },
            {
                id = 'tools',
                label = 'Tools',
                icon = 'fa-solid fa-toolbox',
                items = {
                    { name = 'canteen0', price = 5 },
                    { name = 'axe',      price = 5 },
                    { name = 'pickaxe',  price = 5 },
                    { name = 'shovel',   price = 5 },
                },
            },
        },
        ---------------------------------
        -- sell items
        ---------------------------------
        sell = {
            categories = {
                {
                    id = 'sell_herbs',
                    label = 'Herbs & Plants',
                    icon = 'fa-solid fa-leaf',
                    items = {
                        { name = 'herb_agarita',               price = 0.10 },
                        { name = 'herb_alaskan_ginseng',       price = 0.10 },
                        { name = 'herb_american_ginseng',      price = 0.10 },
                        { name = 'herb_bay_boletus',           price = 0.10 },
                        { name = 'herb_bitterweed',            price = 0.10 },
                        { name = 'herb_black_berry',           price = 0.10 },
                        { name = 'herb_black_current',         price = 0.10 },
                        { name = 'herb_bloodflower',           price = 0.10 },
                        { name = 'herb_burdock_root',          price = 0.10 },
                        { name = 'herb_cardinal_flower',       price = 0.10 },
                        { name = 'herb_chanterelles',          price = 0.10 },
                        { name = 'herb_choc_daisy',            price = 0.10 },
                        { name = 'herb_common_bullrush',       price = 0.10 },
                        { name = 'herb_creek_plum',            price = 0.10 },
                        { name = 'herb_creeping_thyme',        price = 0.10 },
                        { name = 'herb_crows_garlic',          price = 0.10 },
                        { name = 'herb_desert_sage',           price = 0.10 },
                        { name = 'herb_english_mace',          price = 0.10 },
                        { name = 'herb_evergreen_huckleberry', price = 0.10 },
                        { name = 'herb_golden_currant',        price = 0.10 },
                        { name = 'herb_harrietum_officinalis', price = 0.10 },
                        { name = 'herb_hummingbird_sage',      price = 0.10 },
                        { name = 'herb_indian_tobacco',        price = 0.10 },
                        { name = 'herb_lady_slipper',          price = 0.10 },
                        { name = 'herb_milkweed',              price = 0.10 },
                        { name = 'herb_oleander_sage',         price = 0.10 },
                        { name = 'herb_oregano',               price = 0.10 },
                        { name = 'herb_parasol_mushroom',      price = 0.10 },
                        { name = 'herb_prairie_poppy',         price = 0.10 },
                        { name = 'herb_rams_head',             price = 0.10 },
                        { name = 'herb_red_raspberry',         price = 0.10 },
                        { name = 'herb_red_sage',              price = 0.10 },
                        { name = 'herb_saltbush',              price = 0.10 },
                        { name = 'herb_texas_blue_bonnet',     price = 0.10 },
                        { name = 'herb_violet_snowdrop',       price = 0.10 },
                        { name = 'herb_wild_carrot',           price = 0.10 },
                        { name = 'herb_wild_feverfew',         price = 0.10 },
                        { name = 'herb_wild_mint',             price = 0.10 },
                        { name = 'herb_wild_rhubarb',          price = 0.10 },
                        { name = 'herb_wintergreen_berry',     price = 0.10 },
                        { name = 'herb_wisteria',              price = 0.10 },
                        { name = 'herb_yarrow',                price = 0.10 },
                    },
                },
                {
                    id = 'sell_misc',
                    label = 'General Goods',
                    icon = 'fa-solid fa-leaf',
                    items = {
                        { name = 'bread', price = 0.10 },
                        { name = 'water',   price = 0.10 },
                    },
                },
            },
        },
    },
    ---------------------------------
    -- Saint Denis General Store
    ---------------------------------
    {
        id = 'stden_general_store',
        label = 'Saint Denis General Store',
        coords = vector4(2859.36, -1202.19, 48.59, 14.85),
        npcmodel = 'u_m_m_nbxgeneralstoreowner_01',
        blip = {
            show = true,
            sprite = 'blip_shop_store',
            scale = 0.2,
            label = 'Saint Denis General Store',
        },
        money = 'cash',
        dynamicPricing = {
            enabled = true,
        },
        categories = {
            {
                id = 'food',
                label = 'Food & Drink',
                icon = 'fa-solid fa-drumstick-bite',
                items = {
                    { name = 'bread', price = 0.50 },
                    { name = 'water', price = 0.50 },
                },
            },
            {
                id = 'medicine',
                label = 'Medicine',
                icon = 'fa-solid fa-briefcase-medical',
                items = {
                    { name = 'bandage',    price = 0.25 },
                },
            },
            {
                id = 'tools',
                label = 'Tools',
                icon = 'fa-solid fa-toolbox',
                items = {
                    { name = 'canteen0', price = 5 },
                    { name = 'axe',      price = 5 },
                    { name = 'pickaxe',  price = 5 },
                    { name = 'shovel',   price = 5 },
                },
            },
        },
        ---------------------------------
        -- sell items
        ---------------------------------
        sell = {
            categories = {
                {
                    id = 'sell_herbs',
                    label = 'Herbs & Plants',
                    icon = 'fa-solid fa-leaf',
                    items = {
                        { name = 'herb_agarita',               price = 0.10 },
                        { name = 'herb_alaskan_ginseng',       price = 0.10 },
                        { name = 'herb_american_ginseng',      price = 0.10 },
                        { name = 'herb_bay_boletus',           price = 0.10 },
                        { name = 'herb_bitterweed',            price = 0.10 },
                        { name = 'herb_black_berry',           price = 0.10 },
                        { name = 'herb_black_current',         price = 0.10 },
                        { name = 'herb_bloodflower',           price = 0.10 },
                        { name = 'herb_burdock_root',          price = 0.10 },
                        { name = 'herb_cardinal_flower',       price = 0.10 },
                        { name = 'herb_chanterelles',          price = 0.10 },
                        { name = 'herb_choc_daisy',            price = 0.10 },
                        { name = 'herb_common_bullrush',       price = 0.10 },
                        { name = 'herb_creek_plum',            price = 0.10 },
                        { name = 'herb_creeping_thyme',        price = 0.10 },
                        { name = 'herb_crows_garlic',          price = 0.10 },
                        { name = 'herb_desert_sage',           price = 0.10 },
                        { name = 'herb_english_mace',          price = 0.10 },
                        { name = 'herb_evergreen_huckleberry', price = 0.10 },
                        { name = 'herb_golden_currant',        price = 0.10 },
                        { name = 'herb_harrietum_officinalis', price = 0.10 },
                        { name = 'herb_hummingbird_sage',      price = 0.10 },
                        { name = 'herb_indian_tobacco',        price = 0.10 },
                        { name = 'herb_lady_slipper',          price = 0.10 },
                        { name = 'herb_milkweed',              price = 0.10 },
                        { name = 'herb_oleander_sage',         price = 0.10 },
                        { name = 'herb_oregano',               price = 0.10 },
                        { name = 'herb_parasol_mushroom',      price = 0.10 },
                        { name = 'herb_prairie_poppy',         price = 0.10 },
                        { name = 'herb_rams_head',             price = 0.10 },
                        { name = 'herb_red_raspberry',         price = 0.10 },
                        { name = 'herb_red_sage',              price = 0.10 },
                        { name = 'herb_saltbush',              price = 0.10 },
                        { name = 'herb_texas_blue_bonnet',     price = 0.10 },
                        { name = 'herb_violet_snowdrop',       price = 0.10 },
                        { name = 'herb_wild_carrot',           price = 0.10 },
                        { name = 'herb_wild_feverfew',         price = 0.10 },
                        { name = 'herb_wild_mint',             price = 0.10 },
                        { name = 'herb_wild_rhubarb',          price = 0.10 },
                        { name = 'herb_wintergreen_berry',     price = 0.10 },
                        { name = 'herb_wisteria',              price = 0.10 },
                        { name = 'herb_yarrow',                price = 0.10 },
                    },
                },
                {
                    id = 'sell_misc',
                    label = 'General Goods',
                    icon = 'fa-solid fa-leaf',
                    items = {
                        { name = 'bread', price = 0.10 },
                        { name = 'water',   price = 0.10 },
                    },
                },
            },
        },
    },
    ---------------------------------
    -- Tumbleweed General Store
    ---------------------------------
    {
        id = 'tum_general_store',
        label = 'Tumbleweed General Store',
        coords = vector4(-5486.04, -2937.99, -1.40, 131.21),
        npcmodel = 'u_m_m_nbxgeneralstoreowner_01',
        blip = {
            show = true,
            sprite = 'blip_shop_store',
            scale = 0.2,
            label = 'Tumbleweed General Store',
        },
        money = 'cash',
        dynamicPricing = {
            enabled = true,
        },
        categories = {
            {
                id = 'food',
                label = 'Food & Drink',
                icon = 'fa-solid fa-drumstick-bite',
                items = {
                    { name = 'bread', price = 0.50 },
                    { name = 'water', price = 0.50 },
                },
            },
            {
                id = 'medicine',
                label = 'Medicine',
                icon = 'fa-solid fa-briefcase-medical',
                items = {
                    { name = 'bandage',    price = 0.25 },
                },
            },
            {
                id = 'tools',
                label = 'Tools',
                icon = 'fa-solid fa-toolbox',
                items = {
                    { name = 'canteen0', price = 5 },
                    { name = 'axe',      price = 5 },
                    { name = 'pickaxe',  price = 5 },
                    { name = 'shovel',   price = 5 },
                },
            },
        },
        ---------------------------------
        -- sell items
        ---------------------------------
        sell = {
            categories = {
                {
                    id = 'sell_herbs',
                    label = 'Herbs & Plants',
                    icon = 'fa-solid fa-leaf',
                    items = {
                        { name = 'herb_agarita',               price = 0.10 },
                        { name = 'herb_alaskan_ginseng',       price = 0.10 },
                        { name = 'herb_american_ginseng',      price = 0.10 },
                        { name = 'herb_bay_boletus',           price = 0.10 },
                        { name = 'herb_bitterweed',            price = 0.10 },
                        { name = 'herb_black_berry',           price = 0.10 },
                        { name = 'herb_black_current',         price = 0.10 },
                        { name = 'herb_bloodflower',           price = 0.10 },
                        { name = 'herb_burdock_root',          price = 0.10 },
                        { name = 'herb_cardinal_flower',       price = 0.10 },
                        { name = 'herb_chanterelles',          price = 0.10 },
                        { name = 'herb_choc_daisy',            price = 0.10 },
                        { name = 'herb_common_bullrush',       price = 0.10 },
                        { name = 'herb_creek_plum',            price = 0.10 },
                        { name = 'herb_creeping_thyme',        price = 0.10 },
                        { name = 'herb_crows_garlic',          price = 0.10 },
                        { name = 'herb_desert_sage',           price = 0.10 },
                        { name = 'herb_english_mace',          price = 0.10 },
                        { name = 'herb_evergreen_huckleberry', price = 0.10 },
                        { name = 'herb_golden_currant',        price = 0.10 },
                        { name = 'herb_harrietum_officinalis', price = 0.10 },
                        { name = 'herb_hummingbird_sage',      price = 0.10 },
                        { name = 'herb_indian_tobacco',        price = 0.10 },
                        { name = 'herb_lady_slipper',          price = 0.10 },
                        { name = 'herb_milkweed',              price = 0.10 },
                        { name = 'herb_oleander_sage',         price = 0.10 },
                        { name = 'herb_oregano',               price = 0.10 },
                        { name = 'herb_parasol_mushroom',      price = 0.10 },
                        { name = 'herb_prairie_poppy',         price = 0.10 },
                        { name = 'herb_rams_head',             price = 0.10 },
                        { name = 'herb_red_raspberry',         price = 0.10 },
                        { name = 'herb_red_sage',              price = 0.10 },
                        { name = 'herb_saltbush',              price = 0.10 },
                        { name = 'herb_texas_blue_bonnet',     price = 0.10 },
                        { name = 'herb_violet_snowdrop',       price = 0.10 },
                        { name = 'herb_wild_carrot',           price = 0.10 },
                        { name = 'herb_wild_feverfew',         price = 0.10 },
                        { name = 'herb_wild_mint',             price = 0.10 },
                        { name = 'herb_wild_rhubarb',          price = 0.10 },
                        { name = 'herb_wintergreen_berry',     price = 0.10 },
                        { name = 'herb_wisteria',              price = 0.10 },
                        { name = 'herb_yarrow',                price = 0.10 },
                    },
                },
                {
                    id = 'sell_misc',
                    label = 'General Goods',
                    icon = 'fa-solid fa-leaf',
                    items = {
                        { name = 'bread', price = 0.10 },
                        { name = 'water',   price = 0.10 },
                    },
                },
            },
        },
    },
    ---------------------------------
    -- Armadillo General Store
    ---------------------------------
    {
        id = 'arm_general_store',
        label = 'Armadillo General Store',
        coords = vector4(-3687.35, -2623.34, -14.43, 276.71),
        npcmodel = 'u_m_m_armgeneralstoreowner_01',
        blip = {
            show = true,
            sprite = 'blip_shop_store',
            scale = 0.2,
            label = 'Armadillo General Store',
        },
        money = 'cash',
        dynamicPricing = {
            enabled = true,
        },
        categories = {
            {
                id = 'food',
                label = 'Food & Drink',
                icon = 'fa-solid fa-drumstick-bite',
                items = {
                    { name = 'bread', price = 0.50 },
                    { name = 'water', price = 0.50 },
                },
            },
            {
                id = 'medicine',
                label = 'Medicine',
                icon = 'fa-solid fa-briefcase-medical',
                items = {
                    { name = 'bandage',    price = 0.25 },
                },
            },
            {
                id = 'tools',
                label = 'Tools',
                icon = 'fa-solid fa-toolbox',
                items = {
                    { name = 'canteen0', price = 5 },
                    { name = 'axe',      price = 5 },
                    { name = 'pickaxe',  price = 5 },
                    { name = 'shovel',   price = 5 },
                },
            },
        },
        ---------------------------------
        -- sell items
        ---------------------------------
        sell = {
            categories = {
                {
                    id = 'sell_herbs',
                    label = 'Herbs & Plants',
                    icon = 'fa-solid fa-leaf',
                    items = {
                        { name = 'herb_agarita',               price = 0.10 },
                        { name = 'herb_alaskan_ginseng',       price = 0.10 },
                        { name = 'herb_american_ginseng',      price = 0.10 },
                        { name = 'herb_bay_boletus',           price = 0.10 },
                        { name = 'herb_bitterweed',            price = 0.10 },
                        { name = 'herb_black_berry',           price = 0.10 },
                        { name = 'herb_black_current',         price = 0.10 },
                        { name = 'herb_bloodflower',           price = 0.10 },
                        { name = 'herb_burdock_root',          price = 0.10 },
                        { name = 'herb_cardinal_flower',       price = 0.10 },
                        { name = 'herb_chanterelles',          price = 0.10 },
                        { name = 'herb_choc_daisy',            price = 0.10 },
                        { name = 'herb_common_bullrush',       price = 0.10 },
                        { name = 'herb_creek_plum',            price = 0.10 },
                        { name = 'herb_creeping_thyme',        price = 0.10 },
                        { name = 'herb_crows_garlic',          price = 0.10 },
                        { name = 'herb_desert_sage',           price = 0.10 },
                        { name = 'herb_english_mace',          price = 0.10 },
                        { name = 'herb_evergreen_huckleberry', price = 0.10 },
                        { name = 'herb_golden_currant',        price = 0.10 },
                        { name = 'herb_harrietum_officinalis', price = 0.10 },
                        { name = 'herb_hummingbird_sage',      price = 0.10 },
                        { name = 'herb_indian_tobacco',        price = 0.10 },
                        { name = 'herb_lady_slipper',          price = 0.10 },
                        { name = 'herb_milkweed',              price = 0.10 },
                        { name = 'herb_oleander_sage',         price = 0.10 },
                        { name = 'herb_oregano',               price = 0.10 },
                        { name = 'herb_parasol_mushroom',      price = 0.10 },
                        { name = 'herb_prairie_poppy',         price = 0.10 },
                        { name = 'herb_rams_head',             price = 0.10 },
                        { name = 'herb_red_raspberry',         price = 0.10 },
                        { name = 'herb_red_sage',              price = 0.10 },
                        { name = 'herb_saltbush',              price = 0.10 },
                        { name = 'herb_texas_blue_bonnet',     price = 0.10 },
                        { name = 'herb_violet_snowdrop',       price = 0.10 },
                        { name = 'herb_wild_carrot',           price = 0.10 },
                        { name = 'herb_wild_feverfew',         price = 0.10 },
                        { name = 'herb_wild_mint',             price = 0.10 },
                        { name = 'herb_wild_rhubarb',          price = 0.10 },
                        { name = 'herb_wintergreen_berry',     price = 0.10 },
                        { name = 'herb_wisteria',              price = 0.10 },
                        { name = 'herb_yarrow',                price = 0.10 },
                    },
                },
                {
                    id = 'sell_misc',
                    label = 'General Goods',
                    icon = 'fa-solid fa-leaf',
                    items = {
                        { name = 'bread', price = 0.10 },
                        { name = 'water',   price = 0.10 },
                    },
                },
            },
        },
    },
    ---------------------------------
    -- Blackwater General Store
    ---------------------------------
    {
        id = 'blk_general_store',
        label = 'Blackwater General Store',
        coords = vector4(-784.77, -1322.15, 42.88, 194.64),
        npcmodel = 'u_m_o_blwgeneralstoreowner_01',
        blip = {
            show = true,
            sprite = 'blip_shop_store',
            scale = 0.2,
            label = 'Blackwater General Store',
        },
        money = 'cash',
        dynamicPricing = {
            enabled = true,
        },
        categories = {
            {
                id = 'food',
                label = 'Food & Drink',
                icon = 'fa-solid fa-drumstick-bite',
                items = {
                    { name = 'bread', price = 0.50 },
                    { name = 'water', price = 0.50 },
                },
            },
            {
                id = 'medicine',
                label = 'Medicine',
                icon = 'fa-solid fa-briefcase-medical',
                items = {
                    { name = 'bandage',    price = 0.25 },
                },
            },
            {
                id = 'tools',
                label = 'Tools',
                icon = 'fa-solid fa-toolbox',
                items = {
                    { name = 'canteen0', price = 5 },
                    { name = 'axe',      price = 5 },
                    { name = 'pickaxe',  price = 5 },
                    { name = 'shovel',   price = 5 },
                },
            },
        },
        ---------------------------------
        -- sell items
        ---------------------------------
        sell = {
            categories = {
                {
                    id = 'sell_herbs',
                    label = 'Herbs & Plants',
                    icon = 'fa-solid fa-leaf',
                    items = {
                        { name = 'herb_agarita',               price = 0.10 },
                        { name = 'herb_alaskan_ginseng',       price = 0.10 },
                        { name = 'herb_american_ginseng',      price = 0.10 },
                        { name = 'herb_bay_boletus',           price = 0.10 },
                        { name = 'herb_bitterweed',            price = 0.10 },
                        { name = 'herb_black_berry',           price = 0.10 },
                        { name = 'herb_black_current',         price = 0.10 },
                        { name = 'herb_bloodflower',           price = 0.10 },
                        { name = 'herb_burdock_root',          price = 0.10 },
                        { name = 'herb_cardinal_flower',       price = 0.10 },
                        { name = 'herb_chanterelles',          price = 0.10 },
                        { name = 'herb_choc_daisy',            price = 0.10 },
                        { name = 'herb_common_bullrush',       price = 0.10 },
                        { name = 'herb_creek_plum',            price = 0.10 },
                        { name = 'herb_creeping_thyme',        price = 0.10 },
                        { name = 'herb_crows_garlic',          price = 0.10 },
                        { name = 'herb_desert_sage',           price = 0.10 },
                        { name = 'herb_english_mace',          price = 0.10 },
                        { name = 'herb_evergreen_huckleberry', price = 0.10 },
                        { name = 'herb_golden_currant',        price = 0.10 },
                        { name = 'herb_harrietum_officinalis', price = 0.10 },
                        { name = 'herb_hummingbird_sage',      price = 0.10 },
                        { name = 'herb_indian_tobacco',        price = 0.10 },
                        { name = 'herb_lady_slipper',          price = 0.10 },
                        { name = 'herb_milkweed',              price = 0.10 },
                        { name = 'herb_oleander_sage',         price = 0.10 },
                        { name = 'herb_oregano',               price = 0.10 },
                        { name = 'herb_parasol_mushroom',      price = 0.10 },
                        { name = 'herb_prairie_poppy',         price = 0.10 },
                        { name = 'herb_rams_head',             price = 0.10 },
                        { name = 'herb_red_raspberry',         price = 0.10 },
                        { name = 'herb_red_sage',              price = 0.10 },
                        { name = 'herb_saltbush',              price = 0.10 },
                        { name = 'herb_texas_blue_bonnet',     price = 0.10 },
                        { name = 'herb_violet_snowdrop',       price = 0.10 },
                        { name = 'herb_wild_carrot',           price = 0.10 },
                        { name = 'herb_wild_feverfew',         price = 0.10 },
                        { name = 'herb_wild_mint',             price = 0.10 },
                        { name = 'herb_wild_rhubarb',          price = 0.10 },
                        { name = 'herb_wintergreen_berry',     price = 0.10 },
                        { name = 'herb_wisteria',              price = 0.10 },
                        { name = 'herb_yarrow',                price = 0.10 },
                    },
                },
                {
                    id = 'sell_misc',
                    label = 'General Goods',
                    icon = 'fa-solid fa-leaf',
                    items = {
                        { name = 'bread', price = 0.10 },
                        { name = 'water',   price = 0.10 },
                    },
                },
            },
        },
    },
    ---------------------------------
    -- Van Horn General Store
    ---------------------------------
    {
        id = 'van_general_store',
        label = 'Van Horn General Store',
        coords = vector4(3025.60, 562.29, 43.72, 262.32),
        npcmodel = 'u_m_o_blwgeneralstoreowner_01',
        blip = {
            show = true,
            sprite = 'blip_shop_store',
            scale = 0.2,
            label = 'Van Horn General Store',
        },
        money = 'cash',
        dynamicPricing = {
            enabled = true,
        },
        categories = {
            {
                id = 'food',
                label = 'Food & Drink',
                icon = 'fa-solid fa-drumstick-bite',
                items = {
                    { name = 'bread', price = 0.50 },
                    { name = 'water', price = 0.50 },
                },
            },
            {
                id = 'medicine',
                label = 'Medicine',
                icon = 'fa-solid fa-briefcase-medical',
                items = {
                    { name = 'bandage',    price = 0.25 },
                },
            },
            {
                id = 'tools',
                label = 'Tools',
                icon = 'fa-solid fa-toolbox',
                items = {
                    { name = 'canteen0', price = 5 },
                    { name = 'axe',      price = 5 },
                    { name = 'pickaxe',  price = 5 },
                    { name = 'shovel',   price = 5 },
                },
            },
        },
        ---------------------------------
        -- sell items
        ---------------------------------
        sell = {
            categories = {
                {
                    id = 'sell_herbs',
                    label = 'Herbs & Plants',
                    icon = 'fa-solid fa-leaf',
                    items = {
                        { name = 'herb_agarita',               price = 0.10 },
                        { name = 'herb_alaskan_ginseng',       price = 0.10 },
                        { name = 'herb_american_ginseng',      price = 0.10 },
                        { name = 'herb_bay_boletus',           price = 0.10 },
                        { name = 'herb_bitterweed',            price = 0.10 },
                        { name = 'herb_black_berry',           price = 0.10 },
                        { name = 'herb_black_current',         price = 0.10 },
                        { name = 'herb_bloodflower',           price = 0.10 },
                        { name = 'herb_burdock_root',          price = 0.10 },
                        { name = 'herb_cardinal_flower',       price = 0.10 },
                        { name = 'herb_chanterelles',          price = 0.10 },
                        { name = 'herb_choc_daisy',            price = 0.10 },
                        { name = 'herb_common_bullrush',       price = 0.10 },
                        { name = 'herb_creek_plum',            price = 0.10 },
                        { name = 'herb_creeping_thyme',        price = 0.10 },
                        { name = 'herb_crows_garlic',          price = 0.10 },
                        { name = 'herb_desert_sage',           price = 0.10 },
                        { name = 'herb_english_mace',          price = 0.10 },
                        { name = 'herb_evergreen_huckleberry', price = 0.10 },
                        { name = 'herb_golden_currant',        price = 0.10 },
                        { name = 'herb_harrietum_officinalis', price = 0.10 },
                        { name = 'herb_hummingbird_sage',      price = 0.10 },
                        { name = 'herb_indian_tobacco',        price = 0.10 },
                        { name = 'herb_lady_slipper',          price = 0.10 },
                        { name = 'herb_milkweed',              price = 0.10 },
                        { name = 'herb_oleander_sage',         price = 0.10 },
                        { name = 'herb_oregano',               price = 0.10 },
                        { name = 'herb_parasol_mushroom',      price = 0.10 },
                        { name = 'herb_prairie_poppy',         price = 0.10 },
                        { name = 'herb_rams_head',             price = 0.10 },
                        { name = 'herb_red_raspberry',         price = 0.10 },
                        { name = 'herb_red_sage',              price = 0.10 },
                        { name = 'herb_saltbush',              price = 0.10 },
                        { name = 'herb_texas_blue_bonnet',     price = 0.10 },
                        { name = 'herb_violet_snowdrop',       price = 0.10 },
                        { name = 'herb_wild_carrot',           price = 0.10 },
                        { name = 'herb_wild_feverfew',         price = 0.10 },
                        { name = 'herb_wild_mint',             price = 0.10 },
                        { name = 'herb_wild_rhubarb',          price = 0.10 },
                        { name = 'herb_wintergreen_berry',     price = 0.10 },
                        { name = 'herb_wisteria',              price = 0.10 },
                        { name = 'herb_yarrow',                price = 0.10 },
                    },
                },
                {
                    id = 'sell_misc',
                    label = 'General Goods',
                    icon = 'fa-solid fa-leaf',
                    items = {
                        { name = 'bread', price = 0.10 },
                        { name = 'water',   price = 0.10 },
                    },
                },
            },
        },
    },
    ---------------------------------
    -- Valentine Gunsmith
    ---------------------------------
    {
        id = 'val_gunsmith',
        label = 'Valentine Gunsmith',
        coords = vector4(-281.17, 778.94, 118.50, 0.59),
        npcmodel = 'u_m_m_valgunsmith_01',
        blip = {
            show = true,
            sprite = 'blip_shop_gunsmith',
            scale = 0.2,
            label = 'Valentine Gunsmith',
        },
        money = 'cash',
        dynamicPricing = {
            enabled = true,
            increasePerUnit = 0.05, -- ammo/weapons swing a bit faster than general goods
            decreasePerUnit = 0.05,
        },
        categories = {
            {
                id = 'ammo',
                label = 'Ammunition',
                icon = 'fa-solid fa-box',
                items = {
                    { name = 'ammo_box_pistol',   price = 1 },
                    { name = 'ammo_box_revolver', price = 1 },
                    { name = 'ammo_box_repeater', price = 1 },
                    { name = 'ammo_box_rifle',    price = 1 },
                    { name = 'ammo_box_shotgun',  price = 1 },
                    { name = 'ammo_box_varmint',  price = 1 },
                },
            },
            {
                id = 'weapons',
                label = 'Weapons',
                icon = 'fa-solid fa-gun',
                items = {
                    { name = 'weapon_revolver_cattleman',            price = 1 },
                    { name = 'weapon_revolver_doubleaction',         price = 1 },
                    { name = 'weapon_revolver_doubleaction_gambler', price = 1 },
                    { name = 'weapon_revolver_lemat',                price = 1 },
                    { name = 'weapon_revolver_navy',                 price = 1 },
                    { name = 'weapon_revolver_schofield',            price = 1 },
                    { name = 'weapon_pistol_mauser',                 price = 1 },
                    { name = 'weapon_pistol_semiauto',               price = 1 },
                    { name = 'weapon_pistol_volcanic',               price = 1 },
                    { name = 'weapon_rifle_boltaction',              price = 1 },
                    { name = 'weapon_rifle_elephant',                price = 1 },
                    { name = 'weapon_rifle_springfield',             price = 1 },
                    { name = 'weapon_rifle_varmint',                 price = 1 },
                    { name = 'weapon_repeater_carbine',              price = 1 },
                    { name = 'weapon_repeater_evans',                price = 1 },
                    { name = 'weapon_repeater_winchester',           price = 1 },
                    { name = 'weapon_repeater_henry',                price = 1 },
                    { name = 'weapon_sniperrifle_rollingblock',      price = 1 },
                    { name = 'weapon_sniperrifle_carcano',           price = 1 },
                },
            },
            {
                id = 'weaponcare',
                label = 'Weapon Care',
                icon = 'fa-solid fa-oil-can',
                items = {
                    { name = 'weapon_repair_kit', price = 3 },
                },
            },
        },
        ---------------------------------
        -- sell items
        ---------------------------------
        sell = {
            categories = {
                {
                    id = 'sell_scrap',
                    label = 'Scrap & Parts',
                    icon = 'fa-solid fa-screwdriver-wrench',
                    items = {
                        -- add items here
                    },
                },
            },
        },
    },
    ---------------------------------
    -- Tumbleweed Gunsmith
    ---------------------------------
    {
        id = 'tum_gunsmith',
        label = 'Tumbleweed Gunsmith',
        coords = vector4(-5506.41, -2963.95, -1.64, 110.02),
        npcmodel = 'u_m_m_tumgunsmith_01',
        blip = {
            show = true,
            sprite = 'blip_shop_gunsmith',
            scale = 0.2,
            label = 'Tumbleweed Gunsmith',
        },
        money = 'cash',
        dynamicPricing = {
            enabled = true,
            increasePerUnit = 0.05, -- ammo/weapons swing a bit faster than general goods
            decreasePerUnit = 0.05,
        },
        categories = {
            {
                id = 'ammo',
                label = 'Ammunition',
                icon = 'fa-solid fa-box',
                items = {
                    { name = 'ammo_box_pistol',   price = 1 },
                    { name = 'ammo_box_revolver', price = 1 },
                    { name = 'ammo_box_repeater', price = 1 },
                    { name = 'ammo_box_rifle',    price = 1 },
                    { name = 'ammo_box_shotgun',  price = 1 },
                    { name = 'ammo_box_varmint',  price = 1 },
                },
            },
            {
                id = 'weapons',
                label = 'Weapons',
                icon = 'fa-solid fa-gun',
                items = {
                    { name = 'weapon_revolver_cattleman',            price = 1 },
                    { name = 'weapon_revolver_doubleaction',         price = 1 },
                    { name = 'weapon_revolver_doubleaction_gambler', price = 1 },
                    { name = 'weapon_revolver_lemat',                price = 1 },
                    { name = 'weapon_revolver_navy',                 price = 1 },
                    { name = 'weapon_revolver_schofield',            price = 1 },
                    { name = 'weapon_pistol_mauser',                 price = 1 },
                    { name = 'weapon_pistol_semiauto',               price = 1 },
                    { name = 'weapon_pistol_volcanic',               price = 1 },
                    { name = 'weapon_rifle_boltaction',              price = 1 },
                    { name = 'weapon_rifle_elephant',                price = 1 },
                    { name = 'weapon_rifle_springfield',             price = 1 },
                    { name = 'weapon_rifle_varmint',                 price = 1 },
                    { name = 'weapon_repeater_carbine',              price = 1 },
                    { name = 'weapon_repeater_evans',                price = 1 },
                    { name = 'weapon_repeater_winchester',           price = 1 },
                    { name = 'weapon_repeater_henry',                price = 1 },
                    { name = 'weapon_sniperrifle_rollingblock',      price = 1 },
                    { name = 'weapon_sniperrifle_carcano',           price = 1 },
                },
            },
            {
                id = 'weaponcare',
                label = 'Weapon Care',
                icon = 'fa-solid fa-oil-can',
                items = {
                    { name = 'weapon_repair_kit', price = 3 },
                },
            },
        },
        ---------------------------------
        -- sell items
        ---------------------------------
        sell = {
            categories = {
                {
                    id = 'sell_scrap',
                    label = 'Scrap & Parts',
                    icon = 'fa-solid fa-screwdriver-wrench',
                    items = {
                        -- add items here
                    },
                },
            },
        },
    },
    ---------------------------------
    -- Saint Denis Gunsmith
    ---------------------------------
    {
        id = 'stden_gunsmith',
        label = 'Saint Denis Gunsmith',
        coords = vector4(2717.14, -1286.90, 48.64, 29.91),
        npcmodel = 'u_m_m_nbxgunsmith_01',
        blip = {
            show = true,
            sprite = 'blip_shop_gunsmith',
            scale = 0.2,
            label = 'Saint Denis Gunsmith',
        },
        money = 'cash',
        dynamicPricing = {
            enabled = true,
            increasePerUnit = 0.05, -- ammo/weapons swing a bit faster than general goods
            decreasePerUnit = 0.05,
        },
        categories = {
            {
                id = 'ammo',
                label = 'Ammunition',
                icon = 'fa-solid fa-box',
                items = {
                    { name = 'ammo_box_pistol',   price = 1 },
                    { name = 'ammo_box_revolver', price = 1 },
                    { name = 'ammo_box_repeater', price = 1 },
                    { name = 'ammo_box_rifle',    price = 1 },
                    { name = 'ammo_box_shotgun',  price = 1 },
                    { name = 'ammo_box_varmint',  price = 1 },
                },
            },
            {
                id = 'weapons',
                label = 'Weapons',
                icon = 'fa-solid fa-gun',
                items = {
                    { name = 'weapon_revolver_cattleman',            price = 1 },
                    { name = 'weapon_revolver_doubleaction',         price = 1 },
                    { name = 'weapon_revolver_doubleaction_gambler', price = 1 },
                    { name = 'weapon_revolver_lemat',                price = 1 },
                    { name = 'weapon_revolver_navy',                 price = 1 },
                    { name = 'weapon_revolver_schofield',            price = 1 },
                    { name = 'weapon_pistol_mauser',                 price = 1 },
                    { name = 'weapon_pistol_semiauto',               price = 1 },
                    { name = 'weapon_pistol_volcanic',               price = 1 },
                    { name = 'weapon_rifle_boltaction',              price = 1 },
                    { name = 'weapon_rifle_elephant',                price = 1 },
                    { name = 'weapon_rifle_springfield',             price = 1 },
                    { name = 'weapon_rifle_varmint',                 price = 1 },
                    { name = 'weapon_repeater_carbine',              price = 1 },
                    { name = 'weapon_repeater_evans',                price = 1 },
                    { name = 'weapon_repeater_winchester',           price = 1 },
                    { name = 'weapon_repeater_henry',                price = 1 },
                    { name = 'weapon_sniperrifle_rollingblock',      price = 1 },
                    { name = 'weapon_sniperrifle_carcano',           price = 1 },
                },
            },
            {
                id = 'weaponcare',
                label = 'Weapon Care',
                icon = 'fa-solid fa-oil-can',
                items = {
                    { name = 'weapon_repair_kit', price = 3 },
                },
            },
        },
        ---------------------------------
        -- sell items
        ---------------------------------
        sell = {
            categories = {
                {
                    id = 'sell_scrap',
                    label = 'Scrap & Parts',
                    icon = 'fa-solid fa-screwdriver-wrench',
                    items = {
                        -- add items here
                    },
                },
            },
        },
    },
    ---------------------------------
    -- Rhodes Gunsmith
    ---------------------------------
    {
        id = 'rho_gunsmith',
        label = 'Rhodes Gunsmith',
        coords = vector4(1322.31, -1323.02, 76.89, 354.88),
        npcmodel = 'u_m_m_rhdgunsmith_01',
        blip = {
            show = true,
            sprite = 'blip_shop_gunsmith',
            scale = 0.2,
            label = 'Rhodes Gunsmith',
        },
        money = 'cash',
        dynamicPricing = {
            enabled = true,
            increasePerUnit = 0.05, -- ammo/weapons swing a bit faster than general goods
            decreasePerUnit = 0.05,
        },
        categories = {
            {
                id = 'ammo',
                label = 'Ammunition',
                icon = 'fa-solid fa-box',
                items = {
                    { name = 'ammo_box_pistol',   price = 1 },
                    { name = 'ammo_box_revolver', price = 1 },
                    { name = 'ammo_box_repeater', price = 1 },
                    { name = 'ammo_box_rifle',    price = 1 },
                    { name = 'ammo_box_shotgun',  price = 1 },
                    { name = 'ammo_box_varmint',  price = 1 },
                },
            },
            {
                id = 'weapons',
                label = 'Weapons',
                icon = 'fa-solid fa-gun',
                items = {
                    { name = 'weapon_revolver_cattleman',            price = 1 },
                    { name = 'weapon_revolver_doubleaction',         price = 1 },
                    { name = 'weapon_revolver_doubleaction_gambler', price = 1 },
                    { name = 'weapon_revolver_lemat',                price = 1 },
                    { name = 'weapon_revolver_navy',                 price = 1 },
                    { name = 'weapon_revolver_schofield',            price = 1 },
                    { name = 'weapon_pistol_mauser',                 price = 1 },
                    { name = 'weapon_pistol_semiauto',               price = 1 },
                    { name = 'weapon_pistol_volcanic',               price = 1 },
                    { name = 'weapon_rifle_boltaction',              price = 1 },
                    { name = 'weapon_rifle_elephant',                price = 1 },
                    { name = 'weapon_rifle_springfield',             price = 1 },
                    { name = 'weapon_rifle_varmint',                 price = 1 },
                    { name = 'weapon_repeater_carbine',              price = 1 },
                    { name = 'weapon_repeater_evans',                price = 1 },
                    { name = 'weapon_repeater_winchester',           price = 1 },
                    { name = 'weapon_repeater_henry',                price = 1 },
                    { name = 'weapon_sniperrifle_rollingblock',      price = 1 },
                    { name = 'weapon_sniperrifle_carcano',           price = 1 },
                },
            },
            {
                id = 'weaponcare',
                label = 'Weapon Care',
                icon = 'fa-solid fa-oil-can',
                items = {
                    { name = 'weapon_repair_kit', price = 3 },
                },
            },
        },
        ---------------------------------
        -- sell items
        ---------------------------------
        sell = {
            categories = {
                {
                    id = 'sell_scrap',
                    label = 'Scrap & Parts',
                    icon = 'fa-solid fa-screwdriver-wrench',
                    items = {
                        -- add items here
                    },
                },
            },
        },
    },
    ---------------------------------
    -- Annesburg Gunsmith
    ---------------------------------
    {
        id = 'ann_gunsmith',
        label = 'Annesburg Gunsmith',
        coords = vector4(2948.42, 1319.44, 43.82, 79.11),
        npcmodel = 'u_m_m_asbgunsmith_01',
        blip = {
            show = true,
            sprite = 'blip_shop_gunsmith',
            scale = 0.2,
            label = 'Annesburg Gunsmith',
        },
        money = 'cash',
        dynamicPricing = {
            enabled = true,
            increasePerUnit = 0.05, -- ammo/weapons swing a bit faster than general goods
            decreasePerUnit = 0.05,
        },
        categories = {
            {
                id = 'ammo',
                label = 'Ammunition',
                icon = 'fa-solid fa-box',
                items = {
                    { name = 'ammo_box_pistol',   price = 1 },
                    { name = 'ammo_box_revolver', price = 1 },
                    { name = 'ammo_box_repeater', price = 1 },
                    { name = 'ammo_box_rifle',    price = 1 },
                    { name = 'ammo_box_shotgun',  price = 1 },
                    { name = 'ammo_box_varmint',  price = 1 },
                },
            },
            {
                id = 'weapons',
                label = 'Weapons',
                icon = 'fa-solid fa-gun',
                items = {
                    { name = 'weapon_revolver_cattleman',            price = 1 },
                    { name = 'weapon_revolver_doubleaction',         price = 1 },
                    { name = 'weapon_revolver_doubleaction_gambler', price = 1 },
                    { name = 'weapon_revolver_lemat',                price = 1 },
                    { name = 'weapon_revolver_navy',                 price = 1 },
                    { name = 'weapon_revolver_schofield',            price = 1 },
                    { name = 'weapon_pistol_mauser',                 price = 1 },
                    { name = 'weapon_pistol_semiauto',               price = 1 },
                    { name = 'weapon_pistol_volcanic',               price = 1 },
                    { name = 'weapon_rifle_boltaction',              price = 1 },
                    { name = 'weapon_rifle_elephant',                price = 1 },
                    { name = 'weapon_rifle_springfield',             price = 1 },
                    { name = 'weapon_rifle_varmint',                 price = 1 },
                    { name = 'weapon_repeater_carbine',              price = 1 },
                    { name = 'weapon_repeater_evans',                price = 1 },
                    { name = 'weapon_repeater_winchester',           price = 1 },
                    { name = 'weapon_repeater_henry',                price = 1 },
                    { name = 'weapon_sniperrifle_rollingblock',      price = 1 },
                    { name = 'weapon_sniperrifle_carcano',           price = 1 },
                },
            },
            {
                id = 'weaponcare',
                label = 'Weapon Care',
                icon = 'fa-solid fa-oil-can',
                items = {
                    { name = 'weapon_repair_kit', price = 3 },
                },
            },
        },
        ---------------------------------
        -- sell items
        ---------------------------------
        sell = {
            categories = {
                {
                    id = 'sell_scrap',
                    label = 'Scrap & Parts',
                    icon = 'fa-solid fa-screwdriver-wrench',
                    items = {
                        -- add items here
                    },
                },
            },
        },
    },
}
