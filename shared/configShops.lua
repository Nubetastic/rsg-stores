Config.ItemGroups = {
    ["Food"] = {
        id = 'food',
        label = 'Food & Drink',
        icon = 'fa-solid fa-drumstick-bite',
        items = {
            { name = 'bread', sellPrice = 0.10, buyPrice = 0.50 },
            { name = 'water', sellPrice = 0.10, buyPrice = 0.50 },
        },
    },
    ["Medicine"] = {
        id = 'medicine',
        label = 'Medicine',
        icon = 'fa-solid fa-briefcase-medical',
        items = {
            { name = 'bandage', buyPrice = 0.25 },
        },
    },
    ["Tools"] = {
        id = 'tools',
        label = 'Tools',
        icon = 'fa-solid fa-toolbox',
        items = {
            { name = 'canteen0', buyPrice = 5 },
            { name = 'axe', buyPrice = 5 },
            { name = 'pickaxe', buyPrice = 5 },
            { name = 'shovel', buyPrice = 5 },
        },
    },
    ["Herbs"] = {
        id = 'sell_herbs',
        label = 'Herbs & Plants',
        icon = 'fa-solid fa-leaf',
        items = {
            { name = 'herb_agarita', sellPrice = 0.10 },
            { name = 'herb_alaskan_ginseng', sellPrice = 0.10 },
            { name = 'herb_american_ginseng', sellPrice = 0.10 },
            { name = 'herb_bay_boletus', sellPrice = 0.10 },
            { name = 'herb_bitterweed', sellPrice = 0.10 },
            { name = 'herb_black_berry', sellPrice = 0.10 },
            { name = 'herb_black_current', sellPrice = 0.10 },
            { name = 'herb_bloodflower', sellPrice = 0.10 },
            { name = 'herb_burdock_root', sellPrice = 0.10 },
            { name = 'herb_cardinal_flower', sellPrice = 0.10 },
            { name = 'herb_chanterelles', sellPrice = 0.10 },
            { name = 'herb_choc_daisy', sellPrice = 0.10 },
            { name = 'herb_common_bullrush', sellPrice = 0.10 },
            { name = 'herb_creek_plum', sellPrice = 0.10 },
            { name = 'herb_creeping_thyme', sellPrice = 0.10 },
            { name = 'herb_crows_garlic', sellPrice = 0.10 },
            { name = 'herb_desert_sage', sellPrice = 0.10 },
            { name = 'herb_english_mace', sellPrice = 0.10 },
            { name = 'herb_evergreen_huckleberry', sellPrice = 0.10 },
            { name = 'herb_golden_currant', sellPrice = 0.10 },
            { name = 'herb_harrietum_officinalis', sellPrice = 0.10 },
            { name = 'herb_hummingbird_sage', sellPrice = 0.10 },
            { name = 'herb_indian_tobacco', sellPrice = 0.10 },
            { name = 'herb_lady_slipper', sellPrice = 0.10 },
            { name = 'herb_milkweed', sellPrice = 0.10 },
            { name = 'herb_oleander_sage', sellPrice = 0.10 },
            { name = 'herb_oregano', sellPrice = 0.10 },
            { name = 'herb_parasol_mushroom', sellPrice = 0.10 },
            { name = 'herb_prairie_poppy', sellPrice = 0.10 },
            { name = 'herb_rams_head', sellPrice = 0.10 },
            { name = 'herb_red_raspberry', sellPrice = 0.10 },
            { name = 'herb_red_sage', sellPrice = 0.10 },
            { name = 'herb_saltbush', sellPrice = 0.10 },
            { name = 'herb_texas_blue_bonnet', sellPrice = 0.10 },
            { name = 'herb_violet_snowdrop', sellPrice = 0.10 },
            { name = 'herb_wild_carrot', sellPrice = 0.10 },
            { name = 'herb_wild_feverfew', sellPrice = 0.10 },
            { name = 'herb_wild_mint', sellPrice = 0.10 },
            { name = 'herb_wild_rhubarb', sellPrice = 0.10 },
            { name = 'herb_wintergreen_berry', sellPrice = 0.10 },
            { name = 'herb_wisteria', sellPrice = 0.10 },
            { name = 'herb_yarrow', sellPrice = 0.10 },
        },
    },
    ["Ammunition"] = {
        id = 'ammo',
        label = 'Ammunition',
        icon = 'fa-solid fa-box',
        items = {
            { name = 'ammo_box_pistol', buyPrice = 1 },
            { name = 'ammo_box_revolver', buyPrice = 1 },
            { name = 'ammo_box_repeater', buyPrice = 1 },
            { name = 'ammo_box_rifle', buyPrice = 1 },
            { name = 'ammo_box_shotgun', buyPrice = 1 },
            { name = 'ammo_box_varmint', buyPrice = 1 },
        },
    },
    ["Weapons"] = {
        id = 'weapons',
        label = 'Weapons',
        icon = 'fa-solid fa-gun',
        items = {
            { name = 'weapon_revolver_cattleman', buyPrice = 1 },
            { name = 'weapon_revolver_doubleaction', buyPrice = 1 },
            { name = 'weapon_revolver_doubleaction_gambler', buyPrice = 1 },
            { name = 'weapon_revolver_lemat', buyPrice = 1 },
            { name = 'weapon_revolver_navy', buyPrice = 1 },
            { name = 'weapon_revolver_schofield', buyPrice = 1 },
            { name = 'weapon_pistol_mauser', buyPrice = 1 },
            { name = 'weapon_pistol_semiauto', buyPrice = 1 },
            { name = 'weapon_pistol_volcanic', buyPrice = 1 },
            { name = 'weapon_rifle_boltaction', buyPrice = 1 },
            { name = 'weapon_rifle_elephant', buyPrice = 1 },
            { name = 'weapon_rifle_springfield', buyPrice = 1 },
            { name = 'weapon_rifle_varmint', buyPrice = 1 },
            { name = 'weapon_repeater_carbine', buyPrice = 1 },
            { name = 'weapon_repeater_evans', buyPrice = 1 },
            { name = 'weapon_repeater_winchester', buyPrice = 1 },
            { name = 'weapon_repeater_henry', buyPrice = 1 },
            { name = 'weapon_sniperrifle_rollingblock', buyPrice = 1 },
            { name = 'weapon_sniperrifle_carcano', buyPrice = 1 },
        },
    },
    ["Weapon Care"] = {
        id = 'weaponcare',
        label = 'Weapon Care',
        icon = 'fa-solid fa-oil-can',
        items = {
            { name = 'weapon_repair_kit', buyPrice = 3 },
        },
    },
    ["Scrap & Parts"] = {
        id = 'sell_scrap',
        label = 'Scrap & Parts',
        icon = 'fa-solid fa-screwdriver-wrench',
        items = {
            -- add items here
        },
    },
    ["Medic Job"] = {
        id = 'medicjob',
        label = 'Medic Job',
        icon = 'fa-solid fa-briefcase-medical',
        items = {
            { name = 'bandage', buyPrice = 0.0 },
            { name = 'firstaid', buyPrice = 0.0 },
        },
    },
    ["Law Job"] = {
        id = 'lawjob',
        label = 'Law Job',
        icon = 'fa-solid fa-gun',
        items = {
            { name = 'weapon_revolver_cattleman', buyPrice = 0.0 },
            { name = 'weapon_repeater_winchester', buyPrice = 0.0 },
            { name = 'ammo_box_revolver', buyPrice = 0.0 },
            { name = 'ammo_box_repeater', buyPrice = 0.0 },
        },
    },
}

