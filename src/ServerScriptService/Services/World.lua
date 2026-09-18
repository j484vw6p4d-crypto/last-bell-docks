--!strict
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))

local World = {}

-- Harbor sits above leftover grass if terrain wipe is slow.
local DOCK_Y = 12

local function part(name: string, size: Vector3, cf: CFrame, color: Color3, parent: Instance, mat: Enum.Material?): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Locked = false
	p.Parent = parent
	return p
end

local function labelOn(adornee: BasePart, text: string, offset: Vector3, color: Color3?): TextLabel
	local old = adornee:FindFirstChild("Sign")
	if old then
		old:Destroy()
	end
	local bill = Instance.new("BillboardGui")
	bill.Name = "Sign"
	bill.Size = UDim2.fromOffset(280, 42)
	bill.StudsOffset = offset
	bill.AlwaysOnTop = true
	bill.MaxDistance = 140
	bill.LightInfluence = 0
	bill.Parent = adornee
	local t = Instance.new("TextLabel")
	t.Name = "Text"
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = text
	t.TextColor3 = color or Color3.new(1, 1, 1)
	t.Font = Enum.Font.GothamBold
	t.TextScaled = true
	t.Parent = bill
	return t
end

local function keepInstance(inst: Instance): boolean
	if inst:IsA("Camera") or inst:IsA("Terrain") then
		return true
	end
	if inst.Name == "Harbor" then
		return true
	end
	-- Only keep real players. Leftover map kits often have dummy Humanoids.
	if Players:GetPlayerFromCharacter(inst) ~= nil then
		return true
	end
	return false
end

local function destroyLeftover(inst: Instance)
	if keepInstance(inst) then
		return
	end
	pcall(function()
		inst.Locked = false
	end)
	pcall(function()
		inst:Destroy()
	end)
end

local function clearTerrain()
	pcall(function()
		Workspace.StreamingEnabled = false
	end)
	local terrain = Workspace.Terrain
	pcall(function()
		terrain.Decoration = false
	end)
	pcall(function()
		terrain:Clear()
	end)
	-- Chunked air fill. One giant FillBlock exceeds Roblox's voxel cap and used to abort the wipe.
	local size = 64
	for x = -384, 384, size do
		for z = -384, 384, size do
			pcall(function()
				terrain:FillBlock(CFrame.new(x, 48, z), Vector3.new(size, 192, size), Enum.Material.Air)
			end)
		end
	end
	pcall(function()
		terrain:FillBlock(CFrame.new(0, -6, 0), Vector3.new(400, 12, 400), Enum.Material.Water)
	end)
end

function World.wipe()
	print("[Last Bell] Wiping leftover map")
	clearTerrain()

	local oldHarbor = Workspace:FindFirstChild("Harbor")
	if oldHarbor then
		pcall(function()
			oldHarbor:Destroy()
		end)
	end

	for _ = 1, 3 do
		for _, child in ipairs(Workspace:GetChildren()) do
			destroyLeftover(child)
		end
	end

	for _, child in ipairs(Lighting:GetChildren()) do
		pcall(function()
			child:Destroy()
		end)
	end

	for _, child in ipairs(game:GetService("StarterPack"):GetChildren()) do
		pcall(function()
			child:Destroy()
		end)
	end

	pcall(function()
		for _, child in ipairs(game:GetService("ServerStorage"):GetChildren()) do
			child:Destroy()
		end
	end)
end

function World.guardLeftovers()
	for _, child in ipairs(Workspace:GetChildren()) do
		destroyLeftover(child)
	end
	local deadline = os.clock() + 12
	local conn: RBXScriptConnection? = nil
	conn = Workspace.ChildAdded:Connect(function(child)
		task.delay(0.5, function()
			if os.clock() > deadline then
				if conn then
					conn:Disconnect()
				end
				return
			end
			if child.Parent == nil then
				return
			end
			destroyLeftover(child)
		end)
	end)
	task.delay(1, function()
		clearTerrain()
		for _, child in ipairs(Workspace:GetChildren()) do
			destroyLeftover(child)
		end
	end)
end

local function applySky()
	local sky = Instance.new("Sky")
	sky.Name = "HarborSky"
	sky.CelestialBodiesShown = true
	sky.StarCount = 3000
	sky.Parent = Lighting

	local atm = Instance.new("Atmosphere")
	atm.Name = "HarborFog"
	atm.Density = 0.48
	atm.Offset = 0.1
	atm.Color = Color3.fromRGB(72, 92, 118)
	atm.Decay = Color3.fromRGB(28, 36, 52)
	atm.Glare = 0.12
	atm.Haze = 2
	atm.Parent = Lighting

	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "HarborColor"
	cc.Saturation = 0.06
	cc.Contrast = 0.04
	cc.Parent = Lighting
