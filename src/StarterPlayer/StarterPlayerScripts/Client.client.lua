--!strict
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

do
	if not workspace:FindFirstChild("ClientFloor") then
		local p = Instance.new("Part")
		p.Name = "ClientFloor"
		p.Size = Vector3.new(260, 10, 260)
		p.CFrame = CFrame.new(0, 4, 0)
		p.Anchored = true
		p.CanCollide = true
		p.Color = Color3.fromRGB(92, 62, 36)
		p.Material = Enum.Material.Wood
		p.Parent = workspace
	end
end

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
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = pg

local veil = Instance.new("Frame")
veil.Name = "NightVeil"
veil.BackgroundColor3 = Color3.fromRGB(8, 10, 28)
veil.BackgroundTransparency = 1
veil.BorderSizePixel = 0
veil.Size = UDim2.fromScale(1, 1)
veil.ZIndex = 0
veil.Parent = gui

local function corner(parent: Instance, r: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent = parent
end

local function stroke(parent: Instance, color: Color3, t: number)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = t
	s.Transparency = 0.35
	s.Parent = parent
end

local function panel(name: string, pos: UDim2, size: UDim2, parent: Instance): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.Position = pos
	f.Size = size
	f.BackgroundColor3 = Color3.fromRGB(12, 16, 28)
	f.BackgroundTransparency = 0.12
	f.BorderSizePixel = 0
	f.ZIndex = 2
	f.Parent = parent
	corner(f, 14)
	stroke(f, Color3.fromRGB(255, 196, 90), 1.2)
	return f
end

local function txt(name: string, parent: Instance, pos: UDim2, size: UDim2, text: string, color: Color3, textSize: number): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = name
	l.Position = pos
	l.Size = size
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextColor3 = color
	l.Font = Enum.Font.GothamBold
	l.TextSize = textSize
	l.ZIndex = 3
	l.Parent = parent
	return l
end

local top = panel("Top", UDim2.new(0.5, -190, 0, 14), UDim2.new(0, 380, 0, 86), gui)
txt("Title", top, UDim2.new(0, 16, 0, 8), UDim2.new(1, -32, 0, 28), "LAST BELL", Color3.fromRGB(255, 214, 110), 22)
local phaseLbl = txt("Phase", top, UDim2.new(0, 16, 0, 38), UDim2.new(0.4, 0, 0, 36), "DAY", Color3.fromRGB(140, 255, 170), 20)
local toast = txt("Toast", top, UDim2.new(0.38, 0, 0, 38), UDim2.new(0.6, -16, 0, 36), "Walk to the PIER  ·  press E", Color3.fromRGB(235, 235, 245), 15)
toast.TextXAlignment = Enum.TextXAlignment.Right
toast.TextWrapped = true

local left = panel("Wallet", UDim2.new(0, 18, 1, -118), UDim2.new(0, 280, 0, 96), gui)
local coinsLbl = txt("Coins", left, UDim2.new(0, 16, 0, 10), UDim2.new(1, -32, 0, 32), "0 coins", Color3.fromRGB(255, 214, 110), 24)
coinsLbl.TextXAlignment = Enum.TextXAlignment.Left
local carryLbl = txt("Carry", left, UDim2.new(0, 16, 0, 42), UDim2.new(1, -32, 0, 22), "Carry  ·  empty", Color3.fromRGB(210, 210, 220), 16)
carryLbl.TextXAlignment = Enum.TextXAlignment.Left
local stockLbl = txt("Stock", left, UDim2.new(0, 16, 0, 64), UDim2.new(1, -32, 0, 22), "Stall  ·  0 stocked", Color3.fromRGB(210, 210, 220), 16)
stockLbl.TextXAlignment = Enum.TextXAlignment.Left

local keys = panel("Keys", UDim2.new(1, -338, 1, -78), UDim2.new(0, 320, 0, 56), gui)
txt("KeyLine", keys, UDim2.new(0, 10, 0, 8), UDim2.new(1, -20, 1, -16), "E harvest   F stock   Q sell   R steal   P rebirth", Color3.fromRGB(230, 230, 240), 14)

local stickyUntil = 0
local lastPayload: any = nil

local function objectiveFrom(payload: any): string
	local ph = tostring(payload.phase or "Day")
	if ph == "Night" then
		return "Night  ·  R at another stall"
	elseif ph == "Bell" then
		return "Bell  ·  night incoming"
	elseif payload.carried then
		return "F at YOUR stall"
	elseif (payload.display or 0) > 0 then
		return "Q to sell to the buyer"
	elseif (payload.coins or 0) >= (payload.need or 500) then
		return "P at the bell to rebirth"
	end
	return "Walk to the PIER  ·  press E"
end

Remotes.get("Notify").OnClientEvent:Connect(function(text)
	if typeof(text) == "string" then
		toast.Text = text
		stickyUntil = os.clock() + 4
	end
end)

Remotes.get("Phase").OnClientEvent:Connect(function(ph)
	phaseLbl.Text = string.upper(tostring(ph))
	if ph == "Night" then
		phaseLbl.TextColor3 = Color3.fromRGB(255, 120, 130)
		veil.BackgroundTransparency = 0.58
	elseif ph == "Bell" then
		phaseLbl.TextColor3 = Color3.fromRGB(255, 220, 80)
		veil.BackgroundTransparency = 0.78
	else
		phaseLbl.TextColor3 = Color3.fromRGB(140, 255, 170)
		veil.BackgroundTransparency = 1
	end
end)

Remotes.get("Stats").OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "table" then
		return
	end
	lastPayload = payload
	coinsLbl.Text = tostring(payload.coins or 0) .. " coins"
	carryLbl.Text = "Carry  ·  " .. tostring(payload.carried or "empty")
	stockLbl.Text = "Stall  ·  " .. tostring(payload.display or 0) .. " stocked"
	if os.clock() >= stickyUntil then
		toast.Text = objectiveFrom(payload)
	end
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

task.spawn(function()
	while true do
		task.wait(1)
		if lastPayload and os.clock() >= stickyUntil then
			toast.Text = objectiveFrom(lastPayload)
		end
	end
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
