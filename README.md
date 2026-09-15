# rsg-stores

A configurable general store / gunsmith resource for **RSG-Core** on **RedM**, with a custom NUI storefront, live server-side pricing, optional Discord logging, and full ox_lib locale support.

---

## Features

- **Custom NUI storefront** — a themed buy/sell menu (category rail, item grid, running basket) opened via `ox_target`, targeted on an NPC ped at each shop.
- **Buy and sell tabs** — each shop defines its own buy catalog, and can optionally define a separate sell-back catalog (`shop.sell`). Shops without a `sell` block simply don't show a Sell tab.
- **Server-authoritative pricing and validation** — the client never sets a price. Every basket line is re-validated and re-priced from `shared/config.lua` on the server before anything is charged, added, or removed, so a modified client can't manipulate totals.
- **Dynamic pricing (optional, per shop)** — every unit bought nudges that item's price up, every unit sold back nudges it down, pulling against each other. Tracked in memory per shop/item (resets on restart), with configurable rate and min/max multiplier clamps.
- **Progressive per-basket pricing** — buying or selling several units of the same item in one checkout prices each unit along the dynamic curve, exactly as if you'd bought them one at a time.
- **Accurate cent-level pricing** — supports sub-$1 item prices (e.g. $0.50 bread) with all totals rounded to the nearest cent, not the nearest dollar.
- **Inventory-full protection** — if a purchased item won't fit in the player's inventory, that item's exact cost is refunded automatically rather than charging for nothing.
- **Anti-exploit checks** — server-side proximity checks on every action (can't buy/sell by firing events from across the map), per-player request locking (can't double-submit a checkout), and basket validation that rejects malformed, duplicate, out-of-range, or non-finite quantities.
- **Discord webhook logging (optional)** — every completed purchase and sale is posted to a Discord webhook as an embed (player name, citizenid, items, total), queued and rate-limit safe. Fully disabled by default until you set a webhook URL.
- **Full ox_lib locale support** — every player-facing string (notifications, NUI text, toasts) and every Discord embed string lives in `locales/en.json`, ready to translate or reword without touching any code.
- **Blips and NPC peds** — each shop spawns an interactable ped and can optionally show a map blip.

---

## Dependencies

| Resource | Purpose |
|---|---|
| [`rsg-core`](https://github.com/Rexshack-RedM/rsg-core) | Framework — player data, money, inventory |
| [`ox_lib`](https://github.com/overextended/ox_lib) | Notifications (`ox_lib:notify`) and locale system |
| [`ox_target`](https://github.com/overextended/ox_target) | Interaction (ped targeting) |
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

4. Every item referenced in `shared/config.lua` (`bread`, `water`, `bandage`, `ammo_pistol`, etc.) must exist as a key in your `rsg-core/shared/items.lua` — the shop pulls each item's label, weight, and icon live from there. Only the **price** and category grouping live in this resource's config.
5. Every shop needs a valid `npcmodel` — there's no fallback interaction method, so a missing or bad model means that shop won't be interactable (see Troubleshooting below).
6. Restart the resource (or your server) and you're done. Two example shops (a Valentine general store and a gunsmith) are included out of the box and will work immediately if your item names match.

---

## Configuration

All configuration lives in `shared/config.lua`.

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

`Config.DynamicPricing` sets the resource-wide defaults; any shop can override individual fields with its own `dynamicPricing = { ... }` table.

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

### Shops

Each entry in `Config.Shops` defines one store:

```lua
{
    id = 'val_general_store',              -- unique identifier
    label = 'Valentine General Store',     -- shown in the NUI header and blip
    coords = vector4(x, y, z, heading),
    npcmodel = 'u_m_m_valgenstoreowner_01', -- required -- the shop's interactable ped
    blip = {
        show = true,
        sprite = 442,
        scale = 0.9,
        color = 2,
        label = 'General Store',
    },
    money = 'cash',                        -- overrides Config.Money for this shop
    dynamicPricing = { enabled = true },    -- overrides Config.DynamicPricing fields
    categories = {
        {
            id = 'food',
            label = 'Food & Drink',
            icon = 'fa-solid fa-drumstick-bite',   -- any Font Awesome 6 class
            items = {
                { name = 'bread', price = 0.50 },
                { name = 'water', price = 0.50 },
            },
        },
        -- more categories...
    },
    -- Optional: enables the Sell tab for this shop. Same shape as
    -- `categories` above, but each price is what the PLAYER receives.
    -- Omit this whole block to disable selling for the shop.
    sell = {
        categories = {
            {
                id = 'sell_herbs',
                label = 'Herbs & Plants',
                icon = 'fa-solid fa-leaf',
                items = {
                    { name = 'herb_wild_mint', price = 0.50 },
                },
            },
        },
    },
},
```

- `npcmodel` is required for every shop — there is no box-zone fallback. If it's missing or fails to load, that shop is skipped (logged to console) and won't be interactable until fixed.
- Omit `sell` entirely to make a buy-only shop (see the included Gunsmith example, whose `sell` block is present but empty — ready for you to fill in scrap items).
- Every `name` under `items` must match a key in `RSGCore.Shared.Items` — the label, weight, and icon come from there automatically; you only set the price and category here.

### Locales

All player-facing text (notification titles/descriptions, NUI labels, toasts, and Discord embed text) lives in `locales/en.json`, loaded via `ox_lib`'s locale system. To translate the resource, duplicate `en.json` as e.g. `locales/de.json`, translate the values (keep the `%s`/`%d` placeholders in place and in order), and set your server's ox_lib locale convar accordingly. No Lua or JS code needs to change.

---

## File structure

```
rsg-stores/
├── client/
│   └── client.lua        -- NUI open/close, ox_target registration, blips
├── server/
│   ├── server.lua         -- checkout/sell logic, validation, pricing, notifications
│   └── webhook.lua        -- Discord webhook queue/sender
├── shared/
│   └── config.lua         -- all configuration (see above)
├── locales/
│   └── en.json             -- all player-facing and Discord-facing text
├── ui/
│   ├── index.html
│   ├── script.js
│   └── style.css
└── fxmanifest.lua
```

---

## Troubleshooting

- **An item doesn't show up in a shop** — check the server console on start for `[rsg-stores] WARNING: item "..." does not exist in RSGCore.Shared.Items`. The item name in `config.lua` must exactly match a key in `rsg-core/shared/items.lua`.
- **A shop isn't interactable at all** — check the console for `[rsg-stores] WARNING: ped model "..." failed to load` or `[rsg-stores] ERROR: shop "..." has no npcmodel set`. There is no fallback interaction method, so a bad or missing `npcmodel` means that shop is skipped entirely until fixed.
- **No interaction at all** — make sure `ox_target` is started before `rsg-stores`; the console will log `ox_target is not running` if it starts too late.
- **Nothing posts to Discord** — confirm `Config.Webhooks.url` is set and check the console for `Discord webhook post failed with status ...`, which indicates Discord rejected the request (bad/expired webhook URL is the usual cause).
