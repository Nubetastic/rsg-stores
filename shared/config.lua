Config = {}

-- Required permission to use the Blip/NPC menu
Config.AdminPermission = 'admin'

-- Create/upgrade the database tables automatically on resource start.
-- Set to false if you prefer to import rsg-stores.sql by hand.
Config.AutoInstallDatabase = true

--  NPC scenario
Config.DefaultScenario = 'WORLD_HUMAN_STAND_IMPATIENT'
Config.DistanceSpawn = 20.0  -- Distance before spawning/despawning the NPC (GTA Units)
Config.FadeIn = true         -- Enable fade in/out effect
Config.SellPricePercentage = 0.80  -- Player gets 80% (20% shop fee)
Config.SellAddsStock = true        -- Items sold to a shop are added back to its stock (limited-stock items only)
Config.MaxShopStock = 100          -- Most of any one item a shop will hold from player sales (0 = no cap)
Config.TargetDistance = 2.5       -- ox_target range; server allows +5.0 for latency


-- Labels are locale keys (locales/*.json), translated when the admin menu opens.
Config.BlipTypes = {
    { label = 'cfg_blip_coach', value = 1012165077 },
    { label = 'cfg_blip_corpse', value = -1116208957 },
    { label = 'cfg_blip_death', value = 350569997 },
    { label = 'cfg_blip_loan_shark', value = 1838354131 },
    { label = 'cfg_blip_newspaper', value = 587827268 },
    { label = 'cfg_blip_sheriff', value = -693644997 },
    { label = 'cfg_blip_animal', value = -1646261997 },
    { label = 'cfg_blip_camp', value = -910004446 },
    { label = 'cfg_blip_camp_fire', value = 773587962 },
    { label = 'cfg_blip_house', value = 1586273744 },
    { label = 'cfg_blip_bank', value = -2128054417 },
    { label = 'cfg_blip_magnify', value = 150441873 },
    { label = 'cfg_blip_hideout', value = -428972082 },
    { label = 'cfg_blip_saloon', value = 1879260108 },
    { label = 'cfg_blip_letter', value = -2100584570 },
    { label = 'cfg_blip_blacksmith', value = -758970771 },
    { label = 'cfg_blip_barber', value = -2090472724 },
    { label = 'cfg_blip_doctor', value = -1739686743 },
    { label = 'cfg_blip_gunsmith', value = -145868367 },
    { label = 'cfg_blip_stable', value = 1938782895 },
    { label = 'cfg_blip_market', value = 819673798 },
    { label = 'cfg_blip_fishing', value = -852241114 },
    { label = 'cfg_blip_food', value = -1852063472 },
    { label = 'cfg_blip_group', value = -180188163 },
    { label = 'cfg_blip_enemy', value = -507621590 },
    { label = 'cfg_blip_boat', value = -1018164873 },
    { label = 'cfg_blip_moonshine', value = -392465725 },
    { label = 'cfg_blip_wild_beast', value = -1085232344 },
    { label = 'cfg_blip_train', value = 1258184551 },
    { label = 'cfg_blip_mine', value = 1220803671 },
}

Config.NpcModels = {
    { label = 'cfg_model_rough_traveller', value = 'A_M_M_BiVRoughTravellers_01' },
    { label = 'cfg_model_blackwater_townfolk', value = 'A_M_M_BlWTownfolk_01' },
    { label = 'cfg_model_emerald_farmhand', value = 'A_M_M_EmRFarmHand_01' },
    { label = 'cfg_model_sd_dock_foreman', value = 'A_M_M_SDDockForeman_01' },
    { label = 'cfg_model_female_doctor', value = 'am_valentinedoctors_females_01' },
    { label = 'cfg_model_high_society', value = 'a_m_m_gamhighsociety_01' },
    { label = 'cfg_model_butler', value = 'cs_braithwaitebutler' },
    { label = 'cfg_model_elder_townfolk', value = 'a_m_o_waptownfolk_01' },
    { label = 'cfg_model_fish_vendor', value = 'cs_fishcollector' },
    { label = 'cfg_model_butcher', value = 'u_m_m_valbutcher_01' },
    { label = 'cfg_model_bartender', value = 'u_m_m_tumbartender_01' },
    { label = 'cfg_model_rhodes_owner', value = 'u_m_m_rhdgenstoreowner_02' },
    { label = 'cfg_model_strawberry_male', value = 'cr_strawberry_males_01' },
    { label = 'cfg_model_braithwaite_male', value = 'msp_braithwaites1_males_01' },
    { label = 'cfg_model_undertaker', value = 'u_m_m_rhdundertaker_01' }
}

Config.BlipColors = {
    { label = 'cfg_color_white', value = 'BLIP_MODIFIER_MP_COLOR_32' },
    { label = 'cfg_color_red', value = 'BLIP_MODIFIER_MP_COLOR_2' },
    { label = 'cfg_color_purple', value = 'BLIP_MODIFIER_MP_COLOR_3' },
    { label = 'cfg_color_orange', value = 'BLIP_MODIFIER_MP_COLOR_4' },
    { label = 'cfg_color_light_blue', value = 'BLIP_MODIFIER_MP_COLOR_5' },
    { label = 'cfg_color_yellow', value = 'BLIP_MODIFIER_MP_COLOR_6' },
    { label = 'cfg_color_pink', value = 'BLIP_MODIFIER_MP_COLOR_7' },
    { label = 'cfg_color_green', value = 'BLIP_MODIFIER_MP_COLOR_8' },
    { label = 'cfg_color_dark_blue', value = 'BLIP_MODIFIER_MP_COLOR_9' },
}
