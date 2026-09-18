--!strict
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Config = require(game.ReplicatedStorage.Shared.Config)
local World = {}
local function part(name, size, cf, color, parent, mat)
	local p = Instance.new("Part")
	p.Name = name p.Size = size p.CFrame = cf p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic
	p.Anchored = true p.Parent = parent
	return p
end
function World.build()
	for _, c in ipairs(Workspace:GetChildren()) do
		if c:IsA("BasePart") and (c.Name == "Baseplate" or c.Name == "SpawnLocation") then c:Destroy() end
	end
	local folder = Instance.new("Folder") folder.Name = "Harbor" folder.Parent = Workspace
	part("Water", Vector3.new(420, 2, 420), CFrame.new(0, -2, 0), Color3.fromRGB(20, 50, 80), folder, Enum.Material.Glass)
	part("Dock", Vector3.new(80, 2, 80), CFrame.new(0, 1, 0), Color3.fromRGB(70, 50, 30), folder, Enum.Material.Wood)
	local pier = part("Pier", Vector3.new(28, 1.5, 50), CFrame.new(0, 1.2, 40), Color3.fromRGB(90, 65, 40), folder, Enum.Material.Wood)
	local harvest = Instance.new("ProximityPrompt")
	harvest.Name = "HarvestPrompt" harvest.ActionText = "Harvest crate" harvest.HoldDuration = 0.35
	harvest.MaxActivationDistance = 14 harvest.RequiresLineOfSight = false harvest.Parent = pier
	local tower = part("BellTower", Vector3.new(8, 28, 8), CFrame.new(0, 15, -20), Color3.fromRGB(40, 40, 55), folder)
	part("Bell", Vector3.new(6, 3, 6), CFrame.new(0, 30, -20), Color3.fromRGB(210, 170, 40), folder, Enum.Material.Neon)
	local spawn = Instance.new("SpawnLocation")
	spawn.Size = Vector3.new(8, 1, 8) spawn.CFrame = CFrame.new(0, 3, -8) spawn.Anchored = true spawn.Duration = 0 spawn.Parent = folder
	Lighting.ClockTime = 17.5 Lighting.Brightness = 2
	Lighting.FogStart = 40 Lighting.FogEnd = 220 Lighting.FogColor = Color3.fromRGB(30, 40, 60)
	local stalls = Instance.new("Folder") stalls.Name = "Stalls" stalls.Parent = folder
	for i = 1, Config.MaxStalls do
		local a = ((i - 1) / Config.MaxStalls) * math.pi * 2
		local pos = Vector3.new(math.cos(a) * Config.RingRadius, 2, math.sin(a) * Config.RingRadius)
		local m = Instance.new("Model") m.Name = "Stall_" .. i m.Parent = stalls
		local floor = part("Floor", Vector3.new(16, 1, 16), CFrame.new(pos), Color3.fromRGB(50, 40, 35), m, Enum.Material.Wood)
		m.PrimaryPart = floor
		part("Counter", Vector3.new(10, 2, 2), CFrame.new(pos + Vector3.new(0, 1.5, 4)), Color3.fromRGB(90, 70, 50), m)
		local lamp = part("Lamp", Vector3.new(1, 1, 1), CFrame.new(pos + Vector3.new(0, 8, 0)), Color3.fromRGB(255, 200, 120), m, Enum.Material.Neon)
		local pl = Instance.new("PointLight") pl.Brightness = 2 pl.Range = 22 pl.Parent = lamp
		local bill = Instance.new("BillboardGui") bill.Size = UDim2.fromOffset(140, 28) bill.StudsOffset = Vector3.new(0, 6, 0) bill.AlwaysOnTop = true bill.Parent = floor
		local t = Instance.new("TextLabel") t.Name = "OwnerLabel" t.Size = UDim2.fromScale(1, 1) t.BackgroundTransparency = 1
		t.Text = "Empty stall" t.TextColor3 = Color3.new(1, 1, 1) t.Font = Enum.Font.GothamBold t.TextScaled = true t.Parent = bill
	end
	return folder
end
function World.setNight(on: boolean)
	Lighting.ClockTime = if on then 21.4 else 16.8
	Lighting.FogEnd = if on then 140 else 240
end
return World
