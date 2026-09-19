--!strict
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
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

local function labelOn(adornee: BasePart, text: string, offset: Vector3, color: Color3?, size: Vector2?): TextLabel
	local old = adornee:FindFirstChild("Sign")
	if old then
		old:Destroy()
	end
	local bill = Instance.new("BillboardGui")
	bill.Name = "Sign"
	bill.Size = UDim2.fromOffset((size and size.X) or 220, (size and size.Y) or 34)
	bill.StudsOffset = offset
	bill.AlwaysOnTop = true
	bill.MaxDistance = 90
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
		inst.Archivable = true
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

	-- Destroying a top-level child cascades to everything nested
	-- inside it, so this doesn't need to walk descendants — but old
	-- template content can insert itself back in mid-clear (Toolbox
	-- syncs, default "Tutorial" scripts firing late), hence 3 passes.
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

	-- Default template screens (the "Welcome, find 7 hidden items!"
	-- card) sometimes ship as a StarterGui ScreenGui rather than a
	-- 3D part. Clear those too so nothing prototype-looking survives
	-- into a fresh character's PlayerGui.
	pcall(function()
		for _, child in ipairs(game:GetService("StarterGui"):GetChildren()) do
			if child.Name ~= "LoadingScreen" then
				child:Destroy()
			end
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
	sky.StarCount = 4500
	sky.Parent = Lighting

	local atm = Instance.new("Atmosphere")
	atm.Name = "HarborFog"
	atm.Density = 0.5
	atm.Offset = 0.1
	atm.Color = Color3.fromRGB(66, 86, 112)
	atm.Decay = Color3.fromRGB(20, 26, 40)
	atm.Glare = 0.1
	atm.Haze = 2.4
	atm.Parent = Lighting

	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "HarborColor"
	cc.Saturation = -0.08
	cc.Contrast = 0.1
	cc.TintColor = Color3.fromRGB(230, 235, 245)
	cc.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Name = "HarborBloom"
	bloom.Intensity = 0.6
	bloom.Size = 24
	bloom.Threshold = 1.4
	bloom.Parent = Lighting

	local rays = Instance.new("SunRaysEffect")
	rays.Name = "HarborRays"
	rays.Intensity = 0.15
	rays.Spread = 0.5
	rays.Parent = Lighting

	local dof = Instance.new("DepthOfFieldEffect")
	dof.Name = "HarborDepth"
	dof.FarIntensity = 0.25
	dof.FocusDistance = 40
	dof.InFocusRadius = 30
	dof.NearIntensity = 0
	dof.Parent = Lighting
end

function World.build()
	World.wipe()

	local folder = Instance.new("Folder")
	folder.Name = "Harbor"
	folder.Parent = Workspace

	applySky()

	local water = part("Water", Vector3.new(900, 10, 900), CFrame.new(0, DOCK_Y - 8, 0), Color3.fromRGB(10, 30, 52), folder, Enum.Material.Glass)
	water.Transparency = 0.3

	part("Dock", Vector3.new(260, 6, 260), CFrame.new(0, DOCK_Y, 0), Color3.fromRGB(70, 48, 30), folder, Enum.Material.Wood)

	local pier = part("Pier", Vector3.new(20, 2, 80), CFrame.new(0, DOCK_Y + 1, 150), Color3.fromRGB(86, 60, 36), folder, Enum.Material.Wood)
	pier.Name = "Pier"

	for i = -1, 1, 2 do
		part("PierRail", Vector3.new(0.6, 2.6, 80), CFrame.new(i * 10, DOCK_Y + 2.8, 150), Color3.fromRGB(52, 38, 24), folder, Enum.Material.Wood)
	end

	local crateAnchor = part("CratePile", Vector3.new(8, 1, 8), CFrame.new(0, DOCK_Y + 2.2, 180), Color3.fromRGB(56, 40, 24), folder, Enum.Material.Wood)

	local harvest = Instance.new("ProximityPrompt")
	harvest.Name = "HarvestPrompt"
	harvest.ObjectText = "Cargo"
	harvest.ActionText = "Harvest"
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
		local box = part("Crate_" .. i, Vector3.new(2.6, 2.2, 2.6), crateAnchor.CFrame * CFrame.new(off), Color3.fromRGB(140, 96, 52), pierCrates, Enum.Material.Wood)
		box.CanCollide = false
		box:SetAttribute("FullSizeX", 2.6)
		box:SetAttribute("FullSizeY", 2.2)
		box:SetAttribute("FullSizeZ", 2.6)
	end

	part("TowerBase", Vector3.new(16, 2, 16), CFrame.new(0, DOCK_Y + 4, 0), Color3.fromRGB(30, 30, 38), folder)
	part("BellTower", Vector3.new(8, 30, 8), CFrame.new(0, DOCK_Y + 19, 0), Color3.fromRGB(26, 26, 34), folder)
	part("TowerCap", Vector3.new(12, 2, 12), CFrame.new(0, DOCK_Y + 35, 0), Color3.fromRGB(22, 22, 30), folder)
	local bell = part("Bell", Vector3.new(7, 4, 7), CFrame.new(0, DOCK_Y + 32, 0), Color3.fromRGB(200, 160, 60), folder, Enum.Material.Metal)
	labelOn(bell, "THE LAST BELL", Vector3.new(0, 8, 0), Color3.fromRGB(230, 190, 90), Vector2.new(200, 30))

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "SpawnLocation"
	spawn.Size = Vector3.new(14, 1, 14)
	spawn.CFrame = CFrame.new(0, DOCK_Y + 4, 18)
	spawn.Anchored = true
	spawn.Duration = 0
	spawn.Neutral = true
	spawn.Transparency = 1
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
		local floor = part("Floor", Vector3.new(16, 1, 16), look, Color3.fromRGB(44, 32, 22), m, Enum.Material.Wood)
		m.PrimaryPart = floor
		part("Back", Vector3.new(16, 8, 0.7), look * CFrame.new(0, 4.5, 7.6), Color3.fromRGB(58, 42, 26), m, Enum.Material.Wood)
		part("Roof", Vector3.new(17, 0.7, 17), look * CFrame.new(0, 9.2, 0), Color3.fromRGB(48, 34, 22), m, Enum.Material.Wood)
		part("Counter", Vector3.new(10, 2, 2.2), look * CFrame.new(0, 1.6, -6.2), Color3.fromRGB(74, 54, 34), m, Enum.Material.Wood)
		local lamp = part("Lamp", Vector3.new(1.2, 1.2, 1.2), look * CFrame.new(0, 8.2, 0), Color3.fromRGB(255, 200, 120), m, Enum.Material.Neon)
		local pl = Instance.new("PointLight")
		pl.Name = "StallLight"
		pl.Brightness = 1.4
		pl.Range = 24
		pl.Color = Color3.fromRGB(255, 190, 120)
		pl.Parent = lamp
		local display = Instance.new("Folder")
		display.Name = "Display"
		display.Parent = m
		labelOn(floor, "Empty stall", Vector3.new(0, 7, 0), Color3.fromRGB(190, 190, 190), Vector2.new(180, 26))
	end

	World.setNight(false)
	print("[Last Bell] Harbor built")
	return folder
end

function World.setNight(on: boolean)
	Lighting.ClockTime = if on then 0.2 else 16.6
	Lighting.Brightness = if on then 0.25 else 2.2
	Lighting.FogStart = if on then 8 else 30
	Lighting.FogEnd = if on then 70 else 140
	Lighting.FogColor = if on then Color3.fromRGB(4, 5, 10) else Color3.fromRGB(64, 84, 108)
	Lighting.Ambient = if on then Color3.fromRGB(8, 9, 16) else Color3.fromRGB(72, 66, 62)
	Lighting.OutdoorAmbient = if on then Color3.fromRGB(10, 12, 20) else Color3.fromRGB(110, 100, 90)
	Lighting.ColorShift_Top = if on then Color3.fromRGB(20, 24, 46) else Color3.fromRGB(255, 205, 155)

	local atm = Lighting:FindFirstChild("HarborFog")
	if atm and atm:IsA("Atmosphere") then
		atm.Density = if on then 0.68 else 0.48
		atm.Haze = if on then 3.2 else 2.2
		atm.Color = if on then Color3.fromRGB(10, 11, 18) else Color3.fromRGB(66, 86, 112)
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
			light.Brightness = if on then 2.6 else 1.2
			light.Range = if on then 30 else 20
		end
		if lamp and lamp:IsA("BasePart") then
			lamp.Color = if on then Color3.fromRGB(255, 140, 70) else Color3.fromRGB(255, 200, 120)
		end
	end

	-- flickering lamps at night for a bit of horror atmosphere
	if on then
		for _, stall in ipairs(stalls:GetChildren()) do
			local lamp = stall:FindFirstChild("Lamp")
			local light = lamp and lamp:FindFirstChild("StallLight")
			if light and light:IsA("PointLight") then
				task.spawn(function()
					local baseBrightness = light.Brightness
					while light and light.Parent and Lighting.ClockTime < 6 do
						local n = math.noise(os.clock() * 3, stall:GetAttribute("Seed") or 0)
						light.Brightness = math.clamp(baseBrightness + n * 1.2, 0.2, baseBrightness + 1.5)
						task.wait(0.08)
					end
				end)
			end
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
		labelOn(floor, name, Vector3.new(0, 7, 0), Color3.fromRGB(230, 210, 170), Vector2.new(200, 28))
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
		local color = Config.CrateColor[kind] or Color3.fromRGB(140, 96, 52)
		local box = Instance.new("Part")
		box.Name = kind
		box.Size = Vector3.new(2.4, 2.2, 2.4)
		box.Anchored = true
		box.CanCollide = false
		box.Color = color
		box.Material = Enum.Material.Wood
		box.CFrame = floor.CFrame * CFrame.new(-4 + (i - 1) * 2.8, 2.4, 1)
		box.Parent = folder
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
	local buyer = part("Buyer", Vector3.new(2.2, 5.2, 2.2), floor.CFrame * CFrame.new(5.2, 3.4, -4.5), Color3.fromRGB(220, 170, 60), stall, Enum.Material.Neon)
	buyer.CanCollide = false
	labelOn(buyer, "Sell (Q)", Vector3.new(0, 4.2, 0), Color3.fromRGB(240, 210, 120), Vector2.new(120, 24))
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
	box.Color = Config.CrateColor[kind] or Color3.fromRGB(140, 96, 52)
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
	labelOn(p, text, Vector3.new(0, 0, 0), color, Vector2.new(160, 30))
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
			bell.Color = Color3.fromRGB(255, 230, 140)
			task.wait(0.16)
			bell.Color = orig
			task.wait(0.16)
		end
	end)
