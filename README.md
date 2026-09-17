# rsg-stores

A configurable shop resource for **RSG-Core** on **RedM**, with a buy/sell NUI, store hours, external shop exports, optional limited stock, and dynamic pricing.

---

## Features

- **Buy/sell storefront** with categories, baskets, larger item displays, and a remembered **Show only owned items** filter on Sell.
- **Store hours and doors** with global or individual schedules, closed-store blips, NPC removal, and temporary exit unlocking.
- **External shop exports** for registration, live price/stock updates, and stock-change tracking.
- **Optional limited stock** for configured and custom shops, with scheduled restocking and gradual overstock reduction.
- **Optional dynamic pricing** with global defaults and per-shop overrides. Multi-unit transactions price each unit progressively.
- **Server-side validation** of prices, proximity, baskets, and owned quantities, with request locking and inventory-full refunds.
- **Cent-level prices**, optional NPCs/blips, and queued Discord transaction logging.
- **ox_lib locales** for the storefront, transaction notifications, and webhook text.

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
| `Config.Money` | `'cash'` | Account used for purchases and sale payouts. Custom shops accept `cash`, `bank`, `bloodmoney`, or `gold`. Overridable per shop. |
| `Config.Img` | `'rsg-inventory/html/images/'` | Where item icons are loaded from. Change if your inventory resource's image folder differs. |
| `Config.MaxUniqueBasketItems` | `10` | Max number of *different* items in a buy basket at once. |
| `Config.MaxItemQuantity` | `99` | Max quantity of a single item per basket line (buying). |
| `Config.MaxUniqueSellItems` | `10` | Same as above, for the Sell tab. |
| `Config.MaxSellQuantity` | `99` | Max quantity of a single item per basket line (selling). |
| `Config.MaxInteractDistance` | `2.5` | Target interaction and exit-unlock distance. Server proximity checks allow an additional 3 units of movement/latency tolerance. |

### Store hours and doors

`Config.Hours` sets the global schedule: `open = 8`, `close = 20`, `enable = true`, and `unlockDuration = 30 * 1000` (milliseconds). Disabling `enable` keeps all shops open.

Standard and custom shops use the same optional fields. Add them to a `Config.Shops` entry or the shop table passed to `RegisterCustomShop`:

```lua
shop.Hours = { open = 9, close = 21 }
shop.Doors = { 972368328, 1060413677 } -- use the door IDs for your location
```

Omit `Hours` to follow the global schedule. Use `Hours = { alwaysOpen = true }` for an always-open shop. Opening and closing hours must be whole numbers from 0 to 23; overnight schedules are supported. Opening is inclusive and closing is exclusive. `Doors` is an optional sequential list of whole-number RedM door IDs; omit it or use an empty list for no door management.

Closed shops disable their target interaction, turn their blip red, remove their resource-spawned NPC, and lock configured doors. Approaching the interaction area within `Config.MaxInteractDistance` temporarily unlocks those doors for the global `unlockDuration` and shows an ox_lib notification. This checks proximity rather than whether the player is inside. Door IDs and behavior should be verified in-game.

Custom-shop settings are established at registration; re-registration and item updates do not change hours or doors. **Current limitation:** closing disables target interaction but does not close an open menu or enforce hours on `OpenShop` or server transactions.

### Dynamic pricing

`Config.DynamicPricing` supplies defaults for standard and custom shops. The included configured shops inherit these settings; dynamic pricing is globally disabled by default.

```lua
Config.DynamicPricing = {
    enabled = false,        -- off unless a shop turns it on
    increasePerUnit = 0.02, -- % price increase per unit bought
    decreasePerUnit = 0.02, -- % price decrease per unit sold back
    minMultiplier = 0.5,    -- price can never fall below 50% of base
    maxMultiplier = 3.0,    -- price can never exceed 300% of base
}
```

Rates are **percentage points**: `0.02` means 0.02%, and `5` means 5%. Buying raises an item's shared buy/sell multiplier; selling lowers it. Multipliers are held in memory per shop/item and reset to `1.0x` when rsg-stores restarts.

To override a shop, add `dynamicPricing = { enabled = true, increasePerUnit = 0.05 }`. Omitted fields inherit global values. Set `enabled = false` to disable it even when globally enabled, or `true` to enable it when globally disabled. Zero rates cause no movement.

