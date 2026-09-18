--!strict
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Config = require(RS:WaitForChild("Shared"):WaitForChild("Config"))
local Remotes = require(RS.Shared.Remotes)

local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

local old = pg:FindFirstChild("LastBellHUD")
if old then
	old:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "LastBellHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = pg

local function label(name, pos, size, text, color)
	local l = Instance.new("TextLabel")
	l.Name = name
	l.Position = pos
	l.Size = size
	l.Text = text
	l.BackgroundColor3 = Color3.fromRGB(16, 18, 28)
	l.BackgroundTransparency = 0.15
	l.TextColor3 = color or Color3.new(1, 1, 1)
	l.Font = Enum.Font.GothamBold
	l.TextSize = 16
	l.Parent = gui
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = l
	return l
end

label("Title", UDim2.new(0.5, -170, 0, 16), UDim2.new(0, 340, 0, 40), "🔔 Last Bell", Color3.fromRGB(255, 220, 120)).TextSize = 22
local phaseLbl = label("Phase", UDim2.new(0.5, -90, 0, 62), UDim2.new(0, 180, 0, 32), "DAY", Color3.fromRGB(180, 255, 180))
local stats = label("Stats", UDim2.new(0, 16, 1, -92), UDim2.new(0, 280, 0, 40), "Coins 0  |  Carry none")
local hint = label("Hint", UDim2.new(1, -430, 1, -52), UDim2.new(0, 414, 0, 36), "E harvest   F stock   Q sell (day)   R steal (night)   P rebirth")
hint.TextSize = 14
local toast = label("Toast", UDim2.new(0.5, -200, 0, 104), UDim2.new(0, 400, 0, 36), "Walk to the PIER and press E")

Remotes.get("Notify").OnClientEvent:Connect(function(text)
	if typeof(text) == "string" then
		toast.Text = text
	end
end)
Remotes.get("Phase").OnClientEvent:Connect(function(ph)
	phaseLbl.Text = string.upper(tostring(ph))
	if ph == "Night" then
		phaseLbl.TextColor3 = Color3.fromRGB(255, 120, 120)
	elseif ph == "Bell" then
		phaseLbl.TextColor3 = Color3.fromRGB(255, 220, 80)
	else
		phaseLbl.TextColor3 = Color3.fromRGB(180, 255, 180)
	end
end)
Remotes.get("Stats").OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "table" then
		return
	end
	stats.Text = string.format(
		"Coins %s   Carry %s   Stock %s   RB %s",
		tostring(payload.coins),
		tostring(payload.carried or "none"),
		tostring(payload.display),
		tostring(payload.rebirths)
	)
end)
Remotes.get("PlaySound").OnClientEvent:Connect(function(key)
	local id = Config.Sounds[key]
	if typeof(id) ~= "string" then
		return
	end
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = 0.65
	s.Parent = SoundService
	s:Play()
	game:GetService("Debris"):AddItem(s, 3)
end)

UIS.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	local k = input.KeyCode
	if k == Enum.KeyCode.E then
		Remotes.get("Harvest"):FireServer()
	elseif k == Enum.KeyCode.F then
		Remotes.get("StockStall"):FireServer()
	elseif k == Enum.KeyCode.Q then
		Remotes.get("Sell"):FireServer()
	elseif k == Enum.KeyCode.R then
		Remotes.get("Steal"):FireServer()
	elseif k == Enum.KeyCode.P then
		Remotes.get("Rebirth"):FireServer()
	end
end)