end

-- ===== Watcher (night threat) =====

local watcher: Model? = nil
local watcherAlive = false

local function stallPositions(): { Vector3 }
	local harbor = Workspace:FindFirstChild("Harbor")
	local stalls = harbor and harbor:FindFirstChild("Stalls")
	local positions = {}
	if not stalls then
		return positions
	end
	for _, stall in ipairs(stalls:GetChildren()) do
		local floor = stall:FindFirstChild("Floor")
		if floor and floor:IsA("BasePart") then
			table.insert(positions, floor.Position)
		end
	end
	return positions
end

function World.spawnWatcher()
	local harbor = Workspace:FindFirstChild("Harbor")
	if not harbor then
		return
	end
	World.despawnWatcher()

	local model = Instance.new("Model")
	model.Name = "Watcher"
	local torso = part("Figure", Vector3.new(3, 7, 2), CFrame.new(0, DOCK_Y + 8, -60), Color3.fromRGB(4, 4, 6), model, Enum.Material.SmoothPlastic)
	torso.CanCollide = false
	torso.Transparency = 0.05
	model.PrimaryPart = torso

	local light = Instance.new("PointLight")
	light.Name = "EyeLight"
	light.Color = Color3.fromRGB(255, 30, 30)
	light.Range = 12
	light.Brightness = 3
	light.Parent = torso

	model.Parent = harbor
	watcher = model
	watcherAlive = true

	task.spawn(function()
		local positions = stallPositions()
		while watcherAlive and model.Parent do
			if #positions > 0 then
				local target = positions[math.random(1, #positions)] + Vector3.new(0, 8, 0)
				local goal = CFrame.new(target, target - (target - torso.Position))
				local tween = TweenService:Create(torso, TweenInfo.new(2.2, Enum.EasingStyle.Sine), { CFrame = CFrame.new(target) })
				tween:Play()
				tween.Completed:Wait()
			end
			task.wait(1.2)
		end
	end)
end

function World.despawnWatcher()
	watcherAlive = false
	if watcher then
		watcher:Destroy()
		watcher = nil
	end
end

function World.watcherPosition(): Vector3?
	if watcher and watcher.PrimaryPart then
		return watcher.PrimaryPart.Position
	end
	return nil
end

return World
