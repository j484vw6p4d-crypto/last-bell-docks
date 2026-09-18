--!strict
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Config = require(game.ReplicatedStorage.Shared.Config)

local World = {}

local KEEP = {
	Camera = true,
	Terrain = true,
}

local function part(name, size, cf, color, parent, mat)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = true
	p.Parent = parent
	return p
end

local function labelOn(adornee: BasePart, text: string, offset: Vector3, color: Color3?)
	local bill = Instance.new("BillboardGui")
	bill.Name = "Sign"
	bill.Size = UDim2.fromOffset(220, 36)
	bill.StudsOffset = offset
	bill.AlwaysOnTop = true
	bill.Parent = adornee
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = text
	t.TextColor3 = color or Color3.new(1, 1, 1)
	t.Font = Enum.Font.GothamBold
	t.TextScaled = true
	t.Parent = bill
	return t
end

function World.wipe()
	local ok, err = pcall(function()
		Workspace.Terrain:Clear()
	end)
	if not ok then
		warn("[Last Bell] Terrain:Clear failed", err)
	end
	for _, child in ipairs(Workspace:GetChildren()) do
		if not KEEP[child.Name] and not child:IsA("Terrain") and not child:IsA("Camera") then
			child:Destroy()
		end
	end
end

function World.build()
	World.wipe()

	local folder = Instance.new("Folder")
	folder.Name = "Harbor"
	folder.Parent = Workspace

	part("Water", Vector3.new(500, 4, 500), CFrame.new(0, -3, 0), Color3.fromRGB(18, 48, 78), folder, Enum.Material.Glass)
	part("Dock", Vector3.new(90, 2, 90), CFrame.new(0, 1, 0), Color3.fromRGB(72, 48, 28), folder, Enum.Material.Wood)

	local pier = part("Pier", Vector3.new(22, 1.6, 56), CFrame.new(0, 1.3, 48), Color3.fromRGB(96, 68, 38), folder, Enum.Material.Wood)
	labelOn(pier, "PIER — press E to harvest", Vector3.new(0, 8, 0), Color3.fromRGB(255, 220, 120))

	local crateAnchor = part("CratePile", Vector3.new(6, 3, 6), CFrame.new(0, 3.4, 62), Color3.fromRGB(160, 110, 60), folder, Enum.Material.Wood)
	labelOn(crateAnchor, "Cargo crates", Vector3.new(0, 4, 0), Color3.fromRGB(255, 240, 200))

	local harvest = Instance.new("ProximityPrompt")
	harvest.Name = "HarvestPrompt"
	harvest.ObjectText = "Pier cargo"
	harvest.ActionText = "Harvest crate (E)"
	harvest.HoldDuration = 0.25
	harvest.MaxActivationDistance = 16
	harvest.RequiresLineOfSight = false
	harvest.Parent = crateAnchor

	part("BellTower", Vector3.new(8, 28, 8), CFrame.new(0, 15, -22), Color3.fromRGB(42, 42, 58), folder)
	part("Bell", Vector3.new(6, 3, 6), CFrame.new(0, 30, -22), Color3.fromRGB(220, 180, 50), folder, Enum.Material.Neon)
	labelOn(workspace.Harbor.BellTower, "THE BELL", Vector3.new(0, 18, 0), Color3.fromRGB(255, 210, 80))

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "SpawnLocation"
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.CFrame = CFrame.new(0, 2.6, -6)
	spawn.Anchored = true
	spawn.Duration = 0
	spawn.Neutral = true
	spawn.Parent = folder

	Lighting.ClockTime = 16.8
	Lighting.Brightness = 2.2
	Lighting.FogStart = 60
	Lighting.FogEnd = 240
	Lighting.FogColor = Color3.fromRGB(30, 42, 62)
	Lighting.Ambient = Color3.fromRGB(70, 70, 90)
	Lighting.OutdoorAmbient = Color3.fromRGB(90, 90, 110)

	local stalls = Instance.new("Folder")
	stalls.Name = "Stalls"
	stalls.Parent = folder

	for i = 1, Config.MaxStalls do
		local a = ((i - 1) / Config.MaxStalls) * math.pi * 2
		local pos = Vector3.new(math.cos(a) * Config.RingRadius, 2, math.sin(a) * Config.RingRadius)
		local look = CFrame.new(pos, Vector3.new(0, 2, 0))
		local m = Instance.new("Model")
		m.Name = "Stall_" .. i
		m.Parent = stalls
		local floor = part("Floor", Vector3.new(16, 1, 16), look, Color3.fromRGB(52, 40, 32), m, Enum.Material.Wood)
		m.PrimaryPart = floor
		part("Counter", Vector3.new(10, 2, 2), look * CFrame.new(0, 1.5, 5), Color3.fromRGB(92, 70, 48), m, Enum.Material.Wood)
		local lamp = part("Lamp", Vector3.new(1.2, 1.2, 1.2), look * CFrame.new(0, 8, 0), Color3.fromRGB(255, 200, 120), m, Enum.Material.Neon)
		local pl = Instance.new("PointLight")
		pl.Brightness = 2
		pl.Range = 24
		pl.Parent = lamp
		local display = Instance.new("Folder")
		display.Name = "Display"
		display.Parent = m
		labelOn(floor, "Empty stall", Vector3.new(0, 6, 0), Color3.fromRGB(230, 230, 230))
	end

	return folder
end

function World.setNight(on: boolean)
	Lighting.ClockTime = if on then 21.5 else 16.8
	Lighting.FogEnd = if on then 130 else 250
	Lighting.Brightness = if on then 1.1 else 2.2
end

function World.setStallOwner(index: number, name: string)
	local stall = Workspace:FindFirstChild("Harbor") and Workspace.Harbor.Stalls:FindFirstChild("Stall_" .. index)
	if not stall then
		return
	end
	local floor = stall:FindFirstChild("Floor")
	local bill = floor and floor:FindFirstChild("Sign")
	local lab = bill and bill:FindFirstChildOfClass("TextLabel")
	if lab then
		lab.Text = name .. "'s stall"
	end
end

function World.refreshDisplay(index: number, kinds: { string })
	local stall = Workspace:FindFirstChild("Harbor") and Workspace.Harbor.Stalls:FindFirstChild("Stall_" .. index)
	if not stall then
		return
	end
	local folder = stall:FindFirstChild("Display")
	if not folder then
		return
	end
	folder:ClearAllChildren()
	local floor = stall.PrimaryPart
	if not floor then
		return
	end
	for i, kind in ipairs(kinds) do
		local color = Config.CrateColor[kind] or Color3.fromRGB(160, 110, 60)
		local box = Instance.new("Part")
		box.Name = kind
		box.Size = Vector3.new(2.4, 2.2, 2.4)
		box.Anchored = true
		box.CanCollide = false
		box.Color = color
		box.Material = Enum.Material.Wood
		box.CFrame = floor.CFrame * CFrame.new(-4 + (i - 1) * 2.8, 2.2, -2)
		box.Parent = folder
		labelOn(box, kind, Vector3.new(0, 2.2, 0), Color3.new(1, 1, 1))
	end
end

return World