Config.Shops = {
    ---------------------------------
    -- Valentine General Store
    ---------------------------------
    {
        id = 'val_general_store',
        Doors = { 706990067, 4004877412 },
        label = 'Valentine General Store',
        coords = vector4(-324.14, 803.51, 117.88, 280.98),
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
        buy = {{'Food', 0.0}, {'Medicine', 0.0}, {'Tools', 0.0}},
        sell = {{'Herbs', 0.0}, {'Food', 0.0}},
    },
    ---------------------------------
    -- Valentine Medic Job
    ---------------------------------
    {
        id = 'val_medic_store',
        Doors = {},
        label = 'Valentine Medic Store',
        coords = vector4(-288.47, 813.01, 119.39, 139.17),
        npcmodel = 'u_m_m_valdoctor_01',
		jobs = { 'medic' },
        blip = {
            show = true,
            sprite = 'blip_shop_store',
            scale = 0.2,
            label = 'Valentine Medic Store',
        },
        money = 'cash',
        dynamicPricing = {
            enabled = false,
        },
        buy = {{'Medic Job', 0.0}},
        sell = {{'Medic Job', 0.0}},
    },
    ---------------------------------
    -- Valentine Law Store
    ---------------------------------
    {
        id = 'val_law_store',
        Doors = {},
        label = 'Valentine Law Store',
        coords = vector4(-279.15, 805.93, 119.38, 286.26),
        npcmodel = 'cs_valsheriff',
		jobs = { 'vallaw' },
        blip = {
            show = true,
            sprite = 'blip_shop_store',
            scale = 0.2,
            label = 'Valentine Law Store',
        },
        money = 'cash',
        dynamicPricing = {
            enabled = false,
        },
        buy = {{'Law Job', 0.0}},
        sell = {{'Law Job', 0.0}},
    },
    ---------------------------------
    -- Rhodes General Store
    ---------------------------------
    {
        id = 'rho_general_store',
        Doors = { 972368328, 1060413677 },
        label = 'Rhodes General Store',
        coords = vector4(1329.80, -1294.37, 77.02, 60.72),
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
        buy = {{'Food', 0.0}, {'Medicine', 0.0}, {'Tools', 0.0}},
        sell = {{'Herbs', 0.0}, {'Food', 0.0}},
    },
    ---------------------------------
    -- Strawberry General Store
    ---------------------------------
    {
        id = 'str_general_store',
        Doors = { 1595373759, 1854467923 },
        label = 'Strawberry General Store',
        coords = vector4(-1789.78, -388.15, 160.33, 65.43),
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
        buy = {{'Food', 0.0}, {'Medicine', 0.0}, {'Tools', 0.0}},
        sell = {{'Herbs', 0.0}, {'Food', 0.0}},
    },
    ---------------------------------
    -- Annesburg General Store
    ---------------------------------
    {
        id = 'ann_general_store',
        Doors = {}, -- Add door IDs for this location.
        label = 'Annesburg General Store',
        coords = vector4(2930.97, 1365.38, 45.20, 252.02),
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
        buy = {{'Food', 0.0}, {'Medicine', 0.0}, {'Tools', 0.0}},
        sell = {{'Herbs', 0.0}, {'Food', 0.0}},
    },
    ---------------------------------
    -- Saint Denis General Store
    ---------------------------------
    {
        id = 'stden_general_store',
        Doors = { 1051874490, 3986240381, 4114891219, 4234072328 },
        label = 'Saint Denis General Store',
        coords = vector4(2859.36, -1202.19, 49.59, 14.85),
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
        buy = {{'Food', 0.0}, {'Medicine', 0.0}, {'Tools', 0.0}},
        sell = {{'Herbs', 0.0}, {'Food', 0.0}},
    },
    ---------------------------------
    -- Tumbleweed General Store
    ---------------------------------
    {
        id = 'tum_general_store',
        Doors = { 687453229, 3834405300 },
        label = 'Tumbleweed General Store',
        coords = vector4(-5486.04, -2937.99, -0.40, 131.21),
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
        buy = {{'Food', 0.0}, {'Medicine', 0.0}, {'Tools', 0.0}},
        sell = {{'Herbs', 0.0}, {'Food', 0.0}},
    },
    ---------------------------------
    -- Armadillo General Store
    ---------------------------------
    {
        id = 'arm_general_store',
        Doors = { 688797849, 986766366, 1848144587 },
        label = 'Armadillo General Store',
        coords = vector4(-3687.35, -2623.34, -13.43, 276.71),
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
        buy = {{'Food', 0.0}, {'Medicine', 0.0}, {'Tools', 0.0}},
        sell = {{'Herbs', 0.0}, {'Food', 0.0}},
    },
    ---------------------------------
    -- Blackwater General Store
    ---------------------------------
    {
        id = 'blk_general_store',
        Doors = { 2796645535, 3042576856, 2046989122 },
        label = 'Blackwater General Store',
        coords = vector4(-784.77, -1322.15, 43.88, 194.64),
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
        buy = {{'Food', 0.0}, {'Medicine', 0.0}, {'Tools', 0.0}},
        sell = {{'Herbs', 0.0}, {'Food', 0.0}},
    },
    ---------------------------------
    -- Van Horn General Store
    ---------------------------------
    {
        id = 'van_general_store',
        Doors = { 877945562, 2641204994, 3375224492, 1477864640 },
        label = 'Van Horn General Store',
        coords = vector4(3025.60, 562.29, 44.72, 262.32),
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
        buy = {{'Food', 0.0}, {'Medicine', 0.0}, {'Tools', 0.0}},
        sell = {{'Herbs', 0.0}, {'Food', 0.0}},
    },
    ---------------------------------
    -- Valentine Gunsmith
    ---------------------------------
    {
        id = 'val_gunsmith',
        Doors = { 475159788, 2042647667 },
        label = 'Valentine Gunsmith',
        coords = vector4(-281.17, 778.94, 119.50, 0.59),
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
        buy = {{'Ammunition', 0.0}, {'Weapons', 0.0}, {'Weapon Care', 0.0}},
        sell = {{'Scrap & Parts', 0.0}},
    },
    ---------------------------------
    -- Tumbleweed Gunsmith
    ---------------------------------
    {
        id = 'tum_gunsmith',
        Doors = { 1880285656 },
        label = 'Tumbleweed Gunsmith',
        coords = vector4(-5506.41, -2963.95, -0.64, 110.02),
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
        buy = {{'Ammunition', 0.0}, {'Weapons', 0.0}, {'Weapon Care', 0.0}},
        sell = {{'Scrap & Parts', 0.0}},
    },
    ---------------------------------
    -- Saint Denis Gunsmith
    ---------------------------------
    {
        id = 'stden_gunsmith',
        Doors = { 1057071735, 3283200993, 841127028 },
        label = 'Saint Denis Gunsmith',
        coords = vector4(2717.14, -1286.90, 49.64, 29.91),
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
        buy = {{'Ammunition', 0.0}, {'Weapons', 0.0}, {'Weapon Care', 0.0}},
        sell = {{'Scrap & Parts', 0.0}},
    },
    ---------------------------------
    -- Rhodes Gunsmith
    ---------------------------------
    {
        id = 'rho_gunsmith',
        Doors = { 393076024, 934926308, 743565308 },
        label = 'Rhodes Gunsmith',
        coords = vector4(1322.31, -1323.02, 77.89, 354.88),
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
        buy = {{'Ammunition', 0.0}, {'Weapons', 0.0}, {'Weapon Care', 0.0}},
        sell = {{'Scrap & Parts', 0.0}},
    },
    ---------------------------------
    -- Annesburg Gunsmith
    ---------------------------------
    {
        id = 'ann_gunsmith',
        Doors = { 2135900402, 3270231316, 1181665568 },
        label = 'Annesburg Gunsmith',
        coords = vector4(2948.42, 1319.44, 44.82, 79.11),
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
        buy = {{'Ammunition', 0.0}, {'Weapons', 0.0}, {'Weapon Care', 0.0}},
        sell = {{'Scrap & Parts', 0.0}},
    },
}