end

function World.build()
	World.wipe()

	local folder = Instance.new("Folder")
	folder.Name = "Harbor"
	folder.Parent = Workspace

	applySky()

	local water = part("Water", Vector3.new(900, 10, 900), CFrame.new(0, DOCK_Y - 8, 0), Color3.fromRGB(16, 46, 78), folder, Enum.Material.Glass)
	water.Transparency = 0.35

	-- Flat wood deck (no cylinder — Shape changes were a crash risk).
	part("Dock", Vector3.new(260, 6, 260), CFrame.new(0, DOCK_Y, 0), Color3.fromRGB(92, 62, 36), folder, Enum.Material.Wood)

	local pier = part("Pier", Vector3.new(20, 2, 80), CFrame.new(0, DOCK_Y + 1, 150), Color3.fromRGB(112, 78, 44), folder, Enum.Material.Wood)
	labelOn(pier, "PIER — press E to harvest", Vector3.new(0, 9, 0), Color3.fromRGB(255, 220, 120))

	for i = -1, 1, 2 do
		part("PierRail", Vector3.new(0.6, 2.6, 80), CFrame.new(i * 10, DOCK_Y + 2.8, 150), Color3.fromRGB(72, 50, 30), folder, Enum.Material.Wood)
	end

	local crateAnchor = part("CratePile", Vector3.new(8, 1, 8), CFrame.new(0, DOCK_Y + 2.2, 180), Color3.fromRGB(70, 48, 28), folder, Enum.Material.Wood)
	labelOn(crateAnchor, "CARGO — E harvest", Vector3.new(0, 8, 0), Color3.fromRGB(255, 240, 180))

	local harvest = Instance.new("ProximityPrompt")
	harvest.Name = "HarvestPrompt"
	harvest.ObjectText = "Pier cargo"
	harvest.ActionText = "Harvest crate"
	harvest.HoldDuration = 0.2
	harvest.MaxActivationDistance = 18
	harvest.RequiresLineOfSight = false
	harvest.KeyboardKeyCode = Enum.KeyCode.E
	harvest.Parent = crateAnchor

	local pierCrates = Instance.new("Folder")
	pierCrates.Name = "PierCrates"
	pierCrates.Parent = folder
	local offsets = {
		Vector3.new(-2.2, 1.4, -2),
		Vector3.new(2.2, 1.4, -2),
		Vector3.new(-2.2, 1.4, 2),
		Vector3.new(2.2, 1.4, 2),
		Vector3.new(0, 3.4, 0),
		Vector3.new(0, 1.4, 0),
	}
	for i, off in ipairs(offsets) do
		local box = part("Crate_" .. i, Vector3.new(2.6, 2.2, 2.6), crateAnchor.CFrame * CFrame.new(off), Color3.fromRGB(168, 118, 64), pierCrates, Enum.Material.Wood)
		box.CanCollide = false
		box:SetAttribute("FullSizeX", 2.6)
		box:SetAttribute("FullSizeY", 2.2)
		box:SetAttribute("FullSizeZ", 2.6)
	end

	part("TowerBase", Vector3.new(16, 2, 16), CFrame.new(0, DOCK_Y + 4, 0), Color3.fromRGB(48, 48, 62), folder)
	part("BellTower", Vector3.new(8, 30, 8), CFrame.new(0, DOCK_Y + 19, 0), Color3.fromRGB(42, 42, 58), folder)
	part("TowerCap", Vector3.new(12, 2, 12), CFrame.new(0, DOCK_Y + 35, 0), Color3.fromRGB(36, 36, 50), folder)
	local bell = part("Bell", Vector3.new(7, 4, 7), CFrame.new(0, DOCK_Y + 32, 0), Color3.fromRGB(228, 186, 52), folder, Enum.Material.Neon)
	labelOn(bell, "THE BELL  -  P rebirth at 500", Vector3.new(0, 8, 0), Color3.fromRGB(255, 220, 90))

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "SpawnLocation"
	spawn.Size = Vector3.new(14, 1, 14)
	spawn.CFrame = CFrame.new(0, DOCK_Y + 4, 18)
	spawn.Anchored = true
	spawn.Duration = 0
	spawn.Neutral = true
	spawn.BrickColor = BrickColor.new("Dark orange")
	spawn.Parent = folder

	local stalls = Instance.new("Folder")
	stalls.Name = "Stalls"
	stalls.Parent = folder

	local stallY = DOCK_Y + 3.5
	for i = 1, Config.MaxStalls do
		local a = ((i - 1) / Config.MaxStalls) * math.pi * 2
		local pos = Vector3.new(math.cos(a) * Config.RingRadius, stallY, math.sin(a) * Config.RingRadius)
		local look = CFrame.new(pos, Vector3.new(0, stallY, 0))
		local m = Instance.new("Model")
		m.Name = "Stall_" .. i
		m.Parent = stalls
		local floor = part("Floor", Vector3.new(16, 1, 16), look, Color3.fromRGB(58, 42, 30), m, Enum.Material.Wood)
		m.PrimaryPart = floor
		part("Back", Vector3.new(16, 8, 0.7), look * CFrame.new(0, 4.5, 7.6), Color3.fromRGB(86, 60, 38), m, Enum.Material.Wood)
		part("Roof", Vector3.new(17, 0.7, 17), look * CFrame.new(0, 9.2, 0), Color3.fromRGB(72, 48, 30), m, Enum.Material.Wood)
		part("Counter", Vector3.new(10, 2, 2.2), look * CFrame.new(0, 1.6, -6.2), Color3.fromRGB(110, 82, 52), m, Enum.Material.Wood)
		local lamp = part("Lamp", Vector3.new(1.4, 1.4, 1.4), look * CFrame.new(0, 8.2, 0), Color3.fromRGB(255, 210, 130), m, Enum.Material.Neon)
		local pl = Instance.new("PointLight")
		pl.Name = "StallLight"
		pl.Brightness = 1.6
		pl.Range = 28
		pl.Color = Color3.fromRGB(255, 210, 140)
		pl.Parent = lamp
		local display = Instance.new("Folder")
		display.Name = "Display"
		display.Parent = m
		labelOn(floor, "Empty stall", Vector3.new(0, 7, 0), Color3.fromRGB(230, 230, 230))
	end

	World.setNight(false)
	print("[Last Bell] Harbor built")
	return folder