Custom-shop item prices are base prices before the multiplier. Exported price updates retain the current multiplier; re-registration retains the shop's dynamic pricing settings.

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

Leave `url` empty to disable logging. When configured, completed purchases and sales post queued embeds containing the player's name, citizenid, items, and total.

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
        buy = {{'Food', 0.05}},
        sell = {{'Food', -0.01}},
    },
}
```

Add groups and shops to the existing tables. Each `buy` or `sell` entry is `{groupName, adjustment}`: a flat currency adjustment to that group's prices for that direction. Above, bread costs 0.25 to buy and pays 0.04 to sell before dynamic pricing. Adjusted base prices have a minimum of 0.01.

- `id` identifies the shop and must be unique; `label` is its NUI title.
- `coords` is the target zone centre and heading. NPCs spawn at z - 1.0.
- `npc = false` disables the NPC. `npc = true` requires a valid `npcmodel`. The target zone is created independently of NPC spawning.
- `blip.show` controls the map blip; `sprite` uses the configured RedM blip name.
- `money` overrides `Config.Money` for both purchases and sale payouts.
- An item needs a price for the relevant direction to appear on that tab. Omit a direction's price to exclude it.
- `buy = {}` creates a sell-only shop and opens Sell by default when a sell list is available. `sell = {}` creates a buy-only shop without a Sell tab.
- The Sell tab's **Show only owned items** checkbox hides items the player owns zero of and retains its preference across reopening.

### Store types

| Type | Setup | Pricing and inventory |
|---|---|---|
| Standard configured shop | `Config.Shops` and `Config.ItemGroups` in `shared/configShops.lua` | Group base prices, per-group adjustments, optional dynamic pricing, and finite or unlimited stock tracked separately per shop. |
| Custom shop with unlimited stock | Server `RegisterCustomShop` export; omit item `amount` | Supplied base prices, optional dynamic pricing, unlimited store inventory, no stock depletion or restocking. |
| Custom shop with finite stock | Server `RegisterCustomShop` export; set item `amount` and `maxStock` | Supplied base prices, optional dynamic pricing, tracked stock, optional scheduled restocking, and a soft restocking cap. |

General stores, gunsmiths, doctors, and other themed stores are built by choosing their groups. They do not need separate shop-type flags. Both standard and custom shops can be buy-only, sell-only, or buy/sell, and use the same NUI and target zones.

### Shop stock and restocking

Configured and custom shops use the same item stock fields and shop-level restock interval. Both accept `{groupName, adjustment}` buy/sell references; use an adjustment of `0` to leave the supplied base price unchanged.

For a configured shop, add stock fields to an item in `Config.ItemGroups` and set `restockTime` on each shop that should restock it:

```lua
-- Inside a Config.ItemGroups category's items list:
{ name = 'bread', buyPrice = 0.20, sellPrice = 0.05,
    amount = 10, maxStock = 20, restock = 5 },

