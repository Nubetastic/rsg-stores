# rsg-stores

A configurable general store / gunsmith resource for **RSG-Core** on **RedM**, with a custom NUI storefront, live server-side pricing, optional Discord logging, and full ox_lib locale support.

---

## Features

- **Custom NUI storefront** — a themed buy/sell menu (category rail, item grid, running basket) opened via `ox_target`, opened through an ox_target box zone at each shop, independently of its optional NPC.
- **Buy and sell tabs** — each shop defines its own buy catalog, and can optionally define a separate sell-back catalog (`shop.sell`). Shops without a `sell` block simply don't show a Sell tab.
- **Server-authoritative pricing and validation** — the client never sets a price. Every basket line is re-validated and re-priced from the configured item groups or registered custom shop state on the server before anything is charged, added, or removed, so a modified client can't manipulate totals.
- **Dynamic pricing (optional, per shop)** — every unit bought nudges that item's price up, every unit sold back nudges it down, pulling against each other. Tracked in memory per shop/item (resets on restart), with configurable rate and min/max multiplier clamps.
- **Progressive per-basket pricing** — buying or selling several units of the same item in one checkout prices each unit along the dynamic curve, exactly as if you'd bought them one at a time.
- **Accurate cent-level pricing** — supports sub-$1 item prices (e.g. $0.50 bread) with all totals rounded to the nearest cent, not the nearest dollar.
- **Inventory-full protection** — if a purchased item won't fit in the player's inventory, that item's exact cost is refunded automatically rather than charging for nothing.
- **Anti-exploit checks** — server-side proximity checks on every action (can't buy/sell by firing events from across the map), per-player request locking (can't double-submit a checkout), and basket validation that rejects malformed, duplicate, out-of-range, or non-finite quantities.
- **Discord webhook logging (optional)** — every completed purchase and sale is posted to a Discord webhook as an embed (player name, citizenid, items, total), queued and rate-limit safe. Fully disabled by default until you set a webhook URL.
- **Full ox_lib locale support** — every player-facing string (notifications, NUI text, toasts) and every Discord embed string lives in `locales/en.json`, ready to translate or reword without touching any code.
- **Blips and NPC peds** — each shop can optionally spawn an NPC and show a map blip; interaction uses a zone.

---

## Dependencies