end

function World.setNight(on: boolean)
	Lighting.ClockTime = if on then 0.4 else 16.6
	Lighting.Brightness = if on then 0.4 else 2.4
	Lighting.FogStart = if on then 20 else 30
	Lighting.FogEnd = if on then 90 else 140
	Lighting.FogColor = if on then Color3.fromRGB(8, 10, 22) else Color3.fromRGB(70, 92, 118)
	Lighting.Ambient = if on then Color3.fromRGB(18, 20, 32) else Color3.fromRGB(78, 72, 68)
	Lighting.OutdoorAmbient = if on then Color3.fromRGB(22, 26, 42) else Color3.fromRGB(118, 108, 96)
	Lighting.ColorShift_Top = if on then Color3.fromRGB(40, 50, 90) else Color3.fromRGB(255, 210, 160)

	local atm = Lighting:FindFirstChild("HarborFog")
	if atm and atm:IsA("Atmosphere") then
		atm.Density = if on then 0.58 else 0.45
		atm.Haze = if on then 2.4 else 1.8
		atm.Color = if on then Color3.fromRGB(20, 24, 40) else Color3.fromRGB(72, 92, 118)
	end

	local harbor = Workspace:FindFirstChild("Harbor")
	if not harbor then
		return
	end
	local stalls = harbor:FindFirstChild("Stalls")
	if not stalls then
		return
	end
	for _, stall in ipairs(stalls:GetChildren()) do
		local lamp = stall:FindFirstChild("Lamp")
		local light = lamp and lamp:FindFirstChild("StallLight")
		if light and light:IsA("PointLight") then
			light.Brightness = if on then 3.4 else 1.4
			light.Range = if on then 36 else 24
		end
		if lamp and lamp:IsA("BasePart") then
			lamp.Color = if on then Color3.fromRGB(255, 170, 80) else Color3.fromRGB(255, 210, 130)
		end
	end
end

function World.setStallOwner(index: number, name: string)
	local harbor = Workspace:FindFirstChild("Harbor")
	local stalls = harbor and harbor:FindFirstChild("Stalls")
	local stall = stalls and stalls:FindFirstChild("Stall_" .. index)
	if not stall then
		return
	end
	local floor = stall:FindFirstChild("Floor")
	if floor and floor:IsA("BasePart") then
		labelOn(floor, name, Vector3.new(0, 7, 0), Color3.fromRGB(255, 230, 180))
	end
end

function World.refreshDisplay(index: number, kinds: { string })
	local harbor = Workspace:FindFirstChild("Harbor")
	local stalls = harbor and harbor:FindFirstChild("Stalls")
	local stall = stalls and stalls:FindFirstChild("Stall_" .. index)
	if not stall then
		return
	end
	local folder = stall:FindFirstChild("Display")
	if not folder then
		return
	end
	folder:ClearAllChildren()
	local floor = stall:FindFirstChild("Floor") :: BasePart?
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
		box.CFrame = floor.CFrame * CFrame.new(-4 + (i - 1) * 2.8, 2.4, 1)
		box.Parent = folder
		labelOn(box, kind, Vector3.new(0, 2.2, 0), Color3.new(1, 1, 1))
	end