-- Inside the corresponding Config.Shops entry:
restockTime = 15, -- minutes
```

Each shop using that group gets its own stock copy, initialized from `amount`. Sales and purchases at one store do not change another store's stock. To give stores different starting stock settings, define separate item groups. The included config omits stock fields and remains unlimited.

External resources supply their own shop/group tables to `RegisterCustomShop`, as shown below. Only registered custom shops support exported price/stock updates; configured shops change through transactions, dynamic pricing, and restocking.

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

These examples are alternative setups. Both shop types can mix finite and unlimited items. Basket limits and player-owned sale quantities apply to both modes. `maxStock` limits restocking; it does not reject player sales above that amount.

#### Restocking rules

Finite items require nonnegative whole `amount` and `maxStock`; optional `restock` is also a nonnegative whole quantity. Purchases reduce stock and cannot exceed availability; sales increase it, even above the soft cap. Omitted/zero `restockTime` disables scheduled restocking for the shop.

`Config.TargetStock = true` globally enables target-based restocking for limited-stock items in both shop types. Their starting `amount` is saved as the target; later transactions, exported stock updates, and re-registration do not change it. Use a starting amount at or below `maxStock`. Unlimited items are unaffected.

With target stock enabled, each scheduled tick follows these rules:

- **Below target:** add `restock`, capped at `maxStock`.
- **From target through max:** a 50/50 choice adds or removes `restock`, with the result kept between zero and `maxStock`. A decrease can take stock below target; the next tick then increases it. At max, an increase leaves stock unchanged.
- **Above max:** only reduce stock using the overstock tiers below.

Set `Config.TargetStock = false` to disable target behavior globally and always add `restock` up to `maxStock` when at or below the cap. There is no per-shop toggle.

Above the cap, `Config.OverstockReduction` compares excess stock to the restock quantity and subtracts a larger quantity from current stock:

| Excess stock / restock | Reduction |
|---|---|
| Up to 2 | restock * 1.5 |
| Above 2, up to 4 | restock * 2 |
| Above 4 | restock * 3 |

Reductions round to the nearest whole item and stop at `maxStock`. With maxStock 20 and restock 5, stock 30 becomes 22, while stock 50 becomes 35. Tiers are checked in ascending order; `math.huge` means infinity, so the final tier covers all higher ratios. Omitted/zero `restock` skips that item.

Stock is held in memory and resets to configured or registered amounts when rsg-stores restarts. Custom-shop owners can implement persistence through the stock event and exports; configured shops have no persistence/update interface.

### Exports and custom shop integration

Start rsg-stores before the external resource and add `dependency 'rsg-stores'` to that resource's manifest. Shops may register before or after players join; registration syncs their setup to connected clients without duplicate zones, NPCs, or blips.

| Interface | Side | Purpose and return value |
|---|---|---|
| `RegisterCustomShop(shop, itemGroups)` | Server | Register a shop owned by the calling resource. Returns `true` or `false, reason`. |
| `UpdateCustomShopItems(shopId, updates)` | Server | Set existing items' absolute stock and/or prices. Returns `true` or `false, reason`. |
| `GetCustomShopItems(shopId)` | Server | Read a copied snapshot keyed by item name. Returns `items` or `nil, reason`. |
| `OpenShop(shopId)` | Client | Request opening a known shop. Returns whether the asynchronous request started, not whether opening succeeded. Server state requests check proximity. |
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

Only the owning resource can update or read a custom shop. Editing its original config tables does not update the live shop; use the export.

- Updates accept only `amount`, `buyPrice`, and `sellPrice` for existing items. Stock amounts are absolute values, not increments.
- Set a price to `false` to hide the item from that tab, or a number of at least `0.01` to show it again if its group is listed. Disable both directions to hide it completely. Nil/omitted fields stay unchanged.
- Categories, item membership, stock mode, caps, restock settings, and other shop settings cannot be changed through item updates.
- Registration requires at least one numeric price per item; `false` is supported only in updates.
- Busy shops reject registration/updates with a reason. Retry on the resource's next update cycle.

Re-registration replaces existing prices and amounts but preserves all other settings and requires the same item list and stock modes. To apply changed shop settings, restart rsg-stores, then the registering resources. External resources should also re-register when rsg-stores starts.

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

Disable duplicate shop interactions, checkout, and restock timers in integrated resources. They can retain demand calculations and persistence, then send changes through exports.

For rotating selections, register the full possible item list once, then update directional prices to show or hide items. For example, a pelt trader can register all pelts in one group and enable only its current selection.

### Locales

Storefront text, transaction notifications, and Discord embed text use `locales/en.json`. Duplicate it as, for example, `locales/de.json`, translate the values while retaining `%s`/`%d` placeholders in order, and select that language through ox_lib's locale convar. The temporary door-unlock notification is currently hard-coded in `client/hours.lua`.

---

## File structure

```text
rsg-stores/
  client/hours.lua        -- schedules, doors, temporary exit unlocking
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
```

---

## Troubleshooting

- **An item does not show up**: confirm its name exists in `RSGCore.Shared.Items`, its group is listed on the correct shop tab, and it has that direction's price. Also check the owned-items filter on Sell.
- **A shop is not interactable**: check opening hours, zone coordinates, and that ox_target started first. NPC settings do not control interaction. For custom shops, inspect the registration export's success/reason.
- **Nothing posts to Discord** — confirm `Config.Webhooks.url` is set and check the console for `Discord webhook post failed with status ...`, which indicates Discord rejected the request (bad/expired webhook URL is the usual cause).
- **Custom stock or prices do not change**: use the update export rather than editing an already-registered config table. Re-registration applies incoming prices and stock. Restart rsg-stores and then the registering resource after loading code changes.