| Resource | Purpose |
|---|---|
| [`rsg-core`](https://github.com/Rexshack-RedM/rsg-core) | Framework — player data, money, inventory |
| [`ox_lib`](https://github.com/overextended/ox_lib) | Notifications (`ox_lib:notify`) and locale system |
| [`ox_target`](https://github.com/overextended/ox_target) | Interaction (box zones) |
| `rsg-inventory` | Item icons are loaded from its `html/images/` folder (configurable) |

All of the above must be installed and started **before** `rsg-stores` in your `server.cfg`.

---

## Installation

1. Download/clone this resource into your server's resources folder as `rsg-stores`.
2. Make sure `rsg-core`, `ox_lib`, and `ox_target` are installed and already working on your server.
3. Add it to your `server.cfg`, after its dependencies:

   ```cfg
   ensure rsg-core
   ensure ox_lib
   ensure ox_target
   ensure rsg-inventory
   ensure rsg-stores
   ```

4. Every configured item name must exist in `rsg-core/shared/items.lua`. Labels, weights, and images come from RSG; groups and prices are defined in `shared/configShops.lua`.
5. Set `npc = true` and a valid `npcmodel` for shops that need an NPC, or `npc = false` for a zone-only shop.
6. Restart the resource. The included shops and coordinates are based on rsg-shops, with additional configured herb buying and item groups.

---

## Configuration

Global settings live in `shared/config.lua`. Item groups and standard shops live in `shared/configShops.lua`, loaded after the global config. External resources register custom shops through server exports; no extra global config variables are required.

### Global settings

| Setting | Default | Description |
|---|---|---|
| `Config.Money` | `'cash'` | Default account type charged on checkout (`cash`, `bank`, `bloodmoney`, `gold`, ...). Overridable per shop. |
| `Config.Img` | `'rsg-inventory/html/images/'` | Where item icons are loaded from. Change if your inventory resource's image folder differs. |
| `Config.MaxUniqueBasketItems` | `10` | Max number of *different* items in a buy basket at once. |
| `Config.MaxItemQuantity` | `99` | Max quantity of a single item per basket line (buying). |
| `Config.MaxUniqueSellItems` | `10` | Same as above, for the Sell tab. |
| `Config.MaxSellQuantity` | `99` | Max quantity of a single item per basket line (selling). |
| `Config.MaxInteractDistance` | `3.0` | Max distance a player may be from a shop when the server processes any shop action. Keep this in sync with your interaction distance so players can't walk away and keep buying remotely. |

### Dynamic pricing

`Config.DynamicPricing` sets the resource-wide defaults; standard shops can override individual fields with its own `dynamicPricing = { ... }` table.

```lua
Config.DynamicPricing = {
    enabled = false,        -- off unless a shop turns it on
    increasePerUnit = 0.02, -- % price increase per unit bought
    decreasePerUnit = 0.02, -- % price decrease per unit sold back
    minMultiplier = 0.5,    -- price can never fall below 50% of base
    maxMultiplier = 3.0,    -- price can never exceed 300% of base
}
```

All percent fields are **percentage points**, not fractions (`5` = 5%, not 500%). The multiplier is in-memory only and resets to `1.0x` on resource/server restart — it is not persisted to a database.

### Discord webhook logging

```lua
Config.Webhooks = {
    url = '',                 -- your Discord webhook URL; leave empty to disable
    botName = 'RSG Stores',
    botAvatar = '',           -- optional avatar image URL
    purchaseColor = 3066993,  -- green
    saleColor = 15105570,     -- orange
}
```

Leave `url` empty (the default) to disable logging completely — no HTTP requests are ever made. When set, every completed purchase and sale posts an embed to that channel with the player's name/citizenid, items, and total. Messages are queued and sent one at a time to stay well under Discord's webhook rate limit, even if several players check out at once.

### Item groups and standard shops

Define reusable categories in `Config.ItemGroups` in `shared/configShops.lua`. Prices always use the player's perspective: `buyPrice` is paid by the player, and `sellPrice` is received by the player. Group metadata controls the category shown in the NUI.

```lua
Config.ItemGroups = {
    ['Food'] = {
        id = 'food',
        label = 'Food & Drink',
        icon = 'fa-solid fa-drumstick-bite',
        items = {
            { name = 'bread', buyPrice = 0.20, sellPrice = 0.05 },
            { name = 'water', buyPrice = 0.10, sellPrice = 0.025 },
        },
    },
}

Config.Shops = {
    {
        id = 'rho_general_store',
        label = 'Rhodes General Store',
        coords = vector4(1329.80, -1294.37, 77.02, 60.72),
        npc = false,
        npcmodel = 'u_m_m_rhdgenstoreowner_01',
        blip = {
            show = true,
            sprite = 'blip_shop_store',
            scale = 0.2,
            label = 'Rhodes General Store',
        },
        money = 'cash',
        dynamicPricing = { enabled = false },
        buy = {{'Food', 0.05}},
        sell = {{'Food', -0.01}},
    },
}
```

Add groups and shops to the existing tables when editing the included configuration. Each `buy` or `sell` entry is `{groupName, adjustment}`. The adjustment is a flat currency amount added to each item's price in that group for that direction, not a percentage. In this example, bread costs 0.25 to buy and pays 0.04 to sell before any dynamic pricing. Adjusted base prices have a minimum of 0.01. There is no separate `regionalPrice` table or nested `categories` block.

- `id` identifies the shop and must be unique; `label` is its NUI title.
- `coords` is the target zone centre and heading. NPCs spawn at z - 1.0.
- `npc = false` disables the NPC. `npc = true` requires a valid `npcmodel`. The target zone is created independently of NPC spawning.
- `blip.show` controls the map blip; `sprite` uses the configured RedM blip name.
- `money` overrides `Config.Money` for both purchases and sale payouts.
- `dynamicPricing` overrides global defaults for a standard shop. Zero increase/decrease rates produce no movement even when enabled.
- An item needs a price for the relevant direction to appear on that tab. Omit a direction's price to exclude it.
- `buy = {}` creates a sell-only shop and opens Sell by default when a sell list is available. `sell = {}` creates a buy-only shop without a Sell tab.
- The Sell tab's **Show only owned items** checkbox hides items the player owns zero of and retains its preference across reopening.

### Store types

| Type | Setup | Pricing and inventory |
|---|---|---|
| Standard configured shop | `Config.Shops` and `Config.ItemGroups` in `shared/configShops.lua` | Shared base prices, per-group flat adjustments, optional dynamic pricing, unlimited store stock. |
| Custom shop with unlimited stock | Server `RegisterCustomShop` export; omit item `amount` | Supplied final prices, unlimited store inventory, no stock depletion or restocking; dynamic pricing disabled. |
| Custom shop with finite stock | Server `RegisterCustomShop` export; set item `amount` and `maxStock` | Supplied final prices, tracked stock, optional scheduled restocking, and a soft restocking cap; dynamic pricing disabled. |

General stores, gunsmiths, doctors, and other themed stores are built by choosing their groups. They do not need separate shop-type flags. Both standard and custom shops can be buy-only, sell-only, or buy/sell, and use the same NUI and target zones.

### Custom shop stock and restocking

An external resource such as nt_trader supplies its shop and group tables when registering. Custom `buy` and `sell` references use `{groupName, 0}` because their prices are supplied directly.

#### Without stock limits

Omit stock fields from each item. Players can buy without depleting store inventory; player sales do not create tracked stock. Prices can still be updated through the exports.

```lua
local itemGroups = {
    ['Trading'] = {
        id = 'trading',
        label = 'Trading',
        icon = 'fa-solid fa-boxes-stacked',
        items = {
            { name = 't_hay', buyPrice = 15.00, sellPrice = 8.00 },
        },
    },
}

local shop = {
    id = 'rhodes-trading-unlimited',
    label = 'Rhodes Trading',
    coords = vector4(1329.80, -1294.37, 77.02, 60.72),
    npc = false,
    buy = {{'Trading', 0}},
    sell = {{'Trading', 0}},
}

local success, reason = exports['rsg-stores']:RegisterCustomShop(shop, itemGroups)
```

#### With stock limits

Use the same group and shop structure, adding stock fields to the items and a restock interval to the shop. For example, replace the item above and set the shop's interval before registration:

```lua
itemGroups['Trading'].items = {
    { name = 't_hay', buyPrice = 15.00, sellPrice = 8.00,
        amount = 10, maxStock = 50, restock = 15 },
}
shop.id = 'rhodes-trading-finite'
shop.restockTime = 15 -- minutes

local success, reason = exports['rsg-stores']:RegisterCustomShop(shop, itemGroups)
```

These examples are alternatives for a store's setup. Stock mode is chosen per item, so a custom shop can also mix finite and unlimited items. Basket limits and player-owned sale quantities apply to both modes. `maxStock` limits restocking; it does not reject player sales above that amount.

#### Restocking rules

```lua
-- Item inside an external resource's group:
{ name = 't_hay', buyPrice = 15.00, sellPrice = 8.00,
    amount = 10, maxStock = 50, restock = 15 }

-- Setting on that external shop:
restockTime = 15, -- minutes; omitted/zero disables scheduled restocking
```

Omit `amount` for unlimited stock. Finite items require nonnegative whole `amount` and `maxStock`; `restock` is a nonnegative whole quantity. Purchases reduce stock and cannot exceed availability. Player sales increase stock and may exceed `maxStock`, which is a soft restocking cap. Player-owned quantities and the global basket limits still apply to sales.

On each scheduled tick, an item with positive `restock` gains that quantity up to `maxStock` when at or below the cap. When above the cap, its amount becomes `math.max(0, maxStock - restock * 3)`. For maxStock 50 and restock 15, overstock becomes 5. The cap itself stays 50. Omitted/zero `restock` skips scheduled changes for that item.

Stock is held in memory. rsg-stores does not implement `persistentStock` or database persistence; an external resource can track and restore its own economy state.

### Exports and custom shop integration

Start rsg-stores before the external resource and add `dependency 'rsg-stores'` to that resource's manifest. Shops may register before or after players join; registration syncs their setup to connected clients without duplicate zones, NPCs, or blips.

| Interface | Side | Purpose and return value |
|---|---|---|
| `RegisterCustomShop(shop, itemGroups)` | Server | Register a shop owned by the calling resource. Returns `true` or `false, reason`. |
| `UpdateCustomShopItems(shopId, updates)` | Server | Set existing items' absolute stock and/or prices. Returns `true` or `false, reason`. |
| `GetCustomShopItems(shopId)` | Server | Read a copied snapshot keyed by item name. Returns `items` or `nil, reason`. |
| `OpenShop(shopId)` | Client | Start opening a known shop using the existing distance checks. Returns whether the asynchronous request started. |
| `rsg-stores:server:CustomShopStockChanged` | Server-local event | Report resulting stock after purchases, sales, restocking, or exported stock changes. |

```lua
-- External resource's server code, after its config has loaded:
local success, reason = exports['rsg-stores']:RegisterCustomShop(shop, Config.ItemGroups)

-- Updates are keyed by item name. Omitted fields remain unchanged.
local success, reason = exports['rsg-stores']:UpdateCustomShopItems(shop.id, {
    t_hay = { amount = 12, buyPrice = 18.00, sellPrice = 9.00 },
})

local items, reason = exports['rsg-stores']:GetCustomShopItems(shop.id)
```

Only the owning resource can update or read a custom shop through the server exports. Editing the external config table after registration does not change the live shop; call the update export. Set `buyPrice = false` or `sellPrice = false` in an update to remove that price and hide the item from that tab. Set a numeric price of at least 0.01 to enable it again if its group is listed on that tab. Nil or omitted fields leave the live value unchanged. Updates cannot change categories, finite/unlimited mode, maxStock, restock, or shop settings. A busy shop rejects registration/update requests with a reason; the caller should retry in its next update cycle.

Re-registering an existing shop from its owner replaces its live `buyPrice`, `sellPrice`, and `amount` with the supplied values, including after restarting nt_trader. Existing settings, item membership, stock mode, and restock timing remain unchanged. Validation completes before applying the new values.

Changes sync to clients and refresh an open custom shop, clearing its baskets while retaining its selected tab, valid category, and owned-items preference. Checkout checks the shop revision to reject outdated baskets.

```lua
AddEventHandler('rsg-stores:server:CustomShopStockChanged', function(shopId, changedItems, reason)
    if shopId ~= 'gen-rhodes-trading' then return end
    if changedItems.t_hay then
        local amount = changedItems.t_hay.amount -- resulting absolute stock
        -- Update this resource's demand or persistence tracking.
    end
end)
```

The stock event reasons are `buy`, `sell`, `restock`, and `update`. Price-only updates do not emit it. Filter by your shop IDs and avoid sending another stock update in response to every `update` notification.

Disable the external resource's duplicate interactions, checkout, and restock timers for integrated shops. rsg-stores manages the storefront and transactions; nt_trader can retain demand calculations and persistence and send revised prices/stock through exports. Its separate market guide and demand-tier display are not added to the NUI by this integration.

See [exports.md](exports.md) for full signatures, validation rules, registration examples, and integration steps. [trader.lua](trader.lua) is an external configuration draft and is not loaded by rsg-stores.

#### Runtime item availability (nt_pelt_trader)

A resource such as `nt_pelt_trader` can register a shop with a single `Pelts` item group containing every item it might offer. Reference that group in the shop's `buy` and/or `sell` lists with an adjustment of `0`. Each item must have at least one valid price during registration.

After successful registration, call `UpdateCustomShopItems` from `nt_pelt_trader` to set `buyPrice = false` and/or `sellPrice = false` for items that should be hidden. Disable both prices to hide an item completely. Whenever its available selection changes during runtime, send another update: a numeric price of at least `0.01` shows an item on that tab again, and `false` hides it. Open shops refresh automatically.

Register the full possible item list up front; runtime updates change which registered items are available, rather than adding new item names or replacing the group. Editing the original group table alone does not update the live shop. Retry a rejected busy update on the resource's next update cycle.

### Locales

All player-facing text (notification titles/descriptions, NUI labels, toasts, and Discord embed text) lives in `locales/en.json`, loaded via `ox_lib`'s locale system. To translate the resource, duplicate `en.json` as e.g. `locales/de.json`, translate the values (keep the `%s`/`%d` placeholders in place and in order), and set your server's ox_lib locale convar accordingly. No Lua or JS code needs to change.

---

## File structure

```text
rsg-stores/
  client/client.lua       -- NUI, target zones, optional NPCs and blips
  server/server.lua       -- transactions, custom shops, stock and pricing
  server/webhook.lua      -- Discord webhook queue/sender
  server/versionchecker.lua
  shared/config.lua       -- global settings
  shared/configShops.lua  -- standard shop definitions and item groups
  locales/en.json         -- player-facing and webhook text
  ui/index.html
  ui/script.js
  ui/style.css
  fxmanifest.lua
  exports.md              -- custom shop API reference
  custom.md               -- custom shop planning
  trader.lua              -- external trader config draft; not loaded
```

---

## Troubleshooting

- **An item does not show up**: confirm its name exists in `RSGCore.Shared.Items`, its group is listed on the correct shop tab, and it has that direction's price. Also check the owned-items filter on Sell.
- **A shop is not interactable**: verify its zone coordinates and that ox_target started before rsg-stores. NPC settings do not control the target zone. For a custom shop, check the registration export's success/reason in the external resource.
- **No interaction at all** — make sure `ox_target` is started before `rsg-stores`; the console will log `ox_target is not running` if it starts too late.
- **Nothing posts to Discord** — confirm `Config.Webhooks.url` is set and check the console for `Discord webhook post failed with status ...`, which indicates Discord rejected the request (bad/expired webhook URL is the usual cause).
- **Custom stock or prices do not change**: use the update export rather than editing an already-registered config table. Re-registration applies incoming prices and stock. Restart rsg-stores and then the registering resource after loading code changes.