end

function World.setBuyer(index: number, visible: boolean)
	local harbor = Workspace:FindFirstChild("Harbor")
	local stalls = harbor and harbor:FindFirstChild("Stalls")
	local stall = stalls and stalls:FindFirstChild("Stall_" .. index)
	if not stall then
		return
	end
	local old = stall:FindFirstChild("Buyer")
	if old then
		old:Destroy()
	end
	if not visible then
		return
	end
	local floor = stall:FindFirstChild("Floor") :: BasePart?
	if not floor then
		return
	end
	local buyer = part("Buyer", Vector3.new(2.2, 5.2, 2.2), floor.CFrame * CFrame.new(5.2, 3.4, -4.5), Color3.fromRGB(255, 196, 64), stall, Enum.Material.Neon)
	buyer.CanCollide = false
	labelOn(buyer, "BUYER — press Q to sell", Vector3.new(0, 4.2, 0), Color3.fromRGB(255, 230, 120))
end

function World.setPierGrown(count: number)
	local harbor = Workspace:FindFirstChild("Harbor")
	local folder = harbor and harbor:FindFirstChild("PierCrates")
	if not folder then
		return
	end
	local kids = folder:GetChildren()
	table.sort(kids, function(a, b)
		return a.Name < b.Name
	end)
	for i, child in ipairs(kids) do
		if child:IsA("BasePart") then
			local on = i <= count
			child.Transparency = if on then 0 else 0.75
			local fx = child:GetAttribute("FullSizeX")
			local fy = child:GetAttribute("FullSizeY")
			local fz = child:GetAttribute("FullSizeZ")
			if typeof(fx) == "number" and typeof(fy) == "number" and typeof(fz) == "number" then
				child.Size = if on then Vector3.new(fx, fy, fz) else Vector3.new(1.1, 1.1, 1.1)
			end
		end
	end
	local pile = harbor and harbor:FindFirstChild("CratePile")
	if pile and pile:IsA("BasePart") then
		local sign = pile:FindFirstChild("Sign")
		local lab = sign and sign:FindFirstChild("Text")
		if lab and lab:IsA("TextLabel") then
			if count > 0 then
				lab.Text = "CARGO x" .. count .. " — E harvest"
			else
				lab.Text = "Unloading... wait for crates"
			end
		end
	end
end

function World.attachCarry(player: Player, kind: string?)
	local char = player.Character
	if not char then
		return
	end
	local old = char:FindFirstChild("CarriedCrate")
	if old then
		old:Destroy()
	end
	if not kind then
		return
	end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end
	local box = Instance.new("Part")
	box.Name = "CarriedCrate"
	box.Size = Vector3.new(1.8, 1.6, 1.8)
	box.Color = Config.CrateColor[kind] or Color3.fromRGB(160, 110, 60)
	box.Material = Enum.Material.Wood
	box.Massless = true
	box.CanCollide = false
	box.Anchored = false
	box.CFrame = hrp.CFrame * CFrame.new(0, 2.1, -1.5)
	box.Parent = char
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = hrp
	weld.Part1 = box
	weld.Parent = box
	labelOn(box, kind, Vector3.new(0, 1.5, 0), Color3.new(1, 1, 1))
end

function World.floatText(at: Vector3, text: string, color: Color3)
	local harbor = Workspace:FindFirstChild("Harbor")
	if not harbor then
		return
	end
	local p = Instance.new("Part")
	p.Name = "FloatText"
	p.Anchored = true
	p.CanCollide = false
	p.Transparency = 1
	p.Size = Vector3.new(1, 1, 1)
	p.Position = at + Vector3.new(0, 6, 0)
	p.Parent = harbor
	labelOn(p, text, Vector3.new(0, 0, 0), color)
	task.spawn(function()
		for _ = 1, 14 do
			p.Position = p.Position + Vector3.new(0, 0.32, 0)
			task.wait(0.07)
		end
		p:Destroy()
	end)
end

function World.ringBell()
	local harbor = Workspace:FindFirstChild("Harbor")
	local bell = harbor and harbor:FindFirstChild("Bell")
	if not (bell and bell:IsA("BasePart")) then
		return
	end
	local orig = bell.Color
	task.spawn(function()
		for _ = 1, 6 do
			bell.Color = Color3.fromRGB(255, 255, 140)
			task.wait(0.16)
			bell.Color = orig
			task.wait(0.16)
		end
	end)
end

return World
