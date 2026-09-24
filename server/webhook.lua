-- Lightweight Discord webhook logger for rsg-stores.
--
-- Every completed purchase/sale is queued here and sent to Config.Webhooks.url
-- one message at a time, so a burst of transactions (multiple players
-- checking out at once) can never trip Discord's per-webhook rate limit
-- (5 requests / 2 seconds). If no URL is configured this is a complete
-- no-op -- nothing is queued and no HTTP requests are ever made.
local webhookQueue = {}

local function isConfigured()
    return Config.Webhooks ~= nil and Config.Webhooks.url ~= nil and Config.Webhooks.url ~= ''
end

-- Queues a Discord embed (a plain table following Discord's embed object
-- shape: title/color/fields/footer/timestamp/etc) to be posted to the
-- configured webhook. Safe to call even when no webhook is configured.
function SendStoreWebhook(embed)
    if not isConfigured() or type(embed) ~= 'table' then return end
    webhookQueue[#webhookQueue + 1] = embed
end

CreateThread(function()
    while true do
        Wait(1500)

        if isConfigured() and #webhookQueue > 0 then
            local embed = table.remove(webhookQueue, 1)
            local payload = {
                username = Config.Webhooks.botName or 'RSG Stores',
                embeds = { embed },
            }

            if Config.Webhooks.botAvatar and Config.Webhooks.botAvatar ~= '' then
                payload.avatar_url = Config.Webhooks.botAvatar
            end

            PerformHttpRequest(Config.Webhooks.url, function(statusCode)
                -- Discord returns 204 No Content on a successful webhook post.
                if statusCode ~= 200 and statusCode ~= 204 then
                    print(('[rsg-stores] WARNING: Discord webhook post failed with status %s'):format(tostring(statusCode)))
                end
            end, 'POST', json.encode(payload), { ['Content-Type'] = 'application/json' })
        end
    end
end)
